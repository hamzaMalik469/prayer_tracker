library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:prayers_tracker_plus/core/errors/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_state.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

final class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required GetCurrentUser getCurrentUser,
    required WatchAuthState watchAuthState,
    required SignInWithEmail signInWithEmail,
    required CreateAccount createAccount,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required SendPasswordReset sendPasswordReset,
    required DeleteAccount deleteAccount,
    required SharedPreferences prefs,
  })  : _getCurrentUser = getCurrentUser,
        _watchAuthState = watchAuthState,
        _signInWithEmail = signInWithEmail,
        _createAccount = createAccount,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        _sendPasswordReset = sendPasswordReset,
        _deleteAccount = deleteAccount,
        _prefs = prefs;

  final GetCurrentUser _getCurrentUser;
  final WatchAuthState _watchAuthState;
  final SignInWithEmail _signInWithEmail;
  final CreateAccount _createAccount;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final SendPasswordReset _sendPasswordReset;
  final DeleteAccount _deleteAccount;
  final SharedPreferences _prefs;

  StreamSubscription<UserEntity?>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _errorMessage;
  String? _guestUserId;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Returns the effective user ID:
  ///   - Authenticated: real Firebase UID
  ///   - Guest: stable local guest ID
  /// This is NEVER null after initialise() completes.
  String? get userId {
    if (_user != null) return _user!.id;
    return _guestUserId;
  }

  /// True when the user is in guest (local-only) mode.
  bool get isGuest => _user == null && _guestUserId != null;

  /// True when the effective userId is available.
  bool get hasUserId => userId != null;

  void initialise() {
    // Load or create guest ID immediately so userId is never null.
    GuestUserHelper.getOrCreateGuestId(_prefs).then((guestId) {
      _guestUserId = guestId;
      if (_status == AuthStatus.unauthenticated ||
          _status == AuthStatus.initial) {
        notifyListeners();
      }
    });

    _authSubscription = _watchAuthState().listen(
      (user) {
        _user = user;
        _status = user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
        _errorMessage = null;
        AppLogger.info(
          'Auth state: ${user != null ? "authenticated (${user.id})" : "unauthenticated (guest: $_guestUserId)"}',
          tag: 'AuthProvider',
        );
        notifyListeners();
      },
      onError: (Object e) {
        AppLogger.error('Auth stream error', error: e, tag: 'AuthProvider');
        _status = AuthStatus.error;
        _errorMessage = 'Authentication error. Please restart the app.';
        notifyListeners();
      },
    );
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _signInWithEmail(
        SignInWithEmailParams(email: email, password: password),
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading();
    try {
      _user = await _createAccount(
        CreateAccountParams(
          email: email,
          password: password,
          displayName: displayName,
        ),
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      _user = await _signInWithGoogle();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> sendPasswordReset({required String email}) async {
    _setLoading();
    try {
      await _sendPasswordReset(SendPasswordResetParams(email: email));
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> signOut() async {
    _setLoading();
    try {
      await _signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading();
    try {
      await _deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status =
        _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    _errorMessage = message;
    notifyListeners();
  }

  String _getErrorMessage(Object error) {
    if (error is AuthFailure) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

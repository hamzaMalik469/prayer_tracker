/// Manages a persistent guest user ID for unauthenticated users.
///
/// When a user launches the app without creating an account, they
/// receive a stable local guest ID. All their data is stored locally
/// under this ID. On account creation, local data is migrated.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

abstract final class GuestUserHelper {
  static const String _guestPrefix = 'guest_';

  /// Returns the persistent guest user ID.
  /// Creates one if it does not exist yet.
  static Future<String> getOrCreateGuestId(
    SharedPreferences prefs,
  ) async {
    final existing = prefs.getString(PreferenceKeys.guestUserId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = '$_guestPrefix${const Uuid().v4()}';
    await prefs.setString(PreferenceKeys.guestUserId, newId);

    AppLogger.info(
      'Created guest user ID: $newId',
      tag: 'GuestUserHelper',
    );

    return newId;
  }

  /// Returns the stored guest ID without creating one.
  static String? getExistingGuestId(SharedPreferences prefs) =>
      prefs.getString(PreferenceKeys.guestUserId);

  /// Returns true when [userId] belongs to a guest (local-only) user.
  static bool isGuestId(String userId) => userId.startsWith(_guestPrefix);

  /// Clears the guest ID after successful account migration.
  static Future<void> clearGuestId(SharedPreferences prefs) async {
    await prefs.remove(PreferenceKeys.guestUserId);
    AppLogger.info('Guest ID cleared after migration.', tag: 'GuestUserHelper');
  }
}

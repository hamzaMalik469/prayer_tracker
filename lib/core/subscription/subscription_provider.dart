library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'feature_access.dart';
import 'subscription_config.dart';
import 'subscription_domain.dart';
import '../logging/app_logger.dart';

final class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({
    required SubscriptionRepository repository,
    required FeatureAccessService featureAccessService,
  })  : _repository = repository,
        _featureAccessService = featureAccessService;

  final SubscriptionRepository _repository;
  final FeatureAccessService _featureAccessService;

  StreamSubscription<PremiumEntitlement>? _entitlementSubscription;

  PremiumEntitlement _entitlement = const PremiumEntitlement.unknown();
  bool _isLoading = false;
  String? _errorMessage;

  PremiumEntitlement get entitlement => _entitlement;
  bool get isPremium => _entitlement.isPremium;
  SubscriptionStatus get status => _entitlement.status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool canAccess(PremiumFeature feature) =>
      _featureAccessService.canAccess(feature);

  Future<void> initialise() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entitlement = await _repository.getEntitlement();
      _isLoading = false;
      notifyListeners();

      _entitlementSubscription = _repository.watchEntitlement().listen(
        (entitlement) {
          _entitlement = entitlement;
          notifyListeners();
        },
        onError: (Object e) {
          AppLogger.warning('Entitlement stream error', error: e, tag: 'SubscriptionProvider');
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load entitlement', error: e, tag: 'SubscriptionProvider');
      _isLoading = false;
      _entitlement = const PremiumEntitlement.free();
      notifyListeners();
    }
  }

  Future<bool> purchase(SubscriptionPlan plan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entitlement = await _repository.purchase(plan);
      _isLoading = false;
      notifyListeners();
      return _entitlement.isPremium;
    } catch (e) {
      AppLogger.error('Purchase failed', error: e, tag: 'SubscriptionProvider');
      _isLoading = false;
      _errorMessage = 'Purchase could not be completed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entitlement = await _repository.restorePurchases();
      _isLoading = false;
      notifyListeners();
      return _entitlement.isPremium;
    } catch (e) {
      AppLogger.error('Restore purchases failed', error: e, tag: 'SubscriptionProvider');
      _isLoading = false;
      _errorMessage = 'Could not restore purchases. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _entitlementSubscription?.cancel();
    super.dispose();
  }
}

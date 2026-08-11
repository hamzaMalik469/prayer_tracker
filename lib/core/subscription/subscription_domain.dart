/// Domain-level subscription use case interfaces.
///
/// The concrete implementation lives in the Data layer (Phase 3).
/// The Domain layer only knows about these abstractions.
library;

import 'subscription_config.dart';

abstract interface class SubscriptionRepository {
  /// Returns the current entitlement state.
  Future<PremiumEntitlement> getEntitlement();

  /// Watches entitlement changes in real time.
  Stream<PremiumEntitlement> watchEntitlement();

  /// Initiates a purchase for [plan].
  Future<PremiumEntitlement> purchase(SubscriptionPlan plan);

  /// Restores previous purchases.
  Future<PremiumEntitlement> restorePurchases();
}

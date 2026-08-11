/// Stub subscription repository — replaced in Phase 7 with
/// a real RevenueCat or in_app_purchase implementation.
///
/// Returns free entitlement for all users until billing is integrated.
library;

import 'subscription_config.dart';
import 'subscription_domain.dart';

final class StubSubscriptionRepository implements SubscriptionRepository {
  const StubSubscriptionRepository();

  @override
  Future<PremiumEntitlement> getEntitlement() async =>
      const PremiumEntitlement.free();

  @override
  Stream<PremiumEntitlement> watchEntitlement() =>
      Stream.value(const PremiumEntitlement.free());

  @override
  Future<PremiumEntitlement> purchase(SubscriptionPlan plan) async =>
      const PremiumEntitlement.free();

  @override
  Future<PremiumEntitlement> restorePurchases() async =>
      const PremiumEntitlement.free();
}

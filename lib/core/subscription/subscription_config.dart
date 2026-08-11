library;

import 'package:equatable/equatable.dart';

enum SubscriptionStatus {
  free,
  premium,
  expired,
  cancelled,
  billingIssue,
  trial,
  unknown,
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  bool get isActive =>
      this == SubscriptionStatus.premium || this == SubscriptionStatus.trial;

  String get label => switch (this) {
        SubscriptionStatus.free => 'Free',
        SubscriptionStatus.premium => 'Premium',
        SubscriptionStatus.expired => 'Expired',
        SubscriptionStatus.cancelled => 'Cancelled',
        SubscriptionStatus.billingIssue => 'Billing Issue',
        SubscriptionStatus.trial => 'Trial',
        SubscriptionStatus.unknown => 'Unknown',
      };
}

enum SubscriptionPlan {
  monthly,
  yearly,
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get label => switch (this) {
        SubscriptionPlan.monthly => 'Monthly',
        SubscriptionPlan.yearly => 'Yearly',
      };
}

final class PremiumEntitlement extends Equatable {
  const PremiumEntitlement({
    required this.status,
    this.plan,
    this.expiryDate,
    this.isInGracePeriod = false,
    this.willRenew = false,
  });

  const PremiumEntitlement.free()
      : status = SubscriptionStatus.free,
        plan = null,
        expiryDate = null,
        isInGracePeriod = false,
        willRenew = false;

  const PremiumEntitlement.unknown()
      : status = SubscriptionStatus.unknown,
        plan = null,
        expiryDate = null,
        isInGracePeriod = false,
        willRenew = false;

  final SubscriptionStatus status;
  final SubscriptionPlan? plan;
  final DateTime? expiryDate;
  final bool isInGracePeriod;
  final bool willRenew;

  bool get isPremium => status.isActive;

  @override
  List<Object?> get props => [
        status,
        plan,
        expiryDate,
        isInGracePeriod,
        willRenew,
      ];
}

library;

abstract final class FirestoreCollections {
  static const String users = 'users';
  static const String prayerRecords = 'prayer_records';
  static const String qadaRecords = 'qada_records';
  static const String settings = 'settings';
}

abstract final class FirestoreDocuments {
  static const String preferences = 'preferences';
  static const String qadaBalance = 'qada_balance';
}

abstract final class FirestoreFields {
  static const String userId = 'userId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String date = 'date';
  static const String prayerType = 'prayerType';
  static const String status = 'status';
  static const String timezone = 'timezone';
  static const String quantity = 'quantity';
  static const String completedAt = 'completedAt';
  static const String calculationMethod = 'calculationMethod';
  static const String madhab = 'madhab';
  static const String highLatitudeRule = 'highLatitudeRule';
  static const String themeMode = 'themeMode';
  static const String locationMode = 'locationMode';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String cityName = 'cityName';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String subscriptionStatus = 'subscriptionStatus';
}

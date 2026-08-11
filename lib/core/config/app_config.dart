library;

enum AppEnvironment {
  development,
  staging,
  production,
}

class AppConfig {
  AppConfig._({
    required this.environment,
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.enableVerboseLogging,
    required this.enableCrashReporting,
    required this.enableAnalytics,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    assert(
      _instance != null,
      'AppConfig has not been initialised. '
      'Call AppConfig.initialise() before accessing AppConfig.instance.',
    );
    return _instance!;
  }

  static void initialise({
    required String appVersion,
    required String buildNumber,
  }) {
    const envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );

    final environment = switch (envString) {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };

    _instance = AppConfig._(
      environment: environment,
      appName: _resolveAppName(environment),
      appVersion: appVersion,
      buildNumber: buildNumber,
      enableVerboseLogging: environment != AppEnvironment.production,
      enableCrashReporting: environment == AppEnvironment.production,
      enableAnalytics: environment == AppEnvironment.production,
    );
  }

  final AppEnvironment environment;
  final String appName;
  final String appVersion;
  final String buildNumber;
  final bool enableVerboseLogging;
  final bool enableCrashReporting;
  final bool enableAnalytics;

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;

  static String _resolveAppName(AppEnvironment env) => switch (env) {
        AppEnvironment.production => 'Daily Deen',
        AppEnvironment.staging => 'Daily Deen (Staging)',
        AppEnvironment.development => 'Daily Deen (Dev)',
      };

  @override
  String toString() => 'AppConfig('
      'env: $environment, '
      'version: $appVersion+$buildNumber, '
      'logging: $enableVerboseLogging'
      ')';
}

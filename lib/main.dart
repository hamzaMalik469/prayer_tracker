library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/logging/app_logger.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final packageInfo = await PackageInfo.fromPlatform();

  AppConfig.initialise(
    appVersion: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );

  AppLogger.info('Starting ${AppConfig.instance}', tag: 'main');

  await initializeFirebase();
  await initializeDependencies();

  runApp(const DailyDeenApp());
}

Future<void> _recordFatalError(Object error, StackTrace stack) async {
  AppLogger.error('Fatal error', error: error, stackTrace: stack);
  await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}

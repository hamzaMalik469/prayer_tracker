library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
  _configureCrashlytics();
  _configureAnalytics();
  AppLogger.info('Firebase initialised.', tag: 'FirebaseService');
}

void _configureCrashlytics() {
  if (!AppConfig.instance.enableCrashReporting) {
    AppLogger.info(
      'Crashlytics disabled in ${AppConfig.instance.environment} environment.',
      tag: 'FirebaseService',
    );
    return;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  AppLogger.info('Crashlytics configured.', tag: 'FirebaseService');
}

void _configureAnalytics() {
  if (!AppConfig.instance.enableAnalytics) {
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    AppLogger.info(
      'Analytics disabled in ${AppConfig.instance.environment} environment.',
      tag: 'FirebaseService',
    );
    return;
  }

  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  AppLogger.info('Analytics configured.', tag: 'FirebaseService');
}

abstract final class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!AppConfig.instance.enableAnalytics) return;
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      AppLogger.warning('Analytics logEvent failed: $name', error: e);
    }
  }

  static Future<void> setCurrentScreen(String screenName) async {
    if (!AppConfig.instance.enableAnalytics) return;
    try {
      await _analytics.setCurrentScreen(screenName: screenName);
    } catch (e) {
      AppLogger.warning('Analytics setCurrentScreen failed', error: e);
    }
  }

  static Future<void> setUserId(String? userId) async {
    if (!AppConfig.instance.enableAnalytics) return;
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      AppLogger.warning('Analytics setUserId failed', error: e);
    }
  }
}

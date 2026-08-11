library;

import 'package:flutter/foundation.dart';

enum _LogLevel {
  debug,
  info,
  warning,
  error,
}

abstract final class AppLogger {
  static bool _enabled = true;

  static void disable() => _enabled = false;

  static void enable() => _enabled = true;

  static void debug(String message, {String? tag, Object? error}) {
    if (kReleaseMode) return;
    _log(_LogLevel.debug, message, tag: tag, error: error);
  }

  static void info(String message, {String? tag}) {
    if (kReleaseMode) return;
    _log(_LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _log(_LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(_LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    _LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;

    final prefix = switch (level) {
      _LogLevel.debug => '🔍 DEBUG',
      _LogLevel.info => 'ℹ️  INFO',
      _LogLevel.warning => '⚠️  WARN',
      _LogLevel.error => '🔴 ERROR',
    };

    final tagPart = tag != null ? '[$tag] ' : '';
    final errorPart = error != null ? '\n  Error: $error' : '';
    final stackPart = stackTrace != null ? '\n  Stack: $stackTrace' : '';

    // ignore: avoid_print
    debugPrint('$prefix $tagPart$message$errorPart$stackPart');
  }
}

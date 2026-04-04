import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as pkg;

/// Structured logging service with severity levels.
///
/// All log entries are emitted as structured JSON, matching the format
/// expected by cloud-native observability tools (Cloud Logging, Datadog, etc.).
///
/// In a production kiosk deployment, these logs would be shipped to
/// GCP Cloud Logging via a sidecar agent or Fluentd.
abstract class LoggerService {
  void debug(String message, {Map<String, dynamic>? metadata});
  void info(String message, {Map<String, dynamic>? metadata});
  void warn(String message, {Map<String, dynamic>? metadata});
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata});
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata});
}

class LoggerServiceImpl implements LoggerService {
  final pkg.Logger _logger;
  final void Function(Map<String, dynamic> event)? _onCritical;

  LoggerServiceImpl({
    pkg.Logger? logger,
    void Function(Map<String, dynamic> event)? onCritical,
  })  : _logger = logger ??
            pkg.Logger(
              printer: pkg.PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 5,
                lineLength: 100,
              ),
            ),
        _onCritical = onCritical;

  Map<String, dynamic> _buildStructuredLog(
    String level,
    String message, {
    dynamic error,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (metadata != null) ...metadata,
    };
  }

  @override
  void debug(String message, {Map<String, dynamic>? metadata}) {
    if (kDebugMode) {
      _logger.d(jsonEncode(_buildStructuredLog('DEBUG', message, metadata: metadata)));
    }
  }

  @override
  void info(String message, {Map<String, dynamic>? metadata}) {
    _logger.i(jsonEncode(_buildStructuredLog('INFO', message, metadata: metadata)));
  }

  @override
  void warn(String message, {Map<String, dynamic>? metadata}) {
    _logger.w(jsonEncode(_buildStructuredLog('WARN', message, metadata: metadata)));
  }

  @override
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _logger.e(
      jsonEncode(_buildStructuredLog('ERROR', message, error: error, metadata: metadata)),
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    final event = _buildStructuredLog('CRITICAL', message, error: error, metadata: metadata);

    _logger.f(
      jsonEncode(event),
      error: error,
      stackTrace: stackTrace,
    );

    // Dispatch to alert system (Telegram/Sentry)
    _onCritical?.call(event);
  }
}

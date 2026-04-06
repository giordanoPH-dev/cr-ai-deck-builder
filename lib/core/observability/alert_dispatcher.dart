import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Simulates dispatching critical alerts to external monitoring systems.
///
/// In production, this would send structured events to:
/// - **Telegram Bot** (like "Claudemir" / "Mani" agents) for real-time team alerts
/// - **Sentry** for error tracking and crash analytics
/// - **GCP Cloud Monitoring** for SLO/SLA dashboards
///
/// The structured payload format is compatible with GCP Cloud Functions
/// that forward events to Telegram via Bot API.
class AlertDispatcher {
  /// Dispatches a critical alert event.
  ///
  /// In production, this would POST to a Cloud Function endpoint.
  /// Here, it logs the structured payload that would be sent.
  void dispatch({
    required String event,
    required String message,
    String severity = 'CRITICAL',
    Map<String, dynamic>? additionalData,
  }) {
    final payload = {
      'severity': severity,
      'source': AppConstants.appIdentifier,
      'device_id': AppConstants.deviceId,
      'event': event,
      'message': message,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'environment': kDebugMode ? 'development' : 'production',
      if (additionalData != null) 'data': additionalData,
    };

    // ┌─────────────────────────────────────────────────────────
    // │ SIMULATED ALERT DISPATCH
    // │
    // │ Production implementation would be:
    // │   await http.post(
    // │     Uri.parse('https://us-central1-<project>.cloudfunctions.net/alert'),
    // │     body: jsonEncode(payload),
    // │   );
    // │
    // │ The Cloud Function would then:
    // │   1. Forward to Telegram Bot API (chat_id of ops channel)
    // │   2. Create Sentry issue
    // │   3. Update GCP Cloud Monitoring custom metric
    // └─────────────────────────────────────────────────────────
    debugPrint('');
    debugPrint('🚨 ══════════════════════════════════════════════════');
    debugPrint('🚨 ALERT DISPATCHER — ${severity.toUpperCase()}');
    debugPrint('🚨 Event:   $event');
    debugPrint('🚨 Message: $message');
    debugPrint('🚨 Payload: ${jsonEncode(payload)}');
    debugPrint('🚨 ══════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Convenience method for LLM-related alerts.
  void llmFailure(String details, {String? rawResponse}) {
    dispatch(
      event: 'LLM_FAILURE',
      message: details,
      additionalData: {
        if (rawResponse != null)
          'raw_response_preview': rawResponse.length > 200
              ? '${rawResponse.substring(0, 200)}...'
              : rawResponse,
      },
    );
  }

  /// Convenience method for API-related alerts.
  void apiFailure(String endpoint, int? statusCode) {
    dispatch(
      event: 'API_FAILURE',
      message: 'Clash Royale API failure on $endpoint',
      severity: statusCode != null && statusCode >= 500 ? 'CRITICAL' : 'WARNING',
      additionalData: {
        'endpoint': endpoint,
        if (statusCode != null) 'status_code': statusCode,
      },
    );
  }
}

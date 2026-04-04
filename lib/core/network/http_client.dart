import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import '../observability/logger_service.dart';

/// A resilient HTTP client with automatic retry, exponential backoff,
/// configurable timeouts, and structured logging.
///
/// Designed for kiosk reliability — network glitches should not crash the app.
class ResilientHttpClient {
  final http.Client _client;
  final LoggerService _logger;

  ResilientHttpClient({
    required LoggerService logger,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _logger = logger;

  /// Performs a GET request with retry logic.
  ///
  /// Throws [ServerException] for 4xx/5xx responses.
  /// Throws [NetworkException] for connectivity/timeout issues.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final effectiveTimeout = timeout ?? AppConstants.apiTimeout;
    final effectiveRetries = maxRetries ?? AppConstants.maxRetries;

    Exception? lastException;

    for (int attempt = 1; attempt <= effectiveRetries; attempt++) {
      try {
        _logger.debug(
          'HTTP GET attempt $attempt/$effectiveRetries',
          metadata: {'url': url},
        );

        final response = await _client
            .get(Uri.parse(url), headers: headers)
            .timeout(effectiveTimeout);

        if (response.statusCode == 200) {
          _logger.info(
            'HTTP GET success',
            metadata: {'url': url, 'status': 200},
          );
          return json.decode(response.body) as Map<String, dynamic>;
        }

        // Non-retryable client errors (4xx)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw ServerException(
            message: response.body,
            statusCode: response.statusCode,
          );
        }

        // Server errors (5xx) — retryable
        throw ServerException(
          message: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } on ServerException catch (e) {
        if (e.statusCode >= 400 && e.statusCode < 500) {
          // Client errors are never retried
          _logger.warn(
            'HTTP client error (not retrying)',
            metadata: {'url': url, 'status': e.statusCode},
          );
          rethrow;
        }
        lastException = e;
        _logger.warn(
          'HTTP server error, retrying...',
          metadata: {'url': url, 'attempt': attempt, 'status': e.statusCode},
        );
      } on TimeoutException {
        lastException = const NetworkException(message: 'Request timed out');
        _logger.warn(
          'HTTP timeout, retrying...',
          metadata: {'url': url, 'attempt': attempt},
        );
      } on SocketException catch (e) {
        lastException = NetworkException(message: e.message);
        _logger.warn(
          'Socket error, retrying...',
          metadata: {'url': url, 'attempt': attempt},
        );
      } catch (e) {
        lastException = NetworkException(message: e.toString());
        _logger.warn(
          'Unexpected HTTP error, retrying...',
          metadata: {'url': url, 'attempt': attempt, 'error': e.toString()},
        );
      }

      // Exponential backoff: 1s, 2s, 4s...
      if (attempt < effectiveRetries) {
        final delay = AppConstants.retryBaseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }

    _logger.error(
      'HTTP GET failed after $effectiveRetries attempts',
      error: lastException,
      metadata: {'url': url},
    );
    throw lastException!;
  }

  /// GET that returns the raw response body as a List (for battle log endpoint).
  Future<List<dynamic>> getList(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    final effectiveTimeout = timeout ?? AppConstants.apiTimeout;
    final effectiveRetries = maxRetries ?? AppConstants.maxRetries;

    Exception? lastException;

    for (int attempt = 1; attempt <= effectiveRetries; attempt++) {
      try {
        final response = await _client
            .get(Uri.parse(url), headers: headers)
            .timeout(effectiveTimeout);

        if (response.statusCode == 200) {
          _logger.info('HTTP GET list success', metadata: {'url': url});
          return json.decode(response.body) as List<dynamic>;
        }

        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw ServerException(
            message: response.body,
            statusCode: response.statusCode,
          );
        }

        throw ServerException(
          message: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      } on ServerException catch (e) {
        if (e.statusCode >= 400 && e.statusCode < 500) rethrow;
        lastException = e;
      } on TimeoutException {
        lastException = const NetworkException(message: 'Request timed out');
      } on SocketException catch (e) {
        lastException = NetworkException(message: e.message);
      } catch (e) {
        lastException = NetworkException(message: e.toString());
      }

      if (attempt < effectiveRetries) {
        final delay = AppConstants.retryBaseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }

    throw lastException!;
  }

  void dispose() => _client.close();
}

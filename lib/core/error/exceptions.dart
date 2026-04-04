// Typed exceptions thrown by data sources.
// Repositories catch these and convert them into [Failure] objects.

/// Thrown when the Clash Royale API returns a non-2xx response.
class ServerException implements Exception {
  final String message;
  final int statusCode;

  const ServerException({required this.message, required this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when there is no internet or the request times out.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Network request failed'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when the LLM returns an invalid or unparseable response.
class LlmException implements Exception {
  final String message;
  final String? rawResponse;

  const LlmException({required this.message, this.rawResponse});

  @override
  String toString() => 'LlmException: $message';
}

/// Thrown when reading/writing to local cache fails.
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache operation failed'});

  @override
  String toString() => 'CacheException: $message';
}

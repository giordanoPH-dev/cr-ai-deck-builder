import 'package:equatable/equatable.dart';

/// Base failure class. All domain-level errors are represented as [Failure].
/// The presentation layer never sees exceptions — only typed failures
/// wrapped in [Either<Failure, T>].
sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// The Clash Royale API returned an HTTP error (4xx/5xx).
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code,
  });

  @override
  List<Object?> get props => [message, statusCode, code];
}

/// No internet connectivity or request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet. Verifique sua rede e tente novamente.',
    super.code = 'NETWORK_ERROR',
  });
}

/// The LLM (Gemini) failed to respond or returned unparseable data.
class LlmFailure extends Failure {
  final String? rawResponse;

  const LlmFailure({
    required super.message,
    this.rawResponse,
    super.code = 'LLM_ERROR',
  });

  @override
  List<Object?> get props => [message, rawResponse, code];
}

/// Requested player was not found (API 404).
class PlayerNotFoundFailure extends Failure {
  const PlayerNotFoundFailure({
    super.message = 'Jogador não encontrado. Verifique a tag e tente novamente.',
    super.code = 'PLAYER_NOT_FOUND',
  });
}

/// Cache failure — could not read/write local data.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Erro ao acessar dados locais.',
    super.code = 'CACHE_ERROR',
  });
}

/// Supabase or other remote database errors.
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code = 'DATABASE_ERROR',
  });
}

/// Catch-all for truly unexpected errors.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ocorreu um erro inesperado. Tente novamente.',
    super.code = 'UNKNOWN',
  });
}

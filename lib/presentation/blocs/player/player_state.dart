import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/battle.dart';

/// Typed state for player data operations.
///
/// Uses sealed class for exhaustive pattern matching in BlocBuilder,
/// ensuring every UI state is explicitly handled — no blank screens.
sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no search performed yet.
class PlayerInitial extends PlayerState {
  const PlayerInitial();
}

/// Searching for player — show loading indicator.
class PlayerLoading extends PlayerState {
  const PlayerLoading();
}

/// Player data loaded successfully.
class PlayerLoaded extends PlayerState {
  final PlayerProfile profile;
  final List<CrBattle> battles;
  /// True if data came from cache (offline mode).
  final bool isFromCache;

  const PlayerLoaded({
    required this.profile,
    required this.battles,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [profile, battles, isFromCache];
}

/// Error state with typed failure and retry capability.
class PlayerError extends PlayerState {
  final Failure failure;

  const PlayerError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

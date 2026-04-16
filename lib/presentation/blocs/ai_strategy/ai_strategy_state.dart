import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/ai_strategy_report.dart';

/// Typed state for AI strategy generation.
sealed class AiStrategyState extends Equatable {
  const AiStrategyState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no analysis requested.
class AiStrategyInitial extends AiStrategyState {
  final String archetype;
  const AiStrategyInitial({this.archetype = 'Aggressive (Beatdown)'});

  @override
  List<Object?> get props => [archetype];
}

/// Analysis in progress — show loading animation.
class AiStrategyLoading extends AiStrategyState {
  const AiStrategyLoading();
}

/// Strategy report generated successfully.
class AiStrategyLoaded extends AiStrategyState {
  final AiStrategyReport report;

  const AiStrategyLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

/// Error state with typed failure.
class AiStrategyError extends AiStrategyState {
  final Failure failure;

  const AiStrategyError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

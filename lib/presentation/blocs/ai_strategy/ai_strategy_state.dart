import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/ai_strategy_report.dart';
import '../../../domain/entities/deck_analysis_report.dart';
import '../../../domain/entities/full_analysis_report.dart';

sealed class AiStrategyState extends Equatable {
  const AiStrategyState();

  @override
  List<Object?> get props => [];
}

class AiStrategyInitial extends AiStrategyState {
  final String archetype;
  const AiStrategyInitial({this.archetype = 'Aggressive (Beatdown)'});

  @override
  List<Object?> get props => [archetype];
}

class AiStrategyLoading extends AiStrategyState {
  const AiStrategyLoading();
}

class AiStrategyLoaded extends AiStrategyState {
  final AiStrategyReport report;

  const AiStrategyLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

class DeckAnalysisLoading extends AiStrategyState {
  const DeckAnalysisLoading();
}

class DeckAnalysisLoaded extends AiStrategyState {
  final DeckAnalysisReport report;

  const DeckAnalysisLoaded({required this.report});

  @override
  List<Object?> get props => [report];
}

class FullAnalysisLoading extends AiStrategyState {
  const FullAnalysisLoading();
}

class FullAnalysisLoaded extends AiStrategyState {
  final FullAnalysisReport report;
  final DateTime? savedAt;
  final bool isFromCache;

  const FullAnalysisLoaded({required this.report, this.savedAt, this.isFromCache = false});

  @override
  List<Object?> get props => [report, savedAt, isFromCache];
}

class AiStrategyError extends AiStrategyState {
  final Failure failure;

  const AiStrategyError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

import 'package:equatable/equatable.dart';
import 'ai_strategy_report.dart';
import 'deck_analysis_report.dart';

class FullAnalysisReport extends Equatable {
  final AiStrategyReport strategy;
  final DeckAnalysisReport deckAnalysis;
  /// Card IDs from the player's currentDeck at the moment this analysis was generated.
  /// Used to detect when the player changes their deck after a saved analysis.
  final List<int> analyzedDeckIds;

  const FullAnalysisReport({
    required this.strategy,
    required this.deckAnalysis,
    this.analyzedDeckIds = const [],
  });

  @override
  List<Object?> get props => [strategy, deckAnalysis, analyzedDeckIds];
}

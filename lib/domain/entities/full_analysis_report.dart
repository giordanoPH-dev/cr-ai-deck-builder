import 'package:equatable/equatable.dart';
import 'ai_strategy_report.dart';
import 'deck_analysis_report.dart';

class FullAnalysisReport extends Equatable {
  final AiStrategyReport strategy;
  final DeckAnalysisReport deckAnalysis;

  const FullAnalysisReport({required this.strategy, required this.deckAnalysis});

  @override
  List<Object?> get props => [strategy, deckAnalysis];
}

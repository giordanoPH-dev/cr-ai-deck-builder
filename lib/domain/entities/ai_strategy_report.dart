import 'package:equatable/equatable.dart';

/// Typed domain entity for the AI strategy report.
///
/// Instead of returning raw markdown text from the LLM, we parse
/// the response into structured, typed fields. This enables:
/// - Type-safe UI rendering (each section has its own widget)
/// - Validation of LLM output (detect hallucinations)
/// - Deep-link generation from card IDs
class AiStrategyReport extends Equatable {
  /// Analysis of the player's current playstyle.
  final String playstyleAnalysis;

  /// Coaching advice for the player's trophy range/meta.
  final String metaCoaching;

  /// IDs of the 8 suggested cards for the deck.
  final List<int> suggestedDeckIds;

  /// Names of the 8 suggested cards.
  final List<String> suggestedDeckNames;

  /// Battle guide with opening, defense, and win condition strategies.
  final BattleGuide battleGuide;

  /// Pre-built deep link URL for importing the deck into Clash Royale.
  final String deckLinkUrl;

  /// Confidence score from 0.0 to 1.0 indicating how confident
  /// the LLM is in its suggestion.
  final double confidenceScore;

  const AiStrategyReport({
    required this.playstyleAnalysis,
    required this.metaCoaching,
    required this.suggestedDeckIds,
    required this.suggestedDeckNames,
    required this.battleGuide,
    required this.deckLinkUrl,
    required this.confidenceScore,
  });

  @override
  List<Object?> get props => [
        playstyleAnalysis,
        metaCoaching,
        suggestedDeckIds,
        suggestedDeckNames,
        battleGuide,
        deckLinkUrl,
        confidenceScore,
      ];
}

/// Structured battle guide with three phases.
class BattleGuide extends Equatable {
  final String opening;
  final String defense;
  final String winCondition;

  const BattleGuide({
    required this.opening,
    required this.defense,
    required this.winCondition,
  });

  @override
  List<Object?> get props => [opening, defense, winCondition];
}

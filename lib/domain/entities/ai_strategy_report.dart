import 'package:equatable/equatable.dart';

class AiStrategyReport extends Equatable {
  final String playstyleAnalysis;
  final String metaCoaching;
  final List<int> suggestedDeckIds;
  final List<String> suggestedDeckNames;
  final BattleGuide battleGuide;
  final String deckLinkUrl;
  final double confidenceScore;

  // Extended fields — nullable for backward compatibility
  final String? archetypeExplanation;
  final DeckBreakdown? deckBreakdown;
  final List<MatchupTip>? matchupTips;

  const AiStrategyReport({
    required this.playstyleAnalysis,
    required this.metaCoaching,
    required this.suggestedDeckIds,
    required this.suggestedDeckNames,
    required this.battleGuide,
    required this.deckLinkUrl,
    required this.confidenceScore,
    this.archetypeExplanation,
    this.deckBreakdown,
    this.matchupTips,
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
        archetypeExplanation,
        deckBreakdown,
        matchupTips,
      ];
}

class BattleGuide extends Equatable {
  final String opening;
  final String defense;
  final String winCondition;

  // Extended fields — nullable for backward compatibility
  final String? openingMove;
  final String? elixirManagement;
  final String? winConditionExecution;
  final String? doubleElixirStrategy;
  final String? commonMistakes;

  const BattleGuide({
    required this.opening,
    required this.defense,
    required this.winCondition,
    this.openingMove,
    this.elixirManagement,
    this.winConditionExecution,
    this.doubleElixirStrategy,
    this.commonMistakes,
  });

  @override
  List<Object?> get props => [
        opening,
        defense,
        winCondition,
        openingMove,
        elixirManagement,
        winConditionExecution,
        doubleElixirStrategy,
        commonMistakes,
      ];
}

class DeckBreakdown extends Equatable {
  final List<String>? winCondition;
  final List<String>? spells;
  final List<String>? airDefense;
  final List<String>? support;
  final List<String>? buildings;

  const DeckBreakdown({
    this.winCondition,
    this.spells,
    this.airDefense,
    this.support,
    this.buildings,
  });

  @override
  List<Object?> get props => [winCondition, spells, airDefense, support, buildings];
}

class MatchupTip extends Equatable {
  final String enemyArchetype;
  final String tip;

  const MatchupTip({required this.enemyArchetype, required this.tip});

  @override
  List<Object?> get props => [enemyArchetype, tip];
}

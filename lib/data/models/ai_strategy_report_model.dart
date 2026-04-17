import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/ai_strategy_report.dart';

/// Data model for [AiStrategyReport] with robust LLM response parsing.
///
/// This is the critical piece that handles LLM hallucinations:
/// 1. Try direct JSON parse
/// 2. Try extracting JSON from markdown code blocks
/// 3. Throw [LlmException] with the raw response for debugging
class AiStrategyReportModel extends AiStrategyReport {
  const AiStrategyReportModel({
    required super.playstyleAnalysis,
    required super.metaCoaching,
    required super.suggestedDeckIds,
    required super.suggestedDeckNames,
    required super.battleGuide,
    required super.deckLinkUrl,
    required super.confidenceScore,
    super.archetypeExplanation,
    super.deckBreakdown,
    super.matchupTips,
  });

  /// Attempts to parse the raw LLM response into a structured report.
  ///
  /// Three-tier parsing strategy:
  /// 1. Direct `json.decode()` on the entire response
  /// 2. Extract JSON from markdown code blocks (```json ... ```)
  /// 3. Throw [LlmException] if all parsing fails
  factory AiStrategyReportModel.fromLlmResponse(String rawResponse) {
    // Tier 1: Direct JSON parse
    try {
      final json = jsonDecode(rawResponse) as Map<String, dynamic>;
      return AiStrategyReportModel.fromParsedJson(json);
    } catch (_) {
      // Not pure JSON, try tier 2
    }

    // Tier 2: Extract from markdown code blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = codeBlockRegex.firstMatch(rawResponse);
    if (match != null) {
      try {
        final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        return AiStrategyReportModel.fromParsedJson(json);
      } catch (_) {
        // Code block content wasn't valid JSON
      }
    }

    // Tier 3: All parsing failed
    throw LlmException(
      message: 'Failed to parse LLM response. TRACE:\\n$rawResponse',
      rawResponse: rawResponse,
    );
  }

  factory AiStrategyReportModel.fromParsedJson(Map<String, dynamic> json) {
    // Extract deck with safe parsing
    final suggestedDeckRaw = json['suggested_deck'];
    final suggestedDeck = suggestedDeckRaw is List ? suggestedDeckRaw : [];
    final deckIds = <int>[];
    final deckNames = <String>[];

    for (final card in suggestedDeck) {
      if (card is Map) {
        final id = card['id'];
        if (id is int) {
          deckIds.add(id);
        } else if (id is String) {
          deckIds.add(int.tryParse(id) ?? 0);
        }
        deckNames.add(card['name']?.toString() ?? 'Unknown Card');
      }
    }

    // Parse battle guide — try new field names first, fall back to original
    final battleGuideJson = json['battle_guide'] as Map<String, dynamic>? ?? {};
    final opening = _safeStringOrNull(battleGuideJson['opening_move'])
        ?? _safeStringOrNull(battleGuideJson['opening'])
        ?? '';
    final winCondition = _safeStringOrNull(battleGuideJson['win_condition_execution'])
        ?? _safeStringOrNull(battleGuideJson['win_condition'])
        ?? '';

    // Parse confidence score safely
    final rawConfidence = json['confidence_score'];
    double confidence = 0.7;
    if (rawConfidence is double) {
      confidence = rawConfidence.clamp(0.0, 1.0);
    } else if (rawConfidence is int) {
      confidence = rawConfidence.toDouble().clamp(0.0, 1.0);
    } else if (rawConfidence is String) {
      confidence = (double.tryParse(rawConfidence) ?? 0.7).clamp(0.0, 1.0);
    }

    // Parse deck breakdown (new)
    DeckBreakdown? deckBreakdown;
    final breakdownJson = json['deck_breakdown'] as Map<String, dynamic>?;
    if (breakdownJson != null) {
      deckBreakdown = DeckBreakdown(
        winCondition: _parseStringList(breakdownJson['win_condition']),
        spells: _parseStringList(breakdownJson['spells']),
        airDefense: _parseStringList(breakdownJson['air_defense']),
        support: _parseStringList(breakdownJson['support']),
        buildings: _parseStringList(breakdownJson['buildings']),
      );
    }

    // Parse matchup tips (new)
    List<MatchupTip>? matchupTips;
    final matchupsJson = json['matchup_tips'] as List?;
    if (matchupsJson != null) {
      matchupTips = matchupsJson
          .whereType<Map<String, dynamic>>()
          .map((m) => MatchupTip(
                enemyArchetype: m['enemy_archetype'] as String? ?? '',
                tip: m['tip'] as String? ?? '',
              ))
          .toList();
    }

    // Build deck link
    final deckLink = deckIds.isNotEmpty
        ? '${AppConstants.deckLinkBaseUrl}${deckIds.join(';')}'
        : '';

    return AiStrategyReportModel(
      playstyleAnalysis: _safeString(json['playstyle_analysis']),
      metaCoaching: _safeString(json['meta_coaching']),
      suggestedDeckIds: deckIds,
      suggestedDeckNames: deckNames,
      battleGuide: BattleGuide(
        opening: opening,
        defense: _safeString(battleGuideJson['defense']),
        winCondition: winCondition,
        openingMove: _safeStringOrNull(battleGuideJson['opening_move']),
        elixirManagement: _safeStringOrNull(battleGuideJson['elixir_management']),
        winConditionExecution: _safeStringOrNull(battleGuideJson['win_condition_execution']),
        doubleElixirStrategy: _safeStringOrNull(battleGuideJson['double_elixir_strategy']),
        commonMistakes: _safeStringOrNull(battleGuideJson['common_mistakes']),
      ),
      deckLinkUrl: deckLink,
      confidenceScore: confidence,
      archetypeExplanation: _safeStringOrNull(json['archetype_explanation']),
      deckBreakdown: deckBreakdown,
      matchupTips: matchupTips,
    );
  }

  static String _safeString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value;
    if (value is List) return value.join('\n');
    return value.toString();
  }

  static String? _safeStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) return value.join('\n');
    return value.toString();
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'playstyle_analysis': playstyleAnalysis,
      'meta_coaching': metaCoaching,
      if (archetypeExplanation != null) 'archetype_explanation': archetypeExplanation,
      'suggested_deck': List.generate(
        suggestedDeckIds.length,
        (i) => {
          'id': suggestedDeckIds[i],
          'name': i < suggestedDeckNames.length ? suggestedDeckNames[i] : 'Unknown',
        },
      ),
      if (deckBreakdown != null)
        'deck_breakdown': {
          if (deckBreakdown!.winCondition != null) 'win_condition': deckBreakdown!.winCondition,
          if (deckBreakdown!.spells != null) 'spells': deckBreakdown!.spells,
          if (deckBreakdown!.airDefense != null) 'air_defense': deckBreakdown!.airDefense,
          if (deckBreakdown!.support != null) 'support': deckBreakdown!.support,
          if (deckBreakdown!.buildings != null) 'buildings': deckBreakdown!.buildings,
        },
      'battle_guide': {
        'opening': battleGuide.opening,
        'defense': battleGuide.defense,
        'win_condition': battleGuide.winCondition,
        if (battleGuide.openingMove != null) 'opening_move': battleGuide.openingMove,
        if (battleGuide.elixirManagement != null) 'elixir_management': battleGuide.elixirManagement,
        if (battleGuide.winConditionExecution != null) 'win_condition_execution': battleGuide.winConditionExecution,
        if (battleGuide.doubleElixirStrategy != null) 'double_elixir_strategy': battleGuide.doubleElixirStrategy,
        if (battleGuide.commonMistakes != null) 'common_mistakes': battleGuide.commonMistakes,
      },
      if (matchupTips != null)
        'matchup_tips': matchupTips!.map((m) => {'enemy_archetype': m.enemyArchetype, 'tip': m.tip}).toList(),
      'confidence_score': confidenceScore,
    };
  }
}

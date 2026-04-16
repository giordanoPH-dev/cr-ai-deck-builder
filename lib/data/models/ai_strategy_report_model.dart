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
      return AiStrategyReportModel.fromJson(json);
    } catch (_) {
      // Not pure JSON, try tier 2
    }

    // Tier 2: Extract from markdown code blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = codeBlockRegex.firstMatch(rawResponse);
    if (match != null) {
      try {
        final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        return AiStrategyReportModel.fromJson(json);
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

  /// Internal parser from a validated JSON map with safe defaults.
  factory AiStrategyReportModel.fromJson(Map<String, dynamic> json) {
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

    // Parse battle guide with safe access
    final bgRaw = json['battle_guide'];
    final battleGuideJson = bgRaw is Map ? bgRaw : {};

    // Parse confidence score safely
    final rawConfidence = json['confidence_score'];
    double confidence = 0.7; // Default
    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble().clamp(0.0, 1.0);
    } else if (rawConfidence is String) {
      confidence = (double.tryParse(rawConfidence) ?? 0.7).clamp(0.0, 1.0);
    }

    // Build deck link
    final deckLink = deckIds.isNotEmpty
        ? '${AppConstants.deckLinkBaseUrl}${deckIds.join(';')}'
        : '';

    return AiStrategyReportModel(
      playstyleAnalysis: json['playstyle_analysis']?.toString() ?? 'Analysis unavailable.',
      metaCoaching: json['meta_coaching']?.toString() ?? 'Coaching unavailable.',
      suggestedDeckIds: deckIds,
      suggestedDeckNames: deckNames,
      battleGuide: BattleGuide(
        opening: battleGuideJson['opening']?.toString() ?? 'Information unavailable.',
        defense: battleGuideJson['defense']?.toString() ?? 'Information unavailable.',
        winCondition: battleGuideJson['win_condition']?.toString() ?? 'Information unavailable.',
      ),
      deckLinkUrl: deckLink,
      confidenceScore: confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playstyle_analysis': playstyleAnalysis,
      'meta_coaching': metaCoaching,
      'suggested_deck': List.generate(
        suggestedDeckIds.length,
        (i) => {
          'id': suggestedDeckIds[i],
          'name': i < suggestedDeckNames.length ? suggestedDeckNames[i] : 'Unknown',
        },
      ),
      'battle_guide': {
        'opening': battleGuide.opening,
        'defense': battleGuide.defense,
        'win_condition': battleGuide.winCondition,
      },
      'confidence_score': confidenceScore,
    };
  }
}

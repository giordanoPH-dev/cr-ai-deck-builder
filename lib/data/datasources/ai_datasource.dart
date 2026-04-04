import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/battle.dart';
import '../models/ai_strategy_report_model.dart';

/// Data source for AI strategy generation via Google Gemini.
///
/// Key improvements over the original:
/// - Prompt engineered for JSON-only response (no markdown)
/// - Uses `responseMimeType: 'application/json'` for structured output
/// - Throws [LlmException] with raw response for debugging
abstract class AiDatasource {
  bool get isAvailable;
  Future<AiStrategyReportModel> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
  });
}

class AiDatasourceImpl implements AiDatasource {
  final String? _apiKey;
  final LoggerService _logger;
  GenerativeModel? _model;

  AiDatasourceImpl({
    String? apiKey,
    required LoggerService logger,
  })  : _apiKey = apiKey,
        _logger = logger {
    if (_apiKey != null && _apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );
    }
  }

  @override
  bool get isAvailable => _model != null;

  @override
  Future<AiStrategyReportModel> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
  }) async {
    if (_model == null) {
      throw const LlmException(
        message: 'AI service not configured. Provide a valid Gemini API key.',
      );
    }

    final prompt = _buildStructuredPrompt(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
    );

    _logger.info('Sending prompt to Gemini', metadata: {
      'player': profile.name,
      'archetype': preferredArchetype,
      'card_count': profile.cards.length,
    });

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        throw const LlmException(message: 'Gemini returned empty response');
      }

      _logger.info('Gemini response received', metadata: {
        'response_length': rawText.length,
      });

      // Parse structured JSON response
      return AiStrategyReportModel.fromLlmResponse(rawText);
    } on LlmException {
      rethrow;
    } catch (e) {
      _logger.error('Gemini API call failed', error: e);
      throw LlmException(message: 'Gemini API error: $e');
    }
  }

  String _buildStructuredPrompt({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
  }) {
    // Prepare card collection info
    final collectionInfo = profile.cards
        .map((c) => '{"name":"${c.name}","level":${c.level ?? 1},"id":${c.id}}')
        .join(',');

    // Summarize recent battles
    int wins = 0, losses = 0, draws = 0;
    for (var battle in battles.take(AppConstants.maxBattlesForAnalysis)) {
      final teamCrowns = battle.team.isNotEmpty ? battle.team.first.crowns : 0;
      final oppCrowns = battle.opponent.isNotEmpty ? battle.opponent.first.crowns : 0;
      if (teamCrowns > oppCrowns) {
        wins++;
      } else if (teamCrowns < oppCrowns) {
        losses++;
      } else {
        draws++;
      }
    }

    final currentDeckNames = profile.currentDeck.map((c) => c.name).join(', ');

    return '''
You are a Clash Royale Grand Master and Strategy Expert.
Analyze the following player data and respond ONLY with valid JSON matching the schema below.

IMPORTANT: This analysis is part of an unofficial fan content application. It is not endorsed by Supercell.

=== PLAYER DATA ===
Player: ${profile.name}
Trophies: ${profile.trophies}
Arena: ${profile.arenaName}
Current Deck: $currentDeckNames
Recent Performance (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} matches): $wins wins, $losses losses, $draws draws
Preferred Style: ${preferredArchetype.toUpperCase()}

=== CARD COLLECTION (use ONLY these cards) ===
[$collectionInfo]

=== RESPONSE JSON SCHEMA ===
{
  "playstyle_analysis": "Analysis of their current playstyle vs chosen archetype. 2-3 sentences.",
  "meta_coaching": "Coaching for their trophy range meta and how their collection counters it. 2-3 sentences.",
  "suggested_deck": [
    {"id": <card_id_int>, "name": "<card_name>"},
    ... (exactly 8 cards from their collection, prioritizing highest level)
  ],
  "battle_guide": {
    "opening": "How to start: first moves and elixir management. 2-3 sentences.",
    "defense": "How to defend common pushes. 2-3 sentences.",
    "win_condition": "How to win: main push strategy. 2-3 sentences."
  },
  "confidence_score": <float 0.0 to 1.0, your confidence in this deck suggestion>
}

RULES:
- Suggest EXACTLY 8 cards, all from the player's collection
- Prioritize highest-level cards
- If collection cannot support the preferred style, suggest closest viable alternative and explain in playstyle_analysis
- confidence_score: 1.0 = perfect fit, 0.5 = compromise, below 0.3 = weak suggestion
- Keep ALL text fields concise (2-3 sentences max each)
- Response must be ONLY the JSON object, no markdown, no code blocks, no extra text
''';
  }
}

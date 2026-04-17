import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_constants.dart';
import '../../core/data/arena_guide.dart';
import '../../core/error/exceptions.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/battle.dart';
import '../models/ai_strategy_report_model.dart';
import '../models/deck_analysis_report_model.dart';
import '../models/full_analysis_report_model.dart';

/// Data source for AI strategy generation via Google Gemini.
///
/// Key improvements over the original:
/// - Prompt engineered for JSON-only response (no markdown)
/// - Uses `responseMimeType: 'application/json'` for structured output
/// - Throws [LlmException] with raw response for debugging
abstract class AiDatasource {
  bool get isAvailable;
  void updateApiKey(String apiKey);
  Future<AiStrategyReportModel> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  });
  Future<DeckAnalysisReportModel> analyzeDeck({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String languageName,
  });

  Future<FullAnalysisReportModel> getFullAnalysis({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  });
}

class AiDatasourceImpl implements AiDatasource {
  final LoggerService _logger;
  final List<({String name, GenerativeModel model})> _models = [];

  AiDatasourceImpl({
    String? apiKey,
    required LoggerService logger,
  }) : _logger = logger {
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      _buildModels(apiKey);
    }
  }

  void _buildModels(String apiKey) {
    _models.clear();
    for (final modelName in AppConstants.geminiModelFallbacks) {
      _models.add((
        name: modelName,
        model: GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.3,
            maxOutputTokens: 8192,
          ),
        ),
      ));
    }
  }

  @override
  bool get isAvailable => _models.isNotEmpty;

  @override
  void updateApiKey(String apiKey) {
    if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      _buildModels(apiKey);
      _logger.info('Gemini API key updated, models rebuilt');
    }
  }

  @override
  Future<AiStrategyReportModel> generateStrategy({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) async {
    if (_models.isEmpty) {
      throw const LlmException(
        message: 'AI service not configured. Provide a valid Gemini API key.',
      );
    }

    final prompt = _buildStructuredPrompt(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
      languageName: languageName,
    );

    _logger.info('Sending prompt to Gemini', metadata: {
      'player': profile.name,
      'archetype': preferredArchetype,
      'card_count': profile.cards.length,
      'models_available': _models.length,
    });

    String? lastError;

    for (final entry in _models) {
      try {
        _logger.info('Trying model: ${entry.name}');
        final content = [Content.text(prompt)];
        final response = await entry.model.generateContent(content);
        final rawText = response.text;

        if (rawText == null || rawText.isEmpty) {
          throw const LlmException(message: 'Gemini returned empty response');
        }

        _logger.info('Gemini response received', metadata: {
          'model': entry.name,
          'response_length': rawText.length,
        });

        return AiStrategyReportModel.fromLlmResponse(rawText);
      } on LlmException {
        rethrow;
      } catch (e) {
        final msg = e.toString();
        _logger.error('Model ${entry.name} failed', error: e);

        if (_isQuotaError(msg) || _isModelNotFound(msg)) {
          _logger.warn('Skipping ${entry.name}: ${_isQuotaError(msg) ? "quota exceeded" : "model not found"}');
          lastError = msg;
          continue;
        }

        throw LlmException(message: 'Gemini API error: $e');
      }
    }

    throw LlmException(message: 'All Gemini models quota exceeded. Last error: $lastError');
  }

  @override
  Future<DeckAnalysisReportModel> analyzeDeck({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String languageName,
  }) async {
    if (_models.isEmpty) {
      throw const LlmException(message: 'AI service not configured.');
    }

    final prompt = _buildDeckAnalysisPrompt(
      profile: profile,
      battles: battles,
      languageName: languageName,
    );

    String? lastError;

    for (final entry in _models) {
      try {
        _logger.info('Analyzing deck with model: ${entry.name}');
        final response = await entry.model.generateContent([Content.text(prompt)]);
        final rawText = response.text;
        if (rawText == null || rawText.isEmpty) {
          throw const LlmException(message: 'Empty response from Gemini');
        }
        return DeckAnalysisReportModel.fromLlmResponse(rawText);
      } on LlmException {
        rethrow;
      } catch (e) {
        final msg = e.toString();
        _logger.error('Model ${entry.name} failed for deck analysis', error: e);
        if (_isQuotaError(msg) || _isModelNotFound(msg)) {
          lastError = msg;
          continue;
        }
        throw LlmException(message: 'Gemini API error: $e');
      }
    }

    throw LlmException(message: 'All models failed. Last error: $lastError');
  }

  @override
  Future<FullAnalysisReportModel> getFullAnalysis({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) async {
    if (_models.isEmpty) {
      throw const LlmException(message: 'AI service not configured.');
    }

    final prompt = _buildCombinedPrompt(
      profile: profile,
      battles: battles,
      preferredArchetype: preferredArchetype,
      languageName: languageName,
    );

    String? lastError;

    for (final entry in _models) {
      try {
        _logger.info('Full analysis with model: ${entry.name}');
        final response = await entry.model.generateContent([Content.text(prompt)]);
        final rawText = response.text;
        if (rawText == null || rawText.isEmpty) {
          throw const LlmException(message: 'Empty response from Gemini');
        }
        return FullAnalysisReportModel.fromLlmResponse(rawText);
      } on LlmException {
        rethrow;
      } catch (e) {
        final msg = e.toString();
        _logger.error('Model ${entry.name} failed for full analysis', error: e);
        if (_isQuotaError(msg) || _isModelNotFound(msg)) {
          lastError = msg;
          continue;
        }
        throw LlmException(message: 'Gemini API error: $e');
      }
    }

    throw LlmException(message: 'All models failed. Last error: $lastError');
  }

  String _deckKnowledgeBase() => '''
=== CLASH ROYALE DECK BUILDING FRAMEWORK ===

STEP 1 — UNIVERSAL COMPOSITION (every meta deck follows these):
• 1-2 win conditions (cards targeting only buildings OR that consistently reach the tower alone)
• 1-3 spells — at least 1 lightweight: Zap, Log, Snowball, Arrows, Ice Spirit
• AT LEAST 1 unit that hits AIR targets
• 2-4 support troops | 0-2 mini-tanks | 0-2 buildings

WIN CONDITIONS tier 1.0 (solo viable):
Royal Giant, Hog Rider, Royal Hogs, Giant, Wall Breakers, Goblin Barrel, X-Bow, Goblin Giant, Golem, Ram Rider, Graveyard
WIN CONDITIONS tier 0.5 (need specific support):
Skeleton Barrel, Mortar, Elixir Golem, Battle Ram, Three Musketeers, Balloon, Miner, Sparky, Lava Hound
NOT win conditions (PEKKA and Mega Knight are SUPPORT / COUNTER-PUSH only — never the primary win condition):
PEKKA, Mega Knight

---
STEP 2 — ARCHETYPE TEMPLATES WITH META REFERENCE DECKS

[AIRFECTA / LAVALOON] avg elixir 3.3–3.8
Core: Lava Hound + Balloon
Air supports (choose 2): Mega Minion, Minions, Baby Dragon, Inferno Dragon, Flying Machine
Ground units (MAX 2 — play them conservatively): Tombstone, Barbarians, Guards, Goblin Gang, Skeleton Army, Miner
Spells: 1 lightweight (Zap/Arrows/Snowball) + 1 heavy (Fireball/Lightning)
META DECK A: Lava Hound / Balloon / Mega Minion / Minions / Barbarians / Tombstone / Fireball / Zap
META DECK B: Lava Hound / Balloon / Mega Minion / Baby Dragon / Miner / Tombstone / Lightning / Arrows
RULE: You have only 2 ground cards — never waste them, they are your only ground defense.

[HOG RIDER CYCLE] avg elixir 2.6–3.3
Core: Hog Rider
Required: 1 mini-tank (Ice Golem, Knight, Valkyrie) + 1 defensive building (Cannon, Tesla) + ≥1 card costing ≤2 elixir
Spells: lightweight + heavy (Log+Fireball, Log+Rocket, Zap+Fireball). Alternative: Tornado+Executioner instead of heavy spell.
META DECK A (2.6): Hog Rider / Ice Golem / Skeletons / Ice Spirit / Musketeer / Cannon / Log / Fireball
META DECK B (Exnado): Hog Rider / Valkyrie / Goblins / Ice Spirit / Executioner / Tornado / Log / Rocket
RULE: Average elixir MUST stay ≤3.4 or the cycle loses its speed advantage.

[GOLEM BEATDOWN] avg elixir 4.0–5.0
Core: Golem
Near-mandatory trio: Night Witch (infinite bats) + Baby Dragon (splash) + Mega Minion (single-target air)
ALL support cards must survive a Fireball (>300 HP at tournament level)
Spells: lightweight + Tornado + Lightning/Poison. NEVER Rocket or Earthquake in a Golem deck.
META DECK A (Classic): Golem / Baby Dragon / Mega Minion / Night Witch / Lumberjack / Barbarian Barrel / Tornado / Lightning
META DECK B (Mini Pekka): Golem / Baby Dragon / Mega Minion / Night Witch / Mini Pekka / Bomber / Tornado / Lightning
RULE: Drop Golem from behind your King Tower when you reach 10 elixir. Build the full push behind it. Never drop Golem at the bridge.

[GRAVEYARD CONTROL]
Core trio (nearly inseparable): Graveyard + Poison + Tornado
Tank: 1 large tank (Giant, Golem) OR 2 mini-tanks (Knight, Baby Dragon, Bowler)
Air unit: 1 mandatory (Ice Wizard preferred, Musketeer acceptable)
Building: 1 (Goblin Hut or Bomb Tower)
META DECK: Graveyard / Baby Dragon / Knight / Ice Wizard / Goblin Hut / Tornado / Barbarian Barrel / Poison
RULE: Always pair Graveyard with Poison — Poison kills every skeleton-based counter (Skeleton Army, Graveyard itself, Guards).

[X-BOW SIEGE/CYCLE] avg elixir 2.9–3.5
Core: X-Bow + Tesla (Tesla is MANDATORY — never build X-Bow without it)
Mini-tank: 1 (Ice Golem or Knight)
Air unit: 1 (Archers, Musketeer, Ice Wizard)
Cheap cycle: Skeletons, Ice Spirit, Bats
Spells: Log + Rocket or Fireball. Add Tornado if using Ice Wizard.
META DECK A (2.9): X-Bow / Tesla / Ice Golem / Archers / Skeletons / Ice Spirit / Log / Fireball
META DECK B (3.5): X-Bow / Tesla / Knight / Ice Wizard / Skeletons / Log / Tornado / Rocket
RULE: Play defensively. Make positive elixir trades. Place X-Bow at the river on your half of the map.

[LOG/ZAP BAIT]
Core: Goblin Barrel
Mandatory: ≥3 units that die to Log or Zap (Goblin Gang, Princess, Dart Goblin, Minion Horde, Bats, Rascals, Skeleton Army, Minions)
Defensive building: Inferno Tower or Tesla
Spells: Rocket + Log
META DECK A (Classic Log Bait): Goblin Barrel / Goblin Gang / Princess / Knight / Ice Spirit / Inferno Tower / Log / Rocket
META DECK B (Prince Bait): Goblin Barrel / Goblin Gang / Princess / Rascals / Dart Goblin / Prince / Log / Rocket
RULE: Vary Goblin Barrel placement every single time — far corner, behind tower, in front of tower. Never be predictable.

[PEKKA BRIDGE SPAM]
Core: Battle Ram + PEKKA
Bridge spam units (pick 2–3): Bandit, Royal Ghost, Dark Prince, Cannon Cart, Electro Wizard
1 air unit mandatory (Minions, Baby Dragon, Magic Archer)
Spells: Zap (reset Inferno Tower/Dragon) + Poison (area damage on pushes)
META DECK: Battle Ram / PEKKA / Bandit / Electro Wizard / Dark Prince / Royal Ghost / Zap / Poison
RULE: PEKKA defends first, then immediately counter-push with the PEKKA + Battle Ram at the bridge.

[MORTAR CYCLE/BAIT]
Core: Mortar
MANDATORY: Rocket — without it you cannot close games
Mini-tank: 1 (Knight)
Air unit: 1 (Archers, Musketeer)
Cheap cycle: Ice Spirit, Bats, Skeletons
Spells: Rocket + 1–2 lightweight spells (Log, Arrows)
META DECK A (Cycle): Mortar / Knight / Archers / Bats / Ice Spirit / Log / Arrows / Rocket
META DECK B (Bait): Mortar / Miner / Rascals / Minion Horde / Spear Goblins / Goblin Gang / Log / Fireball

[GIANT BEATDOWN]
Core: Giant
Versatile combos: Graveyard, Sparky, Double Prince (Prince + Dark Prince)
Mini-tank: 1 (Mini Pekka or Mega Minion)
Air unit: 1 mandatory
Spells: always include Zap or Electro Spirit to reset Inferno Tower/Dragon; 1–3 spells total
META DECK A (Double Prince): Giant / Prince / Dark Prince / Electro Wizard / Mega Minion / Miner / Fireball / Zap
META DECK B (Graveyard Giant): Giant / Graveyard / Mini Pekka / Musketeer / Bats / Skeleton Army / Zap / Arrows

[ELIXIR GOLEM BEATDOWN]
Core: Elixir Golem
MANDATORY: Battle Healer — blobs from Elixir Golem feed her healing. Without Battle Healer this card is terrible.
Support: Baby Dragon, Electro Dragon (splash to clear blob trail area)
Building: generator-type preferred (Goblin Hut, Barbarian Hut) — more troops = more Battle Healer healing
Spells: Tornado (pull blobs toward Battle Healer) + Earthquake (destroy defensive buildings)
META DECK: Elixir Golem / Battle Healer / Baby Dragon / Electro Dragon / Night Witch / Barbarian Barrel / Tornado / Earthquake

[WALL BREAKERS CYCLE] avg elixir 2.8–3.4
Core: Wall Breakers + Miner (Miner is MANDATORY as instant tank for Wall Breakers)
Bait units: Bats, Spear Goblins, Goblins
Defense: Bomb Tower (safe) OR Mega Knight (aggressive)
Spells: Log mandatory + Poison
META DECK A (Bomb Tower): Wall Breakers / Miner / Knight / Bats / Spear Goblins / Bomb Tower / Log / Poison
META DECK B (Mega Knight): Wall Breakers / Miner / Mega Knight / Mini Pekka / Musketeer / Bats / Goblins / Zap

[THREE MUSKETEERS SPLIT PUSH]
Core: Three Musketeers
MANDATORY: Elixir Collector unless the deck has ≥3 cards costing ≤2 elixir
Secondary win condition: Royal Hogs or Battle Ram
RULE: ALWAYS drop Three Musketeers in the CENTER so they split into both lanes. Never in a corner.
RULE: Bait the enemy's heavy spell with Elixir Collector BEFORE playing Three Musketeers.
META DECK: Three Musketeers / Battle Ram / Bandit / Royal Ghost / Hunter / Ice Golem / Elixir Collector / Log

---
STEP 3 — SUBSTITUTION GUIDE (when player lacks a key meta card):
Night Witch → Witch or Baby Dragon (lose infinite bats, keep splash)
Lumberjack → Mini Pekka or Battle Ram (lose rage on death, keep pressure)
Ice Wizard → Musketeer (lose slow aura, keep air coverage)
Tombstone → Cannon or Tesla (lose skeleton spawn, keep distraction building)
Executioner → Baby Dragon (lose long range chain, keep splash)
Barbarian Barrel → Log or Zap (lose the Barbarian, keep knockback)
Princess → Dart Goblin or Archers (lose extreme range, keep cheap ranged unit)
Electro Wizard → Zap (lose spawn damage and reset body, keep Inferno reset)

---
STEP 4 — FORBIDDEN COMBINATIONS (never violate these):
✗ Elixir Golem WITHOUT Battle Healer
✗ X-Bow WITHOUT Tesla
✗ Goblin Barrel deck with fewer than 3 log-bait units
✗ Golem deck with Rocket or Earthquake
✗ Hog Rider deck with avg elixir above 3.4
✗ Three Musketeers without Elixir Collector when avg cost exceeds 4.5
✗ Mortar deck without Rocket
✗ Zero air-hitting units in any deck
✗ PEKKA or Mega Knight as the primary win condition
''';

  String _buildCombinedPrompt({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) {
    int wins = 0, losses = 0, draws = 0;
    for (var battle in battles.take(AppConstants.maxBattlesForAnalysis)) {
      final team = battle.team.isNotEmpty ? battle.team.first.crowns : 0;
      final opp = battle.opponent.isNotEmpty ? battle.opponent.first.crowns : 0;
      if (team > opp) { wins++; } else if (team < opp) { losses++; } else { draws++; }
    }

    final currentDeckInfo = profile.currentDeck.map((c) {
      final elixir = c.elixirCost != null ? ' (${c.elixirCost} elixir)' : '';
      final level = c.level != null ? ' Lv${c.level}' : '';
      return '${c.name}$elixir$level';
    }).join(', ');

    final collectionInfo = profile.cards.map((c) {
      final elixir = c.elixirCost != null ? ',"elixir":${c.elixirCost}' : '';
      return '{"name":"${c.name}","level":${c.level ?? 1},"id":${c.id}$elixir}';
    }).join(',');

    final collectionForSwaps = profile.cards
        .where((c) => !profile.currentDeck.any((d) => d.id == c.id))
        .map((c) => c.name)
        .take(30)
        .join(', ');

    final arenaGuide = ArenaGuide.findByName(profile.arenaName);
    final arenaMeta = arenaGuide != null
        ? '\nArena meta: ${arenaGuide.aiContext}\nCommon decks: ${arenaGuide.commonDecks.join('; ')}'
        : '';

    return '''
You are a Clash Royale Grand Master coach. Return a SINGLE JSON object with exactly two keys: "deck_analysis" and "strategy".

${_deckKnowledgeBase()}

=== PLAYER DATA ===
Player: ${profile.name} | Level: ${profile.expLevel ?? '?'} | Trophies: ${profile.trophies} | Arena: ${profile.arenaName}
Record: ${profile.wins ?? '?'} wins / ${profile.losses ?? '?'} losses | Recent: $wins wins, $losses losses, $draws draws (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} battles)
Preferred style: ${preferredArchetype.toUpperCase()}$arenaMeta

=== CURRENT DECK ===
$currentDeckInfo

=== FULL CARD COLLECTION (use ONLY these for strategy.suggested_deck) ===
[$collectionInfo]

=== AVAILABLE FOR SWAP SUGGESTIONS (cards NOT in current deck) ===
$collectionForSwaps

=== RESPONSE JSON SCHEMA ===
{
  "deck_analysis": {
    "grade": "B",
    "grade_explanation": "1-2 sentences why",
    "archetype": "Cycle",
    "avg_elixir": 3.1,
    "how_to_play": ["Opening: ...", "Defense: ...", "Win condition: ...", "Double elixir: ...", "Common mistake: ..."],
    "strengths": ["strength 1", "strength 2"],
    "weaknesses": ["weakness 1", "weakness 2"],
    "suggested_swaps": [
      {"remove": "card name from current deck", "add": "card from available swaps list", "reason": "..."}
    ],
    "overall_feedback": "2-3 sentence coach summary"
  },
  "strategy": {
    "playstyle_analysis": "2-3 sentences: which META DECK TEMPLATE was used as base, which cards were substituted and why",
    "archetype_explanation": "2-3 sentences explaining the archetype gameplan to a beginner",
    "meta_coaching": "2-3 sentences about trophy-range threats and coaching",
    "suggested_deck": [{"id": <int>, "name": "<card name>"}],
    "deck_breakdown": {
      "win_condition": ["card names"],
      "spells": ["card names"],
      "air_defense": ["card names"],
      "support": ["card names"],
      "buildings": ["card names"]
    },
    "battle_guide": {
      "opening_move": "Primary first play + what to do if opponent plays first. Name the specific card and position.",
      "elixir_management": "When to spend, when to save, minimum elixir before committing to a push.",
      "defense": "How to use specific cards in this deck to stop common threats at this trophy range.",
      "win_condition_execution": "Step-by-step push recipe: Step 1 → Step 2 → Step 3. Use exact card names.",
      "double_elixir_strategy": "How gameplay changes in double elixir. Which cards become key?",
      "common_mistakes": "Top 3 mistakes players make with this archetype and how to avoid them with this deck."
    },
    "matchup_tips": [{"enemy_archetype": "Beatdown", "tip": "..."}],
    "confidence_score": 0.8
  }
}

STRICT RULES:
1. For strategy.suggested_deck: start from the META DECK TEMPLATE that best fits the preferred archetype, then replace missing cards with the closest substitute from the COLLECTION LIST using the SUBSTITUTION GUIDE.
2. Explain every substitution in strategy.playstyle_analysis.
3. NEVER violate the FORBIDDEN COMBINATIONS list.
4. strategy.suggested_deck: EXACTLY 8 cards, ALL from the full collection list, with correct "id" values from that list.
5. strategy.confidence_score: 1.0 = player owns all meta template cards, 0.7 = 1-2 substitutions needed, 0.5 = 3-4 substitutions, 0.3 = missing core archetype cards.
6. deck_analysis.grade scale: S (elite meta deck), A (strong), B (solid), C (average), D (needs work), F (poor).
7. deck_analysis.suggested_swaps: max 2 entries; use ONLY cards from the available swaps list; empty [] if deck is already strong.
8. strategy.matchup_tips: at least 3 archetypes common at the player's trophy range.
9. Response MUST be ONLY the JSON object — no markdown, no code blocks, no extra text.
10. LANGUAGE: All text values in $languageName. Keep all JSON keys in English.
''';
  }

  String _buildDeckAnalysisPrompt({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String languageName,
  }) {
    int wins = 0, losses = 0;
    for (var battle in battles.take(AppConstants.maxBattlesForAnalysis)) {
      final team = battle.team.isNotEmpty ? battle.team.first.crowns : 0;
      final opp = battle.opponent.isNotEmpty ? battle.opponent.first.crowns : 0;
      if (team > opp) { wins++; } else if (team < opp) { losses++; }
    }

    final currentDeckInfo = profile.currentDeck.map((c) {
      final elixir = c.elixirCost != null ? ' (${c.elixirCost} elixir)' : '';
      final level = c.level != null ? ' Lv${c.level}' : '';
      return '${c.name}$elixir$level';
    }).join(', ');

    final collectionForSwaps = profile.cards
        .where((c) => !profile.currentDeck.any((d) => d.id == c.id))
        .map((c) => c.name)
        .take(30)
        .join(', ');

    return '''
You are an expert Clash Royale coach. Analyze the player's CURRENT deck exactly as-is.
Do NOT suggest a completely new deck — only suggest 0-2 card swaps if clearly beneficial.
Respond ONLY with valid JSON matching the schema below.

=== PLAYER DATA ===
Player: ${profile.name}
Level: ${profile.expLevel ?? 'unknown'}
Arena: ${profile.arenaName}
Trophies: ${profile.trophies}
Recent Record: $wins wins / $losses losses (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} battles)

=== CURRENT DECK (analyze this) ===
$currentDeckInfo

=== AVAILABLE CARDS FOR SWAP SUGGESTIONS ===
$collectionForSwaps

=== JSON SCHEMA ===
{
  "grade": "B",
  "grade_explanation": "1-2 sentences why this grade",
  "archetype": "Cycle",
  "avg_elixir": 3.1,
  "how_to_play": [
    "Abertura: ...",
    "Defesa: ...",
    "Condição de vitória: ...",
    "Duplo elixir: ...",
    "Erro mais comum: ..."
  ],
  "strengths": ["strength 1", "strength 2"],
  "weaknesses": ["weakness 1", "weakness 2"],
  "suggested_swaps": [
    {"remove": "card name", "add": "card from collection", "reason": "..."}
  ],
  "overall_feedback": "2-3 sentence coach summary"
}

RULES:
- Grade scale: S (elite meta deck), A (strong), B (solid), C (average), D (needs work), F (poor)
- "how_to_play" must have 4-6 specific, actionable tips using exact card names from the current deck
- "suggested_swaps" max 2 entries; only use cards from the available collection list; leave empty [] if deck is already strong
- avg_elixir: calculate the real average from the deck cards provided
- Response must be ONLY the JSON — no markdown, no code blocks
- LANGUAGE INSTRUCTION: All text values must be written in $languageName. Keep JSON keys in English.
''';
  }

  bool _isQuotaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('resource_exhausted') ||
        lower.contains('rate limit') ||
        lower.contains('exceeded your current quota');
  }

  bool _isModelNotFound(String message) {
    final lower = message.toLowerCase();
    return lower.contains('not found') ||
        lower.contains('not supported') ||
        lower.contains('listmodels');
  }

  String _buildStructuredPrompt({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) {
    // Prepare card collection info
    final collectionInfo = profile.cards.map((c) {
      final elixir = c.elixirCost != null ? ',"elixir":${c.elixirCost}' : '';
      return '{"name":"${c.name}","level":${c.level ?? 1},"id":${c.id}$elixir}';
    }).join(',');

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
    final arenaGuide = ArenaGuide.findByName(profile.arenaName);
    final arenaMeta = arenaGuide != null
        ? '\n=== ARENA META ===\n${arenaGuide.aiContext}\nDecks comuns nesta arena: ${arenaGuide.commonDecks.join('; ')}'
        : '';

    return '''
You are a Clash Royale Grand Master and deck building expert.
Analyze the player data below and respond ONLY with a valid JSON object matching the schema.

${_deckKnowledgeBase()}

=== HOW TO BUILD THE SUGGESTED DECK ===
1. Identify the META DECK TEMPLATE above that best matches the player's preferred archetype: ${preferredArchetype.toUpperCase()}
2. Check which cards from that template exist in the player's CARD COLLECTION
3. For each missing card, apply the SUBSTITUTION GUIDE to find the best replacement from the collection
4. Verify the final 8-card deck does NOT violate any FORBIDDEN COMBINATION
5. Record every substitution in playstyle_analysis

=== HOW TO WRITE BATTLE GUIDE ===
- Use EXACT card names from suggested_deck
- Give POSITIONAL guidance: "play Hog Rider at the river on the left lane"
- Explain TIMING: "only commit to a push when you have 8+ elixir"
- Explain REACTIONS: "if opponent drops Golem in the back, immediately split push opposite lane"
- Write win_condition_execution as a numbered recipe: Step 1 → Step 2 → Step 3
- For opening_move: always give PRIMARY plan + REACTIVE plan if opponent plays first

=== PLAYER DATA ===
Player: ${profile.name}
Level: ${profile.expLevel ?? 'unknown'}
Trophies: ${profile.trophies}${profile.bestTrophies != null ? ' (best: ${profile.bestTrophies})' : ''}
Arena: ${profile.arenaName}
Lifetime Record: ${profile.wins ?? '?'} wins / ${profile.losses ?? '?'} losses
Current Deck: $currentDeckNames
Recent Performance (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} matches): $wins wins, $losses losses, $draws draws
Preferred Style: ${preferredArchetype.toUpperCase()}
$arenaMeta

=== CARD COLLECTION (use ONLY cards from this list, with their exact id values) ===
[$collectionInfo]

=== RESPONSE JSON SCHEMA ===
{
  "playstyle_analysis": "2-3 sentences: which META DECK TEMPLATE was used as base, which cards were substituted from the collection and why",
  "archetype_explanation": "2-3 sentences: explain the archetype gameplan to a beginner in plain language",
  "meta_coaching": "2-3 sentences: trophy-range specific coaching and common threats",
  "suggested_deck": [{"id": <card_id_int>, "name": "<card_name>"}],
  "deck_breakdown": {
    "win_condition": ["card names"],
    "spells": ["card names"],
    "air_defense": ["card names"],
    "support": ["card names"],
    "buildings": ["card names"]
  },
  "battle_guide": {
    "opening_move": "Primary first play + what to do if opponent plays first. Name specific card and position.",
    "elixir_management": "When to spend, when to save, minimum elixir before committing to a push.",
    "defense": "How to use specific cards in this deck to stop common threats at this trophy range.",
    "win_condition_execution": "Step-by-step push recipe. Step 1 → Step 2 → Step 3. Use exact card names.",
    "double_elixir_strategy": "How gameplay changes in double elixir. Which cards become key?",
    "common_mistakes": "Top 3 mistakes players make with this archetype and how to avoid them with this deck."
  },
  "matchup_tips": [{"enemy_archetype": "Beatdown", "tip": "..."}],
  "confidence_score": <float 0.0-1.0>
}

STRICT RULES:
1. suggested_deck: EXACTLY 8 cards, ALL from the collection list, with correct "id" values.
2. Start from the matching META DECK TEMPLATE. Substitute missing cards from the collection using the SUBSTITUTION GUIDE.
3. NEVER violate the FORBIDDEN COMBINATIONS list.
4. PEKKA and Mega Knight are NEVER the primary win condition.
5. Every deck MUST have at least 1 card that hits air units.
6. confidence_score: 1.0 = player owns all meta template cards, 0.7 = 1-2 substitutions, 0.5 = 3-4 substitutions, 0.3 = missing core archetype cards.
7. matchup_tips: at least 3 archetypes common at the player's trophy range.
8. Response must be ONLY the JSON object — no markdown, no code blocks, no extra text.
9. LANGUAGE: All text values in $languageName. Keep all JSON keys in English.
''';
  }
}

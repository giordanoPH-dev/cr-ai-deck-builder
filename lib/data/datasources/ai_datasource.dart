import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/app_constants.dart';
import '../../core/data/arena_guide.dart';
import '../../core/error/exceptions.dart';
import '../../core/observability/logger_service.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';
import '../models/ai_strategy_report_model.dart';
import '../models/deck_analysis_report_model.dart';
import '../models/full_analysis_report_model.dart';

/// Data source for AI strategy generation via Google Gemini.
///
/// Key improvements:
/// - Champion (🟡) and Evolution (🟣) card detection and prioritization
/// - Level-aware card selection (avoids under-leveled cards)
/// - Tournament-standard level context per arena
/// - Explicit Grade S optimization
/// - Special slot rules (max 1 Champion + max 2 Evolutions)
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

  // ── Champion cards (yellow border, 3-elixir, manual ability, fill slot C) ──
  static const Set<String> _championCardNames = {
    'Archer Queen',
    'Golden Knight',
    'Skeleton King',
    'Mighty Miner',
    'Monk',
    'Little Prince',
    'Magician',
  };

  // ── Evolution cards (purple border, cycle mechanic, fill slots E1 & E2) ──
  // CR API marks evolved cards via evolutionLevel > 0 on the card object.
  // The prefixes below handle legacy API responses that prepend "Evolved " to the name.
  static const Set<String> _evolutionPrefixes = {'evolved ', 'evo '};

  // ── Tournament standard card levels by king tower level (approximate) ──
  static const Map<String, int> _arenaTournamentLevel = {
    // Arenas 1-6 (Training → Goblin Stadium)
    'Training Camp': 9,
    'Goblin Stadium': 9,
    'Bone Pit': 9,
    'Barbarian Bowl': 9,
    'P.E.K.K.A\'s Playhouse': 10,
    'Spell Valley': 10,
    // Arenas 7-12
    'Builder\'s Workshop': 10,
    'Royal Arena': 11,
    'Frozen Peak': 11,
    'Jungle Arena': 11,
    'Hog Mountain': 12,
    'Electro Valley': 12,
    // Arenas 13-17
    'Spooky Town': 12,
    'Rascal\'s Hideout': 13,
    'Serenity Peak': 13,
    'Icy Peak': 13,
    'Executioner\'s Kitchen': 13,
    // Trophy Road / Leagues
    'Master I': 14,
    'Master II': 14,
    'Master III': 14,
    'Champion': 14,
    'Grand Champion': 14,
    'Royal Champion': 14,
    'Ultimate Champion': 15,
    'Legend League': 15,
  };

  // ── Trophy-based tournament level fallback ──────────────────────────────────
  // More reliable than arena name string matching for unknown/event arenas.
  static int _tournamentLevelFromTrophies(int trophies) {
    if (trophies >= 7000) return 15;
    if (trophies >= 5000) return 14;
    if (trophies >= 4000) return 13;
    if (trophies >= 3000) return 12;
    if (trophies >= 1500) return 11;
    if (trophies >= 700) return 10;
    return 9;
  }

  AiDatasourceImpl({String? apiKey, required LoggerService logger})
    : _logger = logger {
    if (apiKey != null &&
        apiKey.isNotEmpty &&
        apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
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

  // ────────────────────────────────────────────────────────────────────────────
  // Card type detection helpers
  // ────────────────────────────────────────────────────────────────────────────

  /// Returns [CHAMPION], [EVOLUTION], or empty string for a full card object.
  ///
  /// Detection logic:
  /// - currentDeck: `evolutionLevel > 0` = card is slotted as an evolution
  /// - cards collection: `maxEvolutionLevel != null` = evolvable card owned
  /// - Fallback: name prefix for legacy API responses ("Evolved X")
  String _cardTypeLabelForCard(CrCard c) {
    final lower = c.name.toLowerCase();
    if (_championCardNames.any((n) => n.toLowerCase() == lower)) {
      return '[CHAMPION]';
    }
    if ((c.evolutionLevel ?? 0) > 0) return '[EVOLUTION]';
    if (c.maxEvolutionLevel != null) return '[EVOLUTION]';
    for (final prefix in _evolutionPrefixes) {
      if (lower.startsWith(prefix)) return '[EVOLUTION]';
    }
    return '';
  }

  /// How many levels away from the card's own rarity max.
  /// 0 = maxed, negative = not yet maxed.
  int _deltaFromMax(CrCard c) => (c.level ?? 1) - (c.maxLevel ?? 14);

  /// Returns the estimated level gap between a card's level and the tournament
  /// standard for the given arena. Negative = under-leveled.
  int _levelGap(int cardLevel, String arenaName, [int trophies = 0]) {
    final standard =
        _arenaTournamentLevel[arenaName] ??
        _arenaTournamentLevel.entries
            .where((e) => arenaName.contains(e.key.split(' ').first))
            .map((e) => e.value)
            .firstOrNull ??
        (trophies > 0 ? _tournamentLevelFromTrophies(trophies) : 12);
    return cardLevel - standard;
  }

  /// Splits the collection into deck-buildable cards and truly unusable ones.
  ///
  /// Uses delta-from-max (level - maxLevel) so that different rarities are
  /// compared fairly: a maxed Legendary (10/10) scores the same as a maxed
  /// Common (14/14), both at delta = 0.
  /// Cards within 4 levels of the player's best delta go to [primary].
  /// Champions and Evolutions always go to [primary] regardless of level.
  ({String primary, String upgradeable}) _buildFilteredCollection(
    PlayerProfile profile,
  ) {
    // bestDelta = 0 if any card is maxed; otherwise the highest (least negative) delta.
    final bestDelta = profile.cards
        .map(_deltaFromMax)
        .fold(0, (best, d) => d > best ? d : best);
    final usableThreshold = bestDelta - 4;

    final primaryCards = <CrCard>[];
    final upgradeableCards = <CrCard>[];

    for (final c in profile.cards) {
      final isSpecial = _cardTypeLabelForCard(c).isNotEmpty;
      if (_deltaFromMax(c) >= usableThreshold || isSpecial) {
        primaryCards.add(c);
      } else {
        upgradeableCards.add(c);
      }
    }

    // Sort: Champions → Evolutions → regulars (closest to max first)
    primaryCards.sort((a, b) {
      final aTag = _cardTypeLabelForCard(a);
      final bTag = _cardTypeLabelForCard(b);
      final aOrd = aTag == '[CHAMPION]' ? 0 : aTag == '[EVOLUTION]' ? 1 : 2;
      final bOrd = bTag == '[CHAMPION]' ? 0 : bTag == '[EVOLUTION]' ? 1 : 2;
      if (aOrd != bOrd) return aOrd.compareTo(bOrd);
      return _deltaFromMax(b).compareTo(_deltaFromMax(a));
    });

    final primaryStr = primaryCards.map((c) {
      final typeTag = _cardTypeLabelForCard(c);
      final type = typeTag.isEmpty
          ? 'REGULAR'
          : typeTag.replaceAll('[', '').replaceAll(']', '');
      final elixir = c.elixirCost != null ? ',"elixir":${c.elixirCost}' : '';
      final level = c.level ?? 1;
      final relGap = _deltaFromMax(c) - bestDelta;
      final levelNote = relGap >= -1
          ? 'BEST_IN_COLLECTION'
          : relGap >= -3
          ? 'GOOD'
          : 'USABLE';
      return '{"name":"${c.name}","level":$level,"id":${c.id}$elixir,"type":"$type","level_note":"$levelNote"}';
    }).join(',');

    final upgradeableStr = upgradeableCards.isEmpty
        ? 'none'
        : upgradeableCards.map((c) => '${c.name} Lv${c.level ?? 1}').join(', ');

    return (primary: primaryStr, upgradeable: upgradeableStr);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────────────────

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

    _logger.info(
      'Sending prompt to Gemini',
      metadata: {
        'player': profile.name,
        'archetype': preferredArchetype,
        'card_count': profile.cards.length,
        'models_available': _models.length,
      },
    );

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

        _logger.info(
          'Gemini response received',
          metadata: {'model': entry.name, 'response_length': rawText.length},
        );

        return AiStrategyReportModel.fromLlmResponse(rawText);
      } on LlmException {
        rethrow;
      } catch (e) {
        final msg = e.toString();
        _logger.error('Model ${entry.name} failed', error: e);

        if (_isQuotaError(msg) || _isModelNotFound(msg)) {
          _logger.warn(
            'Skipping ${entry.name}: ${_isQuotaError(msg) ? "quota exceeded" : "model not found"}',
          );
          lastError = msg;
          continue;
        }

        throw LlmException(message: 'Gemini API error: $e');
      }
    }

    throw LlmException(
      message: 'All Gemini models quota exceeded. Last error: $lastError',
    );
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
        final response = await entry.model.generateContent([
          Content.text(prompt),
        ]);
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
        final response = await entry.model.generateContent([
          Content.text(prompt),
        ]);
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

  // ────────────────────────────────────────────────────────────────────────────
  // Knowledge base
  // ────────────────────────────────────────────────────────────────────────────

  String _deckKnowledgeBase() => '''
=== CLASH ROYALE DECK BUILDING FRAMEWORK ===

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 0 — SPECIAL CARD SLOTS (PRIORITY #1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Every Clash Royale deck has 3 special slots beyond the 5 regular slots:
  • CHAMPION slot (C) — max 1 per deck. Yellow-border card, costs 3 elixir, has a manually-activated ability.
  • EVOLUTION slot E1 & E2 — max 2 per deck. Purple-border cards. After cycling through the base card twice, the next copy is the evolved "supercharged" version.

RULE: If the player owns at least one Champion at AT_META or SLIGHTLY_UNDER level, include it — the power gain is too large to skip.
RULE: If the player owns at least one Evolution at AT_META or SLIGHTLY_UNDER level, include it (up to 2).
RULE: Evolutions must still fulfill a composition role (the evolved version cannot be the only air-hitter or the only spell, etc.).
RULE: A SEVERELY_UNDER Champion or Evolution may be included ONLY if no AT_META alternative exists and the ability compensates for the stat deficit.

── CHAMPION CARD REFERENCE ──
Each champion has a 3-elixir base cost and a rechargeable ability. Include in suggested_deck when available at acceptable level.

• Archer Queen — ranged attacker. Ability: Cloaking Strike (briefly invisible + summons Archers). Best in: Log Bait, Hog Rider cycle. Pairs with spells that cover her range weakness.
• Golden Knight — melee tank. Ability: Dashing Dash (charges across the arena stunning enemies). Best in: Bridge Spam, Midladder push. Pairs with Skeleton Army or support troops.
• Skeleton King — melee tank. Ability: Soul Summoning (collects souls from dying troops to summon a skeleton swarm). Best in: Control, Graveyard. Pairs with swarm decks.
• Mighty Miner — digs under defenses. Ability: Drill Charge (charges into tower for bonus damage). Best in: Miner cycle, Wall Breakers. Pairs with Miner-style win conditions.
• Monk — melee, high HP. Ability: Pensive Protection (deflects all projectiles for a short time). Best in: Any deck needing a tanky defender against spells. Excellent with Graveyard / Beatdown.
• Little Prince — summons Shield Maiden. Ability: Royal Rescue (calls Shield Maiden to protect him). Best in: Control and midrange decks.
• Magician — ranged splash. Ability: Grand Illusion (creates a temporary clone that attacks). Best in: Cycle and midrange decks that need cheap splash.

── EVOLUTION CARD REFERENCE ──
Evolutions enhance the base card with a unique trait that activates after cycling it twice.
Include when available and when it replaces or upgrades a card the deck already needs.

• Evo Barbarians — spawn already enraged; super-fast burst; best for Hog Rider cycle, Log Bait.
• Evo Skeletons — spawns with extra skeleton (4 total) + they hop at enemies; excellent cycle card.
• Evo Knight — gains a shield on spawn; best defensive mini-tank swap.
• Evo Archers — split into two individual Archers that can cover both lanes simultaneously.
• Evo Bomber — lobs bombs that bounce; great aoe in Golem / Beatdown decks.
• Evo Ice Spirit — creates a larger freeze ring; excellent in Hog cycle or any fast deck.
• Evo Valkyrie — spins while moving, continuous splash; upgrade for Hog Rider decks.
• Evo Firecracker — fires in 3 directions on death; great in control / X-Bow decks.
• Evo Tesla — permanently active, deals higher DPS; excellent defensive building upgrade.
• Evo Musketeer — shoots three bullets at once (pierces); excellent in Beatdown / Golem.
• Evo Goblin Barrel — extra Goblin (4 total) + faster delivery; must-have in Log Bait.
• Evo Bats — summons faster and with more bats; great in cycle decks.
• Evo Mortar — fires two mortars simultaneously; strong upgrade in Mortar siege.
• Evo Royal Giant — gains a shield on each push; strong mid-ladder.
• Evo Giant Skeleton — bomb has more HP and travels further.
• Evo Cannon — faster targeting and shots; great defensive building.
• Evo Dark Prince — charges further distance and more frequently.
• Evo Mega Knight — spawn & jump damage area is larger.
• Evo Hog Rider — charges all the way to the tower on bridge placement; major upgrade in any Hog deck.
• Evo Electro Dragon — chain lightning hits more targets.
• Evo Three Musketeers — split+charge immediately on spawn.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 1 — CARD SELECTION RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Each card in the USABLE CARDS list is tagged with a level_note relative to the player's best cards:
  BEST_IN_COLLECTION → player's top-tier cards. USE FREELY — always prioritize these.
  GOOD               → solid cards, slightly below the player's best. Use when no BEST_IN_COLLECTION fills that role.
  USABLE             → acceptable only if no BEST_IN_COLLECTION or GOOD option exists for the role. Always explain in deck_notes.

Cards NOT in the USABLE CARDS list are too far below the collection standard — DO NOT use them.

RULE: Among cards that fill the same role, ALWAYS prefer the one with the highest level_note (BEST > GOOD > USABLE).
RULE: A deck using all BEST_IN_COLLECTION cards scores higher than the same deck using GOOD/USABLE cards.
RULE: Document any USABLE-tier card choice in "deck_notes" — explain why no better option existed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 2 — UNIVERSAL COMPOSITION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Every meta deck must have:
  • 1-2 win conditions
  • 1-3 spells (at least 1 lightweight: Zap, Log, Snowball, Arrows, Ice Spirit)
  • AT LEAST 1 unit that hits AIR targets
  • 2-4 support troops | 0-2 mini-tanks | 0-2 buildings
  • 0-1 Champion (if available at acceptable level)
  • 0-2 Evolutions (if available at acceptable level, filling composition roles)

WIN CONDITIONS tier 1.0 (solo viable):
Royal Giant, Hog Rider, Royal Hogs, Giant, Wall Breakers, Goblin Barrel, X-Bow, Goblin Giant, Golem, Ram Rider, Graveyard
WIN CONDITIONS tier 0.5 (need specific support):
Skeleton Barrel, Mortar, Elixir Golem, Battle Ram, Three Musketeers, Balloon, Miner, Sparky, Lava Hound
NOT win conditions (support / counter-push only):
PEKKA, Mega Knight

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 3 — ARCHETYPE TEMPLATES WITH META REFERENCE DECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[AIRFECTA / LAVALOON] avg elixir 3.3–3.8
Core: Lava Hound + Balloon
Air supports (choose 2): Mega Minion, Minions, Baby Dragon, Inferno Dragon, Flying Machine
Ground units (MAX 2): Tombstone, Barbarians, Guards, Goblin Gang, Skeleton Army, Miner
Spells: 1 lightweight + 1 heavy (Fireball/Lightning)
Champions that fit: Archer Queen (ranged air support, cloaks to reposition)
Evolutions that fit: Evo Minions (more minions for air coverage), Evo Bats
META DECK A: Lava Hound / Balloon / Mega Minion / Minions / Barbarians / Tombstone / Fireball / Zap
META DECK B: Lava Hound / Balloon / Mega Minion / Baby Dragon / Miner / Tombstone / Lightning / Arrows
RULE: Only 2 ground cards — never waste them.

[HOG RIDER CYCLE] avg elixir 2.6–3.3
Core: Hog Rider
Required: 1 mini-tank (Ice Golem, Knight, Valkyrie) + 1 defensive building (Cannon, Tesla) + ≥1 card ≤2 elixir
Spells: lightweight + heavy (Log+Fireball, Log+Rocket, Zap+Fireball)
Champions that fit: Archer Queen (ranged support behind Hog), Golden Knight (bridge + Hog double push)
Evolutions that fit: Evo Hog Rider (+++ direct upgrade), Evo Ice Spirit (better freeze ring), Evo Barbarians (faster defense), Evo Valkyrie (spinning splash defense), Evo Tesla (stronger building)
META DECK A (2.6): Hog Rider / Ice Golem / Skeletons / Ice Spirit / Musketeer / Cannon / Log / Fireball
META DECK B (Exnado): Hog Rider / Valkyrie / Goblins / Ice Spirit / Executioner / Tornado / Log / Rocket
RULE: Average elixir MUST stay ≤3.4.

[GOLEM BEATDOWN] avg elixir 4.0–5.0
Core: Golem
Near-mandatory trio: Night Witch + Baby Dragon + Mega Minion
Spells: lightweight + Tornado + Lightning/Poison
Champions that fit: Monk (deflects spells protecting the push), Archer Queen (covers air flank)
Evolutions that fit: Evo Bomber (persistent aoe behind Golem), Evo Musketeer (3-bullet pierce)
META DECK A: Golem / Baby Dragon / Mega Minion / Night Witch / Lumberjack / Barbarian Barrel / Tornado / Lightning
META DECK B: Golem / Baby Dragon / Mega Minion / Night Witch / Mini Pekka / Bomber / Tornado / Lightning
RULE: Drop Golem from behind King Tower at 10 elixir. NEVER at the bridge.

[GRAVEYARD CONTROL]
Core trio: Graveyard + Poison + Tornado
Tank: 1 large (Giant, Golem) OR 2 mini-tanks
Air unit: 1 mandatory (Ice Wizard preferred)
Champions that fit: Skeleton King (soul collection synergy with skeletons dying), Monk (protects setup)
Evolutions that fit: Evo Giant Skeleton (tankier bomb), Evo Archers (covers both lanes)
META DECK: Graveyard / Baby Dragon / Knight / Ice Wizard / Goblin Hut / Tornado / Barbarian Barrel / Poison
RULE: Always pair Graveyard + Poison.

[X-BOW SIEGE] avg elixir 2.9–3.5
Core: X-Bow + Tesla (MANDATORY — never X-Bow without Tesla)
Air unit: 1 mandatory
Cheap cycle: Skeletons, Ice Spirit, Bats
Champions that fit: Archer Queen (punishes opponent rushing X-Bow)
Evolutions that fit: Evo Tesla (permanently active, stronger defense), Evo Ice Spirit (bigger freeze), Evo Firecracker (aoe deterrent)
META DECK A: X-Bow / Tesla / Ice Golem / Archers / Skeletons / Ice Spirit / Log / Fireball
META DECK B: X-Bow / Tesla / Knight / Ice Wizard / Skeletons / Log / Tornado / Rocket
RULE: Play defensively. Place X-Bow at the river on your side.

[LOG/ZAP BAIT]
Core: Goblin Barrel
Mandatory: ≥3 units that die to Log or Zap
Defensive building: Inferno Tower or Tesla
Champions that fit: Archer Queen (Cloaking Strike baits another spell)
Evolutions that fit: Evo Goblin Barrel (+1 goblin, faster; MASSIVE upgrade), Evo Bats (more bats to bait Zap/Log)
META DECK A: Goblin Barrel / Goblin Gang / Princess / Knight / Ice Spirit / Inferno Tower / Log / Rocket
META DECK B: Goblin Barrel / Goblin Gang / Princess / Rascals / Dart Goblin / Prince / Log / Rocket
RULE: Vary Goblin Barrel placement every single throw.

[PEKKA BRIDGE SPAM]
Core: Battle Ram + PEKKA
Bridge spam (2-3): Bandit, Royal Ghost, Dark Prince, Cannon Cart, Electro Wizard
Champions that fit: Golden Knight (Dashing Dash stuns + pushes with PEKKA)
Evolutions that fit: Evo Dark Prince (longer charge), Evo Mega Knight (larger jump aoe)
META DECK: Battle Ram / PEKKA / Bandit / Electro Wizard / Dark Prince / Royal Ghost / Zap / Poison
RULE: PEKKA defends first, then counter-push immediately with PEKKA + Battle Ram.

[MORTAR CYCLE/BAIT]
Core: Mortar + Rocket (MANDATORY pair)
Champions that fit: Magician (cheap splash cycle)
Evolutions that fit: Evo Mortar (double mortar fire, massively stronger)
META DECK A: Mortar / Knight / Archers / Bats / Ice Spirit / Log / Arrows / Rocket
META DECK B: Mortar / Miner / Rascals / Minion Horde / Spear Goblins / Goblin Gang / Log / Fireball

[GIANT BEATDOWN]
Core: Giant
Combos: Graveyard, Sparky, Double Prince
Air unit: 1 mandatory. Zap/Electro Spirit mandatory to reset Inferno.
Champions that fit: Skeleton King (soul farm behind Giant), Little Prince (extra tank + shield maiden)
Evolutions that fit: Evo Archers (split-lane threat), Evo Bomber (aoe behind Giant)
META DECK A: Giant / Prince / Dark Prince / Electro Wizard / Mega Minion / Miner / Fireball / Zap
META DECK B: Giant / Graveyard / Mini Pekka / Musketeer / Bats / Skeleton Army / Zap / Arrows

[ELIXIR GOLEM BEATDOWN]
Core: Elixir Golem + Battle Healer (MANDATORY pair)
Champions that fit: Monk (deflects spells protecting the push)
Evolutions that fit: Evo Electro Dragon (more chain hits clear the blob trail area)
META DECK: Elixir Golem / Battle Healer / Baby Dragon / Electro Dragon / Night Witch / Barbarian Barrel / Tornado / Earthquake

[WALL BREAKERS CYCLE] avg elixir 2.8–3.4
Core: Wall Breakers + Miner (MANDATORY pair)
Champions that fit: Mighty Miner (direct synergy — drills under defenses like Miner)
Evolutions that fit: Evo Bats (cheap cycle with more bats)
META DECK A: Wall Breakers / Miner / Knight / Bats / Spear Goblins / Bomb Tower / Log / Poison
META DECK B: Wall Breakers / Miner / Mega Knight / Mini Pekka / Musketeer / Bats / Goblins / Zap

[MINER CONTROL] avg elixir 3.0–3.5
Core: Miner + Poison (MANDATORY pair — Miner chips the tower, Poison covers the area)
Defense: 1 building (Tombstone or Tesla) + 1 mini-tank (Knight, Valkyrie)
Support: 2 cheap swarm units for cycling and defense (Goblin Gang, Minions, Bats, Spear Goblins)
Air unit: Minions or Bats (mandatory — defends Balloon and Lava Hound pushes)
Spells: Poison + 1 lightweight (Zap, Log, or Arrows)
Champions that fit: Mighty Miner (drills under defenses just like Miner, direct synergy), Archer Queen (ranged chip + bait)
Evolutions that fit: Evo Goblin Barrel (secondary pressure win condition), Evo Bats (more bats for faster cycling)
META DECK A: Miner / Poison / Goblin Gang / Minions / Knight / Tombstone / Zap / Arrows
META DECK B: Miner / Poison / Goblin Gang / Bats / Valkyrie / Tesla / Log / Fireball
RULE: Play reactively — never rush. Defend first, then counter-push immediately with Miner.
RULE: Poison placement must cover both the Miner landing zone and the tower simultaneously.
RULE: This is a CONTROL archetype — patience wins. Chip damage from Miner adds up over many cycles.

[THREE MUSKETEERS SPLIT PUSH]
Core: Three Musketeers + Elixir Collector (MANDATORY unless ≥3 cards cost ≤2 elixir)
Secondary win condition: Royal Hogs or Battle Ram
Champions that fit: Golden Knight (Dash charges across the split)
Evolutions that fit: Evo Three Musketeers (split+charge immediately)
META DECK: Three Musketeers / Battle Ram / Bandit / Royal Ghost / Hunter / Ice Golem / Elixir Collector / Log
RULE: ALWAYS drop Three Musketeers in CENTER. Bait heavy spell with Elixir Collector first.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 4 — SUBSTITUTION GUIDE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Night Witch → Witch or Baby Dragon
Lumberjack → Mini Pekka or Battle Ram
Ice Wizard → Musketeer
Tombstone → Cannon or Tesla (prefer Evo Tesla if available)
Executioner → Baby Dragon
Barbarian Barrel → Log or Zap
Princess → Dart Goblin or Archers (prefer Evo Archers if available)
Electro Wizard → Zap (or Evo Ice Spirit for reset utility)
Champion (any) → Best available AT_META 3-elixir card for that role
Evolution (any) → Base card version at highest level available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PART 5 — FORBIDDEN COMBINATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✗ Elixir Golem WITHOUT Battle Healer
✗ X-Bow WITHOUT Tesla
✗ Goblin Barrel deck with fewer than 3 log-bait units
✗ Golem deck with Rocket or Earthquake
✗ Hog Rider deck with avg elixir above 3.4
✗ Three Musketeers without Elixir Collector when avg cost exceeds 4.5
✗ Mortar deck without Rocket
✗ Zero air-hitting units in any deck
✗ PEKKA or Mega Knight as the primary win condition
✗ More than 1 Champion in the same deck
✗ More than 2 Evolution cards in the same deck
✗ A SEVERELY_UNDER card included without explicit justification
''';

  // ────────────────────────────────────────────────────────────────────────────
  // Prompt builders
  // ────────────────────────────────────────────────────────────────────────────

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
      if (team > opp) {
        wins++;
      } else if (team < opp) {
        losses++;
      } else {
        draws++;
      }
    }

    final currentDeckInfo = profile.currentDeck
        .map((c) {
          final typeTag = _cardTypeLabelForCard(c);
          final elixir = c.elixirCost != null
              ? ' (${c.elixirCost} elixir)'
              : '';
          final level = c.level != null ? ' Lv${c.level}' : '';
          return '${c.name}$typeTag$elixir$level';
        })
        .join(', ');

    final filteredCollection = _buildFilteredCollection(profile);

    final collectionForSwaps = profile.cards
        .where((c) => !profile.currentDeck.any((d) => d.id == c.id))
        .map((c) {
          final typeTag = _cardTypeLabelForCard(c);
          final levelNote =
              _levelGap(c.level ?? 1, profile.arenaName, profile.trophies) >= 0
                  ? ''
                  : ' (UNDER)';
          return '${c.name}$typeTag$levelNote';
        })
        .take(40)
        .join(', ');

    final arenaGuide = ArenaGuide.findByName(profile.arenaName);
    final arenaMeta = arenaGuide != null
        ? '\nArena meta: ${arenaGuide.aiContext}'
        : '';
    final enemyDecks = arenaGuide != null
        ? arenaGuide.commonDecks.take(5).join('\n• ')
        : 'Hog 2.6 Cycle, Golem Beatdown, LavaLoon, Bridge Spam, Miner Poison';

    final tournamentLevel =
        _arenaTournamentLevel[profile.arenaName] ??
        _tournamentLevelFromTrophies(profile.trophies);

    // Count available special cards for context
    final championsOwned = profile.cards
        .where((c) => _cardTypeLabelForCard(c) == '[CHAMPION]')
        .map((c) => '${c.name} Lv${c.level}')
        .join(', ');
    final evolutionsOwned = profile.cards
        .where((c) => _cardTypeLabelForCard(c) == '[EVOLUTION]')
        .map((c) => '${c.name} Lv${c.level}')
        .join(', ');

    return '''
You are a Clash Royale Grand Master coach focused on building the BEST POSSIBLE DECK for this player.
Your #1 priority is a deck that wins at ${profile.trophies} trophies against the most common enemies there.
Return a SINGLE JSON object with exactly two keys: "deck_analysis" and "strategy".

${_deckKnowledgeBase()}

=== PLAYER DATA ===
Player: ${profile.name} | Level: ${profile.expLevel ?? '?'} | Trophies: ${profile.trophies} | Arena: ${profile.arenaName}
Tournament standard level for this arena: $tournamentLevel
Record: ${profile.wins ?? '?'} wins / ${profile.losses ?? '?'} losses | Recent: $wins wins, $losses losses, $draws draws (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} battles)
Preferred style: ${preferredArchetype.toUpperCase()}$arenaMeta

=== SPECIAL CARDS OWNED ===
Champions [CHAMPION]: ${championsOwned.isEmpty ? 'none' : championsOwned}
Evolutions [EVOLUTION]: ${evolutionsOwned.isEmpty ? 'none' : evolutionsOwned}

=== CURRENT DECK ===
$currentDeckInfo

IMPORTANT — PLAYER COLLECTION CONTEXT: This player's best card is at level ${profile.cards.map((c) => c.level ?? 1).fold(1, (b, l) => l > b ? l : b)}. Build the deck from what they ACTUALLY HAVE — always pick higher-level cards over lower-level ones for each role.

=== USABLE CARDS — BUILD THE DECK FROM THESE (sorted: Champions → Evolutions → regulars by level desc) ===
level_note guide: BEST_IN_COLLECTION = player's top-tier cards (use these first) | GOOD = solid choices | USABLE = acceptable if no better option for that role
[${filteredCollection.primary}]

=== CARDS TOO FAR BELOW COLLECTION STANDARD (do NOT use) ===
${filteredCollection.upgradeable}

=== CARDS AVAILABLE FOR SWAP SUGGESTIONS (not in current deck) ===
$collectionForSwaps

=== MOST COMMON ENEMY DECKS AT ${profile.trophies} TROPHIES ===
• $enemyDecks

COUNTER-META MANDATE — your deck MUST satisfy all of these:
✓ At least 1 unit that hits AIR targets → defends Balloon and LavaLoon pushes
✓ At least 1 building OR heavy spell (Fireball / Poison / Lightning / Rocket) → counters Hog Rider, Giant, and tank pushes
✓ At least 1 splash unit or area spell → stops swarm decks (Goblin Barrel, Bridge Spam, Barbarians)
✓ Average elixir ≤ 3.8 for Cycle/Bait styles | ≤ 5.0 for Beatdown

=== DECK BUILDING STEPS (execute in order before writing the JSON) ===
1. Identify the META TEMPLATE for archetype ${preferredArchetype.toUpperCase()} from the knowledge base
2. From USABLE CARDS, pick the best Champion that fits the template (max 1)
3. From USABLE CARDS, pick up to 2 Evolutions that fill composition roles in the template
4. Fill remaining slots from USABLE CARDS matching roles (win condition, spells, air defense, support, buildings)
5. Verify COUNTER-META MANDATE — if violated, swap one card to fix it
6. Verify no FORBIDDEN COMBINATIONS violated
7. Assign confidence_score using the rules below

=== GRADE MAXIMIZATION RULES ===
To achieve Grade S: meta template used, all 8 slots filled with BEST_IN_COLLECTION cards, Champion + Evolutions included, counter-meta mandate met, zero FORBIDDEN violations.
To achieve Grade A: meta template intact with GOOD/BEST_IN_COLLECTION cards, counter-meta mandate met, no FORBIDDEN violations.
Grade B or below: only if the usable collection genuinely cannot support better.

=== RESPONSE JSON SCHEMA ===
{
  "deck_analysis": {
    "grade": "S",
    "grade_explanation": "1-2 sentences explaining exactly why this grade was assigned",
    "archetype": "Cycle",
    "avg_elixir": 3.1,
    "special_slots_used": {
      "champion": "Card name or null",
      "evolution_1": "Card name or null",
      "evolution_2": "Card name or null"
    },
    "how_to_play": ["Opening: ...", "Defense: ...", "Win condition: ...", "Double elixir: ...", "Common mistake: ..."],
    "strengths": ["strength 1", "strength 2"],
    "weaknesses": ["weakness 1", "weakness 2"],
    "suggested_swaps": [
      {"remove": "card name", "add": "card from available swaps list", "reason": "..."}
    ],
    "deck_notes": "Level warnings and special slot usage explanation (empty string if all cards are AT_META)",
    "overall_feedback": "2-3 sentence coach summary"
  },
  "strategy": {
    "playstyle_analysis": "2-3 sentences: which META DECK TEMPLATE was used, substitutions made, special cards included and why",
    "archetype_explanation": "2-3 sentences explaining the archetype gameplan to a beginner",
    "meta_coaching": "2-3 sentences about trophy-range threats and how special cards counter them",
    "suggested_deck": [{"id": <int>, "name": "<card name>"}],
    "deck_breakdown": {
      "win_condition": ["card names"],
      "spells": ["card names"],
      "air_defense": ["card names"],
      "support": ["card names"],
      "buildings": ["card names"],
      "champion": ["card name or empty"],
      "evolutions": ["card names or empty"]
    },
    "battle_guide": {
      "opening_move": "Primary first play + reactive plan if opponent plays first. Name specific card and position.",
      "elixir_management": "When to spend, when to save, minimum elixir before committing to a push.",
      "defense": "How to use specific cards in this deck to stop common threats at this trophy range.",
      "win_condition_execution": "Step-by-step push recipe: Step 1 → Step 2 → Step 3. Use exact card names.",
      "champion_usage": "How and when to activate the champion ability. Name the exact ability and trigger condition. Write 'No champion in this deck.' if none.",
      "evolution_usage": "When to cycle to trigger each evolution. Describe the enhanced behavior and best deployment timing. Write 'No evolutions in this deck.' if none.",
      "double_elixir_strategy": "How gameplay changes in double elixir. Which cards (including special) become key?",
      "common_mistakes": "Top 3 mistakes players make with this archetype and how to avoid them with this specific deck."
    },
    "matchup_tips": [{"enemy_archetype": "Beatdown", "tip": "..."}],
    "confidence_score": <float 0.0-1.0>
  }
}

STRICT RULES:
1. TARGET GRADE S. Only lower the grade if the usable collection genuinely prevents it.
2. suggested_deck: EXACTLY 8 cards, ALL from the USABLE CARDS list, with correct "id" values.
3. Champion: include the best BEST_IN_COLLECTION/GOOD Champion that fits the archetype. Max 1.
4. Evolutions: include up to 2 BEST_IN_COLLECTION/GOOD Evolutions filling composition roles. Max 2.
5. Level priority: ALWAYS pick the highest-level card for each role. BEST_IN_COLLECTION > GOOD > USABLE. Never use cards from "CARDS TOO FAR BELOW" list.
6. NEVER violate the FORBIDDEN COMBINATIONS list.
7. confidence_score — how well this deck serves the player at their trophy range:
   1.00 = perfect: all 8 cards BEST_IN_COLLECTION + recognized meta template + special slots filled + counter-meta mandate met
   0.85 = strong: mostly BEST_IN_COLLECTION/GOOD, meta template intact, special slots used
   0.70 = solid: mix of GOOD/USABLE, follows meta template, counter-meta met — MINIMUM for any functional deck
   0.55 = limited: forced USABLE-tier cards for core roles OR missing win condition with no substitute
   0.35 = compromised: counter-meta mandate violated OR no recognizable meta structure
   RULE: Any deck following a recognized meta template using the player's best available cards MUST score ≥ 0.70.
8. matchup_tips: at least 4 archetypes common at ${profile.trophies} trophies.
9. deck_notes: note any USABLE-tier cards chosen and why they were the best available option.
10. Response MUST be ONLY the JSON object — no markdown, no code blocks, no extra text.
11. LANGUAGE: All text values in $languageName. Keep all JSON keys in English.
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
      if (team > opp) {
        wins++;
      } else if (team < opp) {
        losses++;
      }
    }

    final currentDeckInfo = profile.currentDeck
        .map((c) {
          final typeTag = _cardTypeLabelForCard(c);
          final elixir = c.elixirCost != null
              ? ' (${c.elixirCost} elixir)'
              : '';
          final level = c.level != null ? ' Lv${c.level}' : '';
          final gap = _levelGap(c.level ?? 1, profile.arenaName, profile.trophies);
          final underLabel = gap < 0
              ? ' ⚠️ ${gap.abs()} levels under meta'
              : '';
          return '${c.name}$typeTag$elixir$level$underLabel';
        })
        .join(', ');

    final collectionForSwaps = profile.cards
        .where((c) => !profile.currentDeck.any((d) => d.id == c.id))
        .map((c) {
          final typeTag = _cardTypeLabelForCard(c);
          final gap = _levelGap(c.level ?? 1, profile.arenaName, profile.trophies);
          final levelNote = gap >= 0 ? '' : ' (-${gap.abs()}lvl)';
          return '${c.name}$typeTag Lv${c.level ?? 1}$levelNote';
        })
        .take(40)
        .join(', ');

    final tournamentLevel =
        _arenaTournamentLevel[profile.arenaName] ??
        _tournamentLevelFromTrophies(profile.trophies);

    return '''
You are an expert Clash Royale coach. Analyze the player's CURRENT deck exactly as-is.
TARGET: Suggest improvements to reach Grade S/A. Suggest 0-2 card swaps maximum.
Respond ONLY with valid JSON matching the schema below.

${_deckKnowledgeBase()}

=== PLAYER DATA ===
Player: ${profile.name} | Level: ${profile.expLevel ?? 'unknown'}
Arena: ${profile.arenaName} | Trophies: ${profile.trophies}
Tournament standard level for this arena: $tournamentLevel
Recent Record: $wins wins / $losses losses (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} battles)

=== CURRENT DECK (analyze this — card type and level gap vs tournament standard shown) ===
$currentDeckInfo

=== CARDS AVAILABLE FOR SWAP SUGGESTIONS ===
$collectionForSwaps

=== JSON SCHEMA ===
{
  "grade": "B",
  "grade_explanation": "1-2 sentences explaining exactly why this grade, and what would be needed to reach S/A",
  "archetype": "Cycle",
  "avg_elixir": 3.1,
  "special_slots_used": {
    "champion": "Card name or null",
    "evolution_1": "Card name or null",
    "evolution_2": "Card name or null"
  },
  "how_to_play": [
    "Opening: ...",
    "Defense: ...",
    "Win condition: ...",
    "Champion ability: how and when to use it (or 'No champion in deck')",
    "Evolution trigger: when to cycle to activate each evo (or 'No evolutions in deck')",
    "Double elixir: ...",
    "Common mistake: ..."
  ],
  "strengths": ["strength 1", "strength 2"],
  "weaknesses": ["weakness 1", "weakness 2"],
  "suggested_swaps": [
    {"remove": "card name", "add": "card from collection", "reason": "..."}
  ],
  "deck_notes": "Flag any SEVERELY_UNDER or UNDER cards in the deck. Note any missing special slot opportunity.",
  "overall_feedback": "2-3 sentence coach summary"
}

RULES:
- Grade scale: S (elite meta, AT_META cards, special slots used), A (strong, minor deviations), B (solid), C (average), D (needs work), F (poor)
- "how_to_play" must have 5-7 specific tips using exact card names from the current deck
- "suggested_swaps" max 2 entries; prioritize: (1) add a Champion/Evolution if one is available in the collection at AT_META/SLIGHTLY_UNDER, (2) swap an UNDER/SEVERELY_UNDER card for an AT_META one filling the same role
- avg_elixir: calculate from actual deck card costs
- Response must be ONLY the JSON — no markdown, no code blocks
- LANGUAGE: All text values in $languageName. Keep JSON keys in English.
''';
  }

  String _buildStructuredPrompt({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) {
    int wins = 0, losses = 0, draws = 0;
    for (var battle in battles.take(AppConstants.maxBattlesForAnalysis)) {
      final teamCrowns = battle.team.isNotEmpty ? battle.team.first.crowns : 0;
      final oppCrowns = battle.opponent.isNotEmpty
          ? battle.opponent.first.crowns
          : 0;
      if (teamCrowns > oppCrowns) {
        wins++;
      } else if (teamCrowns < oppCrowns) {
        losses++;
      } else {
        draws++;
      }
    }

    final filteredCollection = _buildFilteredCollection(profile);
    final currentDeckNames = profile.currentDeck
        .map((c) {
          final typeTag = _cardTypeLabelForCard(c);
          return '${c.name}$typeTag Lv${c.level ?? '?'}';
        })
        .join(', ');

    final arenaGuide = ArenaGuide.findByName(profile.arenaName);
    final arenaMeta = arenaGuide != null
        ? '\n=== ARENA META ===\n${arenaGuide.aiContext}'
        : '';
    final enemyDecks = arenaGuide != null
        ? arenaGuide.commonDecks.take(5).join('\n• ')
        : 'Hog 2.6 Cycle, Golem Beatdown, LavaLoon, Bridge Spam, Miner Poison';

    final tournamentLevel =
        _arenaTournamentLevel[profile.arenaName] ??
        _tournamentLevelFromTrophies(profile.trophies);

    final championsOwned = profile.cards
        .where((c) => _cardTypeLabelForCard(c) == '[CHAMPION]')
        .map(
          (c) =>
              '${c.name} Lv${c.level} (${_levelGap(c.level ?? 1, profile.arenaName, profile.trophies) >= 0 ? "AT_META" : "UNDER"})',
        )
        .join(', ');
    final evolutionsOwned = profile.cards
        .where((c) => _cardTypeLabelForCard(c) == '[EVOLUTION]')
        .map(
          (c) =>
              '${c.name} Lv${c.level} (${_levelGap(c.level ?? 1, profile.arenaName, profile.trophies) >= 0 ? "AT_META" : "UNDER"})',
        )
        .join(', ');

    return '''
You are a Clash Royale Grand Master and deck building expert.
Your PRIMARY GOAL is to build the STRONGEST POSSIBLE (Grade S) deck for this player
using their actual card collection, prioritizing meta templates, special slot cards, and level-appropriate cards.
Respond ONLY with a valid JSON object matching the schema.

${_deckKnowledgeBase()}

=== DECK BUILDING STEP-BY-STEP ===
1. Identify the META DECK TEMPLATE matching the preferred archetype: ${preferredArchetype.toUpperCase()}
2. CHECK SPECIAL SLOTS FIRST:
   a. Does the player own a Champion listed under that template's "Champions that fit" at AT_META/SLIGHTLY_UNDER? → Include it.
   b. Does the player own 1-2 Evolutions listed under that template's "Evolutions that fit" at AT_META/SLIGHTLY_UNDER? → Include up to 2.
   c. Special cards replace regular cards while improving or maintaining the composition role.
3. Fill remaining slots from the META DECK TEMPLATE, substituting missing cards from the collection using the SUBSTITUTION GUIDE.
4. Among substitution candidates, always pick the highest-level AT_META card.
5. Verify no FORBIDDEN COMBINATION is violated.
6. Record every substitution AND every special card choice in playstyle_analysis.

=== HOW TO WRITE BATTLE GUIDE ===
- Use EXACT card names from suggested_deck (including champion/evolution names)
- Give POSITIONAL guidance: "play Hog Rider at the river on the left lane"
- Explain TIMING: "only commit to a push when you have 8+ elixir"
- Explain REACTIONS: "if opponent drops Golem in the back, immediately split push opposite lane"
- champion_usage: exact trigger condition + activation timing + synergy with other deck cards
- evolution_usage: cycle count to trigger + what changes + best deployment position

=== PLAYER DATA ===
Player: ${profile.name}
Level: ${profile.expLevel ?? 'unknown'} | Trophies: ${profile.trophies}${profile.bestTrophies != null ? ' (best: ${profile.bestTrophies})' : ''}
Arena: ${profile.arenaName} | Tournament standard level: $tournamentLevel
Lifetime Record: ${profile.wins ?? '?'} wins / ${profile.losses ?? '?'} losses
Current Deck: $currentDeckNames
Recent Performance (last ${battles.take(AppConstants.maxBattlesForAnalysis).length} matches): $wins wins, $losses losses, $draws draws
Preferred Style: ${preferredArchetype.toUpperCase()}
$arenaMeta

=== SPECIAL CARDS OWNED ===
Champions [CHAMPION]: ${championsOwned.isEmpty ? 'none' : championsOwned}
Evolutions [EVOLUTION]: ${evolutionsOwned.isEmpty ? 'none' : evolutionsOwned}

=== MOST COMMON ENEMY DECKS AT ${profile.trophies} TROPHIES ===
• $enemyDecks

COUNTER-META MANDATE — your deck MUST satisfy all of these:
✓ At least 1 unit that hits AIR targets → defends Balloon and LavaLoon pushes
✓ At least 1 building OR heavy spell (Fireball / Poison / Lightning / Rocket) → counters Hog Rider and tank pushes
✓ At least 1 splash unit or area spell → stops swarm decks (Goblin Barrel, Bridge Spam)
✓ Average elixir ≤ 3.8 for Cycle/Bait | ≤ 5.0 for Beatdown

IMPORTANT — PLAYER COLLECTION CONTEXT: This player's best card is at level ${profile.cards.map((c) => c.level ?? 1).fold(1, (b, l) => l > b ? l : b)}. Build from what they actually have — always prefer higher-level cards for each role.

=== USABLE CARDS — BUILD DECK FROM THESE (sorted: Champions → Evolutions → regulars by level desc) ===
level_note guide: BEST_IN_COLLECTION = player's top-tier cards (prioritize these) | GOOD = solid | USABLE = acceptable if no better option
[${filteredCollection.primary}]

=== CARDS TOO FAR BELOW COLLECTION STANDARD (do NOT use) ===
${filteredCollection.upgradeable}

=== RESPONSE JSON SCHEMA ===
{
  "playstyle_analysis": "2-3 sentences: META DECK TEMPLATE used, substitutions made, special cards included (champion + evolutions) and why",
  "archetype_explanation": "2-3 sentences: archetype gameplan in plain language for a beginner",
  "meta_coaching": "2-3 sentences: trophy-range specific coaching, common threats, how special cards help",
  "suggested_deck": [{"id": <card_id_int>, "name": "<card_name>"}],
  "deck_breakdown": {
    "win_condition": ["card names"],
    "spells": ["card names"],
    "air_defense": ["card names"],
    "support": ["card names"],
    "buildings": ["card names"],
    "champion": ["card name or empty list"],
    "evolutions": ["card names or empty list"]
  },
  "special_slots": {
    "champion": "Card name or null",
    "evolution_1": "Card name or null",
    "evolution_2": "Card name or null"
  },
  "deck_notes": "Any UNDER/SEVERELY_UNDER cards included and the justification. Empty string if all cards are AT_META.",
  "battle_guide": {
    "opening_move": "Primary first play + reactive plan if opponent plays first. Name specific card and position.",
    "elixir_management": "When to spend, when to save, minimum elixir before committing to a push.",
    "defense": "How to use specific cards in this deck to stop common threats at this trophy range.",
    "win_condition_execution": "Step-by-step push recipe. Step 1 → Step 2 → Step 3. Use exact card names.",
    "champion_usage": "Exact ability name, trigger condition, timing, and synergy. Or: 'No champion in this deck.'",
    "evolution_usage": "For each evolution: cycle count to trigger, what changes, best deployment. Or: 'No evolutions in this deck.'",
    "double_elixir_strategy": "How gameplay changes in double elixir. Which regular and special cards become key?",
    "common_mistakes": "Top 3 mistakes for this archetype and how to avoid them with this specific deck."
  },
  "matchup_tips": [{"enemy_archetype": "Beatdown", "tip": "..."}],
  "confidence_score": <float 0.0-1.0>
}

STRICT RULES:
1. suggested_deck: EXACTLY 8 cards, ALL from USABLE CARDS list, correct "id" values.
2. TARGET GRADE S — use the best possible combination of meta cards + special cards.
3. Special slots: max 1 Champion, max 2 Evolutions. Prioritize BEST_IN_COLLECTION/GOOD ones listed under the archetype template.
4. Level selection: ALWAYS prefer higher-level cards. BEST_IN_COLLECTION > GOOD > USABLE. Never use "CARDS TOO FAR BELOW" list.
5. NEVER violate FORBIDDEN COMBINATIONS.
6. confidence_score — how well this deck serves the player at their trophy range:
   1.00 = perfect: all 8 BEST_IN_COLLECTION + meta template + special slots + counter-meta mandate met
   0.85 = strong: mostly BEST_IN_COLLECTION/GOOD, meta template intact, special slots used
   0.70 = solid: mix of GOOD/USABLE, follows meta template, counter-meta met — MINIMUM for any functional deck
   0.55 = limited: forced USABLE-tier for core roles OR missing win condition
   0.35 = compromised: counter-meta violated OR no recognizable meta structure
   RULE: Any deck using the player's best available cards in a meta template MUST score ≥ 0.70.
7. matchup_tips: at least 4 archetypes common at ${profile.trophies} trophies.
8. Response must be ONLY the JSON object — no markdown, no code blocks, no extra text.
9. LANGUAGE: All text values in $languageName. Keep all JSON keys in English.
''';
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Test-visible helpers (do not call from production code)
  // ────────────────────────────────────────────────────────────────────────────

  @visibleForTesting
  String cardTypeLabelForCard(CrCard c) => _cardTypeLabelForCard(c);

  @visibleForTesting
  int deltaFromMax(CrCard c) => _deltaFromMax(c);

  @visibleForTesting
  ({String primary, String upgradeable}) buildFilteredCollection(
    PlayerProfile profile,
  ) => _buildFilteredCollection(profile);

  // ────────────────────────────────────────────────────────────────────────────
  // Error classification helpers
  // ────────────────────────────────────────────────────────────────────────────

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
}

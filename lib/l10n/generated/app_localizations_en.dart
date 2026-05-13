// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ROYALE COACH';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get restartApp => 'Restart the application.';

  @override
  String get unofficialApp => 'UNOFFICIAL FAN APP';

  @override
  String get aiPoweredTagline => 'AI-POWERED STRATEGY & INSIGHTS';

  @override
  String get playerTagLabel => 'PLAYER TAG';

  @override
  String get playerTagHint => 'eg: L8P22UR2';

  @override
  String get analyzeButton => 'ANALYZE PROFILE';

  @override
  String get whereIsMyTag => 'Where is my Tag?';

  @override
  String get step1 => 'Open Clash Royale';

  @override
  String get step2 => 'Tap your Name (Top Left)';

  @override
  String get step3 => 'Copy the Tag under your Name';

  @override
  String get tagExample => 'Example: #L8P22UR2';

  @override
  String get disclaimerText =>
      'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy.';

  @override
  String get poweredByGemini => 'Powered by Gemini AI';

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get cacheTooltip => 'Cached data (offline)';

  @override
  String get offlineBadge => 'OFFLINE';

  @override
  String get aiInsightsTitle => 'AI STRATEGY INSIGHTS';

  @override
  String get analyzingText => 'Analyzing with Gemini AI...';

  @override
  String get chooseStrategy => 'Choose your battle strategy:';

  @override
  String get unlockAnalysis => 'Unlock expert analysis of your collection.';

  @override
  String get watchAdButton => 'WATCH AD TO UNLOCK';

  @override
  String get tabDeck => 'DECK';

  @override
  String get tabCards => 'CARDS';

  @override
  String get tabBattles => 'BATTLES';

  @override
  String get tabStats => 'STATS';

  @override
  String get trophiesLabel => 'TROPHIES';

  @override
  String get bestRecordLabel => 'BEST';

  @override
  String get levelLabel => 'LEVEL';

  @override
  String get yourDeck => 'YOUR DECK';

  @override
  String get opponentDeck => 'OPPONENT DECK';

  @override
  String get importButton => 'IMPORT IN CLASH ROYALE';

  @override
  String get victory => 'VICTORY';

  @override
  String get defeat => 'DEFEAT';

  @override
  String get draw => 'DRAW';

  @override
  String get noBattlesFound => 'No battles found';

  @override
  String get cardsNotFound => 'Cards not found';

  @override
  String get deckNotFound => 'Deck not found';

  @override
  String get noCards => 'No cards';

  @override
  String get commonDecks => 'MOST COMMON DECKS';

  @override
  String get arenaStrategies => 'ARENA STRATEGIES';

  @override
  String get winTips => 'WIN TIPS';

  @override
  String arenaGuideNotFound(String arena) {
    return 'Guide not found for $arena';
  }

  @override
  String get playstyleAnalysisTitle => 'PLAYSTYLE ANALYSIS';

  @override
  String get metaCoachingTitle => 'META COACHING';

  @override
  String get suggestedDeckTitle => 'SUGGESTED DECK';

  @override
  String get battleGuideTitle => 'BATTLE GUIDE';

  @override
  String get opening => '⚔️ Opening';

  @override
  String get defense => '🛡️ Defense';

  @override
  String get winConditionLabel => '🏆 Win Condition';

  @override
  String get importDeckButton => 'IMPORT DECK IN CLASH ROYALE';

  @override
  String get reAnalyze => 'RE-ANALYZE';

  @override
  String confidence(int pct) {
    return 'Confidence: $pct%';
  }

  @override
  String cardLevelInfo(String level, String maxLevel) {
    return 'Level $level / $maxLevel';
  }

  @override
  String get archetypeExplanationTitle => 'ARCHETYPE GUIDE';

  @override
  String get deckBreakdownTitle => 'DECK BREAKDOWN';

  @override
  String get roleWinCondition => 'Win Condition';

  @override
  String get roleSpells => 'Spells';

  @override
  String get roleAirDefense => 'Air Defense';

  @override
  String get roleSupport => 'Support';

  @override
  String get roleBuildings => 'Buildings';

  @override
  String get elixirManagementTitle => '⚡ Elixir';

  @override
  String get doubleElixirTitle => '⚡⚡ Double Elixir';

  @override
  String get commonMistakesTitle => '⚠️ Common Mistakes';

  @override
  String get matchupTipsTitle => 'MATCHUP GUIDE';

  @override
  String get vsLabel => 'vs';

  @override
  String get archetypeBeatdown => 'Beatdown';

  @override
  String get archetypeControl => 'Control';

  @override
  String get archetypeCycle => 'Cycle';

  @override
  String get archetypeSiege => 'Siege';

  @override
  String get archetypeBait => 'Bait';

  @override
  String get archetypeBridgeSpam => 'Bridge Spam';

  @override
  String get archetypeLavaLoon => 'LavaLoon';

  @override
  String get archetypeMinerPoison => 'Miner Poison';

  @override
  String get archetypeGraveyard => 'Graveyard';

  @override
  String get archetypeHybrid => 'Hybrid';

  @override
  String get archetypeBeatdownDesc =>
      'Slow pushes with powerful tanks. Build momentum and advance with overwhelming force.';

  @override
  String get archetypeControlDesc =>
      'Defend efficiently and exploit your opponent\'s mistakes with surgical counter-attacks.';

  @override
  String get archetypeCycleDesc =>
      'Cheap cards to cycle quickly. Repeat your win condition before the opponent can prepare.';

  @override
  String get archetypeSiegeDesc =>
      'Use buildings like X-Bow or Mortar to attack the tower without direct combat.';

  @override
  String get archetypeBaitDesc =>
      'Force the opponent to use the wrong spells, gaining advantage with cards they can\'t ignore.';

  @override
  String get archetypeBridgeSpamDesc =>
      'Constant immediate pressure at the bridge. Fast, aggressive decks that overwhelm before defenses are ready.';

  @override
  String get archetypeLavaLoonDesc =>
      'Lethal aerial combo: Lava Hound absorbs damage while the Balloon destroys towers.';

  @override
  String get archetypeMinerPoisonDesc =>
      'Constant chip damage with Miner and Poison. Accumulated damage wins by attrition.';

  @override
  String get archetypeGraveyardDesc =>
      'Summon skeletons directly on the enemy tower with the Graveyard spell to win through chip damage.';

  @override
  String get archetypeHybridDesc =>
      'Balanced mix of attack and defense, adaptable to various situations and opponents.';

  @override
  String get chooseArchetypeTitle => 'Choose deck type';

  @override
  String get deckChangedWarning => 'Deck changed since analysis';

  @override
  String get chooseArchetypeLabel => 'Choose your strategy:';

  @override
  String get currentArenaLabel => 'Current arena';

  @override
  String get openClashRoyale => 'OPEN CLASH ROYALE';

  @override
  String get tabAi => 'AI';

  @override
  String get elixirAverageLabel => 'avg elixir';

  @override
  String get howToPlayLabel => 'HOW TO PLAY';

  @override
  String get strengthsLabel => 'STRENGTHS';

  @override
  String get weaknessesLabel => 'WEAKNESSES';

  @override
  String get suggestedSwapLabel => 'SUGGESTED SWAP';

  @override
  String get shareDeckButton => 'Share Deck';

  @override
  String get currentDeckAnalysisTitle => 'CURRENT DECK ANALYSIS';

  @override
  String get copyLinkLabel => 'Copy link';

  @override
  String get reanalyzeWatchVideo => 'Re-analyze (watch video)';

  @override
  String analysisSavedAt(String date) {
    return 'Analysis saved on $date';
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ROYALE COACH'**
  String get appTitle;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @restartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart the application.'**
  String get restartApp;

  /// No description provided for @unofficialApp.
  ///
  /// In en, this message translates to:
  /// **'UNOFFICIAL FAN APP'**
  String get unofficialApp;

  /// No description provided for @aiPoweredTagline.
  ///
  /// In en, this message translates to:
  /// **'AI-POWERED STRATEGY & INSIGHTS'**
  String get aiPoweredTagline;

  /// No description provided for @playerTagLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAYER TAG'**
  String get playerTagLabel;

  /// No description provided for @playerTagHint.
  ///
  /// In en, this message translates to:
  /// **'eg: L8P22UR2'**
  String get playerTagHint;

  /// No description provided for @analyzeButton.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE PROFILE'**
  String get analyzeButton;

  /// No description provided for @whereIsMyTag.
  ///
  /// In en, this message translates to:
  /// **'Where is my Tag?'**
  String get whereIsMyTag;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'Open Clash Royale'**
  String get step1;

  /// No description provided for @step2.
  ///
  /// In en, this message translates to:
  /// **'Tap your Name (Top Left)'**
  String get step2;

  /// No description provided for @step3.
  ///
  /// In en, this message translates to:
  /// **'Copy the Tag under your Name'**
  String get step3;

  /// No description provided for @tagExample.
  ///
  /// In en, this message translates to:
  /// **'Example: #L8P22UR2'**
  String get tagExample;

  /// No description provided for @disclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy.'**
  String get disclaimerText;

  /// No description provided for @poweredByGemini.
  ///
  /// In en, this message translates to:
  /// **'Powered by Gemini AI'**
  String get poweredByGemini;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileTitle;

  /// No description provided for @cacheTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cached data (offline)'**
  String get cacheTooltip;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get offlineBadge;

  /// No description provided for @aiInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI STRATEGY INSIGHTS'**
  String get aiInsightsTitle;

  /// No description provided for @analyzingText.
  ///
  /// In en, this message translates to:
  /// **'Analyzing with Gemini AI...'**
  String get analyzingText;

  /// No description provided for @chooseStrategy.
  ///
  /// In en, this message translates to:
  /// **'Choose your battle strategy:'**
  String get chooseStrategy;

  /// No description provided for @unlockAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Unlock expert analysis of your collection.'**
  String get unlockAnalysis;

  /// No description provided for @watchAdButton.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD TO UNLOCK'**
  String get watchAdButton;

  /// No description provided for @tabDeck.
  ///
  /// In en, this message translates to:
  /// **'DECK'**
  String get tabDeck;

  /// No description provided for @tabCards.
  ///
  /// In en, this message translates to:
  /// **'CARDS'**
  String get tabCards;

  /// No description provided for @tabBattles.
  ///
  /// In en, this message translates to:
  /// **'BATTLES'**
  String get tabBattles;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'STATS'**
  String get tabStats;

  /// No description provided for @trophiesLabel.
  ///
  /// In en, this message translates to:
  /// **'TROPHIES'**
  String get trophiesLabel;

  /// No description provided for @bestRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get bestRecordLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get levelLabel;

  /// No description provided for @yourDeck.
  ///
  /// In en, this message translates to:
  /// **'YOUR DECK'**
  String get yourDeck;

  /// No description provided for @opponentDeck.
  ///
  /// In en, this message translates to:
  /// **'OPPONENT DECK'**
  String get opponentDeck;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'IMPORT IN CLASH ROYALE'**
  String get importButton;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'VICTORY'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'DEFEAT'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get draw;

  /// No description provided for @noBattlesFound.
  ///
  /// In en, this message translates to:
  /// **'No battles found'**
  String get noBattlesFound;

  /// No description provided for @cardsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cards not found'**
  String get cardsNotFound;

  /// No description provided for @deckNotFound.
  ///
  /// In en, this message translates to:
  /// **'Deck not found'**
  String get deckNotFound;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards'**
  String get noCards;

  /// No description provided for @commonDecks.
  ///
  /// In en, this message translates to:
  /// **'MOST COMMON DECKS'**
  String get commonDecks;

  /// No description provided for @arenaStrategies.
  ///
  /// In en, this message translates to:
  /// **'ARENA STRATEGIES'**
  String get arenaStrategies;

  /// No description provided for @winTips.
  ///
  /// In en, this message translates to:
  /// **'WIN TIPS'**
  String get winTips;

  /// No description provided for @arenaGuideNotFound.
  ///
  /// In en, this message translates to:
  /// **'Guide not found for {arena}'**
  String arenaGuideNotFound(String arena);

  /// No description provided for @playstyleAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'PLAYSTYLE ANALYSIS'**
  String get playstyleAnalysisTitle;

  /// No description provided for @metaCoachingTitle.
  ///
  /// In en, this message translates to:
  /// **'META COACHING'**
  String get metaCoachingTitle;

  /// No description provided for @suggestedDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED DECK'**
  String get suggestedDeckTitle;

  /// No description provided for @battleGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'BATTLE GUIDE'**
  String get battleGuideTitle;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'⚔️ Opening'**
  String get opening;

  /// No description provided for @defense.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Defense'**
  String get defense;

  /// No description provided for @winConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'🏆 Win Condition'**
  String get winConditionLabel;

  /// No description provided for @importDeckButton.
  ///
  /// In en, this message translates to:
  /// **'IMPORT DECK IN CLASH ROYALE'**
  String get importDeckButton;

  /// No description provided for @reAnalyze.
  ///
  /// In en, this message translates to:
  /// **'RE-ANALYZE'**
  String get reAnalyze;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {pct}%'**
  String confidence(int pct);

  /// No description provided for @cardLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Level {level} / {maxLevel}'**
  String cardLevelInfo(String level, String maxLevel);

  /// No description provided for @archetypeExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'ARCHETYPE GUIDE'**
  String get archetypeExplanationTitle;

  /// No description provided for @deckBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'DECK BREAKDOWN'**
  String get deckBreakdownTitle;

  /// No description provided for @roleWinCondition.
  ///
  /// In en, this message translates to:
  /// **'Win Condition'**
  String get roleWinCondition;

  /// No description provided for @roleSpells.
  ///
  /// In en, this message translates to:
  /// **'Spells'**
  String get roleSpells;

  /// No description provided for @roleAirDefense.
  ///
  /// In en, this message translates to:
  /// **'Air Defense'**
  String get roleAirDefense;

  /// No description provided for @roleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get roleSupport;

  /// No description provided for @roleBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get roleBuildings;

  /// No description provided for @elixirManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡ Elixir'**
  String get elixirManagementTitle;

  /// No description provided for @doubleElixirTitle.
  ///
  /// In en, this message translates to:
  /// **'⚡⚡ Double Elixir'**
  String get doubleElixirTitle;

  /// No description provided for @commonMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Common Mistakes'**
  String get commonMistakesTitle;

  /// No description provided for @matchupTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'MATCHUP GUIDE'**
  String get matchupTipsTitle;

  /// No description provided for @vsLabel.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get vsLabel;

  /// No description provided for @archetypeBeatdown.
  ///
  /// In en, this message translates to:
  /// **'Beatdown'**
  String get archetypeBeatdown;

  /// No description provided for @archetypeControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get archetypeControl;

  /// No description provided for @archetypeCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get archetypeCycle;

  /// No description provided for @archetypeSiege.
  ///
  /// In en, this message translates to:
  /// **'Siege'**
  String get archetypeSiege;

  /// No description provided for @archetypeBait.
  ///
  /// In en, this message translates to:
  /// **'Bait'**
  String get archetypeBait;

  /// No description provided for @archetypeBridgeSpam.
  ///
  /// In en, this message translates to:
  /// **'Bridge Spam'**
  String get archetypeBridgeSpam;

  /// No description provided for @archetypeLavaLoon.
  ///
  /// In en, this message translates to:
  /// **'LavaLoon'**
  String get archetypeLavaLoon;

  /// No description provided for @archetypeMinerPoison.
  ///
  /// In en, this message translates to:
  /// **'Miner Poison'**
  String get archetypeMinerPoison;

  /// No description provided for @archetypeGraveyard.
  ///
  /// In en, this message translates to:
  /// **'Graveyard'**
  String get archetypeGraveyard;

  /// No description provided for @archetypeHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get archetypeHybrid;

  /// No description provided for @archetypeBeatdownDesc.
  ///
  /// In en, this message translates to:
  /// **'Slow pushes with powerful tanks. Build momentum and advance with overwhelming force.'**
  String get archetypeBeatdownDesc;

  /// No description provided for @archetypeControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Defend efficiently and exploit your opponent\'s mistakes with surgical counter-attacks.'**
  String get archetypeControlDesc;

  /// No description provided for @archetypeCycleDesc.
  ///
  /// In en, this message translates to:
  /// **'Cheap cards to cycle quickly. Repeat your win condition before the opponent can prepare.'**
  String get archetypeCycleDesc;

  /// No description provided for @archetypeSiegeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use buildings like X-Bow or Mortar to attack the tower without direct combat.'**
  String get archetypeSiegeDesc;

  /// No description provided for @archetypeBaitDesc.
  ///
  /// In en, this message translates to:
  /// **'Force the opponent to use the wrong spells, gaining advantage with cards they can\'t ignore.'**
  String get archetypeBaitDesc;

  /// No description provided for @archetypeBridgeSpamDesc.
  ///
  /// In en, this message translates to:
  /// **'Constant immediate pressure at the bridge. Fast, aggressive decks that overwhelm before defenses are ready.'**
  String get archetypeBridgeSpamDesc;

  /// No description provided for @archetypeLavaLoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Lethal aerial combo: Lava Hound absorbs damage while the Balloon destroys towers.'**
  String get archetypeLavaLoonDesc;

  /// No description provided for @archetypeMinerPoisonDesc.
  ///
  /// In en, this message translates to:
  /// **'Constant chip damage with Miner and Poison. Accumulated damage wins by attrition.'**
  String get archetypeMinerPoisonDesc;

  /// No description provided for @archetypeGraveyardDesc.
  ///
  /// In en, this message translates to:
  /// **'Summon skeletons directly on the enemy tower with the Graveyard spell to win through chip damage.'**
  String get archetypeGraveyardDesc;

  /// No description provided for @archetypeHybridDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced mix of attack and defense, adaptable to various situations and opponents.'**
  String get archetypeHybridDesc;

  /// No description provided for @chooseArchetypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose deck type'**
  String get chooseArchetypeTitle;

  /// No description provided for @deckChangedWarning.
  ///
  /// In en, this message translates to:
  /// **'Deck changed since analysis'**
  String get deckChangedWarning;

  /// No description provided for @chooseArchetypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose your strategy:'**
  String get chooseArchetypeLabel;

  /// No description provided for @currentArenaLabel.
  ///
  /// In en, this message translates to:
  /// **'Current arena'**
  String get currentArenaLabel;

  /// No description provided for @openClashRoyale.
  ///
  /// In en, this message translates to:
  /// **'OPEN CLASH ROYALE'**
  String get openClashRoyale;

  /// No description provided for @tabAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get tabAi;

  /// No description provided for @elixirAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'avg elixir'**
  String get elixirAverageLabel;

  /// No description provided for @howToPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlayLabel;

  /// No description provided for @strengthsLabel.
  ///
  /// In en, this message translates to:
  /// **'STRENGTHS'**
  String get strengthsLabel;

  /// No description provided for @weaknessesLabel.
  ///
  /// In en, this message translates to:
  /// **'WEAKNESSES'**
  String get weaknessesLabel;

  /// No description provided for @suggestedSwapLabel.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED SWAP'**
  String get suggestedSwapLabel;

  /// No description provided for @shareDeckButton.
  ///
  /// In en, this message translates to:
  /// **'Share Deck'**
  String get shareDeckButton;

  /// No description provided for @currentDeckAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'CURRENT DECK ANALYSIS'**
  String get currentDeckAnalysisTitle;

  /// No description provided for @copyLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkLabel;

  /// No description provided for @reanalyzeWatchVideo.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze (watch video)'**
  String get reanalyzeWatchVideo;

  /// No description provided for @analysisSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Analysis saved on {date}'**
  String analysisSavedAt(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'package:cr_ai_deck_builder/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/arena_assets.dart';
import '../../core/data/arena_guide.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/entities/deck_analysis_report.dart';
import '../../domain/entities/player.dart';
import '../../services/ad_service.dart';
import '../blocs/ai_strategy/ai_strategy_cubit.dart';
import '../blocs/ai_strategy/ai_strategy_state.dart';
import '../blocs/ai_strategy/saved_strategies_cubit.dart';
import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/battle_stats_dashboard.dart';
import '../widgets/card_guide_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_display_widget.dart';
import '../widgets/grade_badge.dart';
import '../widgets/offline_banner_widget.dart';
import '../widgets/skeleton_widgets.dart';
import '../widgets/streak_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/meta_cards.dart';
import 'how_to_play_screen.dart';
import 'search_screen.dart';

enum _SortBy { level, rarity, elixir }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedArchetype = 'Beatdown';
  int _currentIndex = 0;
  bool _profileSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerState = context.read<PlayerCubit>().state;
      final aiState = context.read<AiStrategyCubit>().state;
      if (playerState is PlayerLoaded) {
        context.read<SavedStrategiesCubit>().fetchSavedStrategies(playerState.profile.tag);
        final deckIds = playerState.profile.currentDeck.map((c) => c.id).toList();
        if (aiState is AiStrategyInitial) {
          // No analysis loaded yet — load from cache, auto-clearing if deck changed.
          context.read<AiStrategyCubit>().loadSavedAnalysis(
            playerState.profile.tag,
            currentDeckIds: deckIds,
          );
        } else if (aiState is FullAnalysisLoaded) {
          // Already loaded from splash — validate it matches the current deck.
          context.read<AiStrategyCubit>().validateDeckConsistency(
            playerState.profile.tag,
            deckIds,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (playerState is PlayerLoading || playerState is PlayerInitial) {
          return const ProfileSkeletonScreen();
        }

        if (playerState is PlayerError) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: ErrorDisplayWidget(
              failure: playerState.failure,
              onRetry: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
          );
        }

        if (playerState is! PlayerLoaded) {
          return const ProfileSkeletonScreen();
        }

        final profile = playerState.profile;
        final battleLog = playerState.battles;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: GestureDetector(
              onTap: () => _showProfileSheet(context, profile),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _profileSheetOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    context.read<PlayerCubit>().fetchPlayer(profile.tag),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Column(
                children: [
                  if (playerState.isFromCache)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: OfflineBannerWidget(isOffline: true),
                    ),
                  if (battleLog.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: StreakWidget(battles: battleLog),
                    ),
                  Expanded(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          _buildAnalysisTab(context, profile, battleLog),
                          _buildDeck8Grid(
                            context,
                            profile.currentDeck,
                            profile: profile,
                            battleLog: battleLog,
                          ),
                          _CardGridTab(cards: profile.cards, emptyMessage: l10n.cardsNotFound),
                          _buildHistoryTab(context, battleLog),
                          _buildStatsTab(context, profile, battleLog),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.borderMedium, width: 0.5),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) => setState(() => _currentIndex = i),
                  backgroundColor: AppColors.surface,
                  indicatorColor: AppColors.primary.withValues(alpha: 0.15),
                  height: 65,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(icon: const Icon(Icons.auto_awesome), label: AppLocalizations.of(context)!.tabAi),
                    NavigationDestination(icon: const Icon(Icons.style), label: AppLocalizations.of(context)!.tabDeck),
                    NavigationDestination(icon: const Icon(Icons.grid_view), label: AppLocalizations.of(context)!.tabCards),
                    NavigationDestination(icon: const Icon(Icons.history), label: AppLocalizations.of(context)!.tabBattles),
                    NavigationDestination(icon: const Icon(Icons.bar_chart), label: AppLocalizations.of(context)!.tabStats),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: const BannerAdWidget(adUnitId: 'ca-app-pub-8273819403150038/5940370812'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialAnalysisUI(
    BuildContext context,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.chooseArchetypeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.unlockAnalysis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showArchetypeSelector(context, profile, battleLog),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.style),
            label: Text(
              l10n.chooseArchetypeTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckAnalysisResult(
    BuildContext context,
    DeckAnalysisReport report,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GradeRevealWidget(grade: report.grade, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.archetype.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.gradeExplanation,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/ui_icons/elixir.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      report.avgElixir.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.accent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(l10n.elixirAverageLabel, style: const TextStyle(color: AppColors.textDisabled, fontSize: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.howToPlayLabel,
          style: const TextStyle(
            color: AppColors.successAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ...report.howToPlay.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.successAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: AppColors.successAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAnalysisSection(
                l10n.strengthsLabel,
                report.strengths,
                AppColors.successAccent,
                Icons.thumb_up,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAnalysisSection(
                l10n.weaknessesLabel,
                report.weaknesses,
                AppColors.errorAccent,
                Icons.thumb_down,
              ),
            ),
          ],
        ),
        if (report.suggestedSwaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.suggestedSwapLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...report.suggestedSwaps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_circle,
                    color: AppColors.errorAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.remove,
                    style: const TextStyle(
                      color: AppColors.errorAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      color: AppColors.textDisabled,
                      size: 14,
                    ),
                  ),
                  const Icon(
                    Icons.add_circle,
                    color: AppColors.successAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.add,
                      style: const TextStyle(
                        color: AppColors.successAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          report.overallFeedback,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _triggerFullAnalysis(context, profile, battleLog),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(
            l10n.reAnalyze,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _triggerFullAnalysis(
    BuildContext context,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    final adService = GetIt.instance<AdService>();
    final aiCubit = context.read<AiStrategyCubit>();
    final languageName = _localeToLanguageName(Localizations.localeOf(context));

    void run() => aiCubit.runFullAnalysis(
      profile: profile,
      battles: battleLog,
      preferredArchetype: _selectedArchetype,
      languageName: languageName,
    );

    if (kIsWeb) {
      run();
    } else {
      adService.showRewardedAd(onUserEarnedReward: run);
    }
  }

  String _localeToLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'pt':
        return 'Brazilian Portuguese';
      case 'es':
        return 'Spanish';
      default:
        return 'English';
    }
  }

  void _showArchetypeSelector(
    BuildContext context,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // (key for AI prompt, display name, description, icon, color)
    final archetypes = [
      ('Beatdown',     l10n.archetypeBeatdown,     l10n.archetypeBeatdownDesc,     Icons.bolt,             const Color(0xFFFF6B35)),
      ('Control',      l10n.archetypeControl,       l10n.archetypeControlDesc,      Icons.shield,           const Color(0xFF4A90D9)),
      ('Cycle',        l10n.archetypeCycle,         l10n.archetypeCycleDesc,        Icons.loop,             const Color(0xFF27AE60)),
      ('Siege',        l10n.archetypeSiege,         l10n.archetypeSiegeDesc,        Icons.castle,           const Color(0xFF8B6914)),
      ('Bait',         l10n.archetypeBait,          l10n.archetypeBaitDesc,         Icons.pest_control,     const Color(0xFFE1C40B)),
      ('Bridge Spam',  l10n.archetypeBridgeSpam,    l10n.archetypeBridgeSpamDesc,   Icons.directions_run,   const Color(0xFFE67E22)),
      ('LavaLoon',     l10n.archetypeLavaLoon,      l10n.archetypeLavaLoonDesc,     Icons.local_fire_department, const Color(0xFFE74C3C)),
      ('Miner Poison', l10n.archetypeMinerPoison,   l10n.archetypeMinerPoisonDesc,  Icons.science,          const Color(0xFF8E44AD)),
      ('Graveyard',    l10n.archetypeGraveyard,     l10n.archetypeGraveyardDesc,    Icons.nights_stay,      const Color(0xFF6C3483)),
      ('Hybrid',       l10n.archetypeHybrid,        l10n.archetypeHybridDesc,       Icons.balance,          const Color(0xFF7F8C8D)),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  l10n.chooseArchetypeTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: archetypes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final (key, name, desc, icon, color) = archetypes[i];
                    final isSelected = _selectedArchetype == key;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        desc,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18)
                          : null,
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        setState(() => _selectedArchetype = key);
                        _triggerFullAnalysis(context, profile, battleLog);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProfileSheet(BuildContext context, PlayerProfile profile) async {
    setState(() => _profileSheetOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildArenaButton(context, profile),
              const SizedBox(height: 16),
              Text(
                profile.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.tag,
                style: const TextStyle(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Divider(height: 32, color: AppColors.borderStrong),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    l10n.trophiesLabel,
                    profile.trophies.toString(),
                    Icons.emoji_events,
                    AppColors.primary,
                  ),
                  _buildStatDivider(),
                  if (profile.bestTrophies != null) ...[
                    _buildStatItem(
                      l10n.bestRecordLabel,
                      profile.bestTrophies.toString(),
                      Icons.military_tech,
                      AppColors.warning,
                    ),
                    _buildStatDivider(),
                  ],
                  if (profile.expLevel != null)
                    _buildStatItem(
                      l10n.levelLabel,
                      profile.expLevel.toString(),
                      Icons.star,
                      AppColors.primary,
                    ),
                  if (profile.wins != null) ...[
                    _buildStatDivider(),
                    _buildStatItem(l10n.victory, profile.wins.toString(), Icons.check_circle_outline, AppColors.battleVictory),
                  ],
                  if (profile.losses != null) ...[
                    _buildStatDivider(),
                    _buildStatItem(l10n.defeat, profile.losses.toString(), Icons.cancel_outlined, AppColors.battleDefeat),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
    if (mounted) setState(() => _profileSheetOpen = false);
  }

  Widget _buildArenaButton(BuildContext context, PlayerProfile profile) {
    return _AnimatedArenaButton(
      profile: profile,
      onTap: () => _showArenaGuide(context, profile.arenaName),
    );
  }

  void _showDeckPopup(
    BuildContext context,
    String deckName, {
    String? deckUrl,
    List<String>? metaDeckCardNames,
    Map<String, CrCard>? cardByName,
  }) {
    final hasRealDeck = deckUrl != null && deckUrl.isNotEmpty;
    final cards = metaDeckCardNames ?? [];
    final ownedSet = cardByName?.keys.toSet() ?? {};

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.card, AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, color: AppColors.primary, size: 32),
              const SizedBox(height: 10),
              Text(
                deckName,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              if (!hasRealDeck) ...[
                const SizedBox(height: 4),
                Text(
                  'Cartas que você está faltando',
                  style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
              if (cards.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: cards.map((name) {
                    final owned = ownedSet.contains(name.toLowerCase());
                    final card = cardByName?[name.toLowerCase()];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: owned
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: owned
                              ? AppColors.successAccent.withValues(alpha: 0.5)
                              : AppColors.errorAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (card?.iconUrl != null && card!.iconUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Image.network(
                                card.iconUrl,
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          Text(
                            name,
                            style: TextStyle(
                              color: owned ? AppColors.successAccent : AppColors.errorAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            owned ? Icons.check_circle_outline : Icons.cancel_outlined,
                            size: 12,
                            color: owned ? AppColors.successAccent : AppColors.errorAccent,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              if (hasRealDeck) ...[
                _Push3DButton(
                  label: 'Abrir no Clash Royale',
                  icon: Icons.open_in_new_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: deckUrl));
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    final uri = Uri.parse(deckUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clash Royale não encontrado.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 12, color: AppColors.textDisabled),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'No CR: toque em "Copiar para Baralho"',
                        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Consiga as cartas marcadas em vermelho para importar este deck.',
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar', style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolves a list of card names against the player's collection and builds
  /// a valid deck deep-link. Returns null if fewer than 8 cards matched.
  String? _resolveDeckUrl(List<String>? cardNames, Map<String, CrCard> cardByName) {
    if (cardNames == null || cardNames.isEmpty) return null;
    final resolved = cardNames
        .map((n) => cardByName[n.toLowerCase()])
        .whereType<CrCard>()
        .toList();
    if (resolved.length != 8) return null;
    return AppConstants.buildDeckUrl(resolved.map((c) => c.id).toList());
  }

  void _showArenaGuide(BuildContext context, String arenaName) {
    final guide = ArenaGuide.findByName(arenaName);
    if (guide == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.arenaGuideNotFound(arenaName))),
      );
      return;
    }

    // Resolve meta deck card names against the player's collection to build URLs.
    final playerState = context.read<PlayerCubit>().state;
    final cardByName = playerState is PlayerLoaded
        ? {for (final c in playerState.profile.cards) c.name.toLowerCase(): c}
        : <String, CrCard>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.castle, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ArenaAssets.localizedName(
                              guide.arenaName,
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            guide.trophyRange,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      guide.overview,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGuideSection(
                      icon: Icons.style,
                      title: AppLocalizations.of(context)!.commonDecks,
                      color: AppColors.primary,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: guide.commonDecks
                            .asMap()
                            .entries
                            .map(
                              (e) => GestureDetector(
                                onTap: () {
                                  final metaCards = ArenaGuide.cardsForDeck(e.value);
                                  _showDeckPopup(
                                    context,
                                    e.value,
                                    deckUrl: _resolveDeckUrl(metaCards, cardByName),
                                    metaDeckCardNames: metaCards,
                                    cardByName: cardByName,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        e.value,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGuideSection(
                      icon: Icons.psychology,
                      title: AppLocalizations.of(context)!.arenaStrategies,
                      color: AppColors.accent,
                      child: Column(
                        children: guide.strategies
                            .asMap()
                            .entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(
                                        right: 10,
                                        top: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGuideSection(
                      icon: Icons.emoji_events,
                      title: AppLocalizations.of(context)!.winTips,
                      color: AppColors.successAccent,
                      child: Column(
                        children: guide.winTips
                            .map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.successAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderMedium,
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDeck8Grid(
    BuildContext context,
    List<CrCard> cards, {
    required PlayerProfile profile,
    required List<CrBattle> battleLog,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (cards.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.deckNotFound,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final deckUrl =
        AppConstants.buildDeckUrl(cards.map((c) => c.id).toList());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current deck grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return GestureDetector(
                onTap: () => CardGuideSheet.show(context, card),
                child: _buildCardTile(card),
              );
            },
          ),
          const SizedBox(height: 10),
          // Share button
          ElevatedButton.icon(
            onPressed: () =>
                SharePlus.instance.share(ShareParams(text: deckUrl)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              l10n.shareDeckButton,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Deck analysis — shown when analysis is available
          BlocBuilder<AiStrategyCubit, AiStrategyState>(
            builder: (context, state) {
              DeckAnalysisReport? deckReport;
              if (state is FullAnalysisLoaded) deckReport = state.report.deckAnalysis;
              if (state is DeckAnalysisLoaded) deckReport = state.report;
              if (deckReport == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          l10n.currentDeckAnalysisTitle,
                          style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDeckAnalysisResult(context, deckReport, profile, battleLog),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(
    BuildContext context,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BattleStatsDashboard(profile: profile, battles: battleLog),
          // Playstyle analysis from AI — shown when analysis is available
          BlocBuilder<AiStrategyCubit, AiStrategyState>(
            builder: (context, state) {
              AiStrategyReport? stratReport;
              if (state is FullAnalysisLoaded) stratReport = state.report.strategy;
              if (state is AiStrategyLoaded) stratReport = state.report;
              if (stratReport == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    icon: Icons.psychology,
                    title: AppLocalizations.of(context)!.playstyleAnalysisTitle,
                    content: stratReport.playstyleAnalysis,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoSection(
                    icon: Icons.school,
                    title: AppLocalizations.of(context)!.metaCoachingTitle,
                    content: stratReport.metaCoaching,
                    color: AppColors.accent,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Shared info section widget (used in stats tab + analysis tab) ─────────
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }

  // ── IA / Analysis tab ─────────────────────────────────────────────
  Widget _buildAnalysisTab(
    BuildContext context,
    PlayerProfile profile,
    List<CrBattle> battleLog,
  ) {
    return BlocBuilder<AiStrategyCubit, AiStrategyState>(
      builder: (context, state) {
        return switch (state) {
          FullAnalysisLoading() ||
          AiStrategyLoading() ||
          DeckAnalysisLoading() =>
            const AiAnalysisSkeletonWidget(),
          FullAnalysisLoaded(:final report, :final savedAt, :final isFromCache) =>
            _buildAnalysisContent(
              context, report.strategy, profile, battleLog,
              savedAt: savedAt, isFromCache: isFromCache,
              analyzedDeckIds: report.analyzedDeckIds,
            ),
          AiStrategyLoaded(:final report) =>
            _buildAnalysisContent(context, report, profile, battleLog),
          AiStrategyError(:final failure) =>
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ErrorDisplayWidget(failure: failure),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AiStrategyCubit>().reset(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.borderStrong),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          _ => _buildInitialAnalysisUI(context, profile, battleLog),
        };
      },
    );
  }

  Widget _buildAnalysisContent(
    BuildContext context,
    AiStrategyReport report,
    PlayerProfile profile,
    List<CrBattle> battleLog, {
    DateTime? savedAt,
    bool isFromCache = false,
    List<int> analyzedDeckIds = const [],
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cardById = {for (final c in profile.cards) c.id: c};
    final cardByName = {for (final c in profile.cards) c.name.toLowerCase(): c};

    // Resolve each card by ID first, then by name — the AI often returns
    // hallucinated IDs while card names are reliable.
    final resolvedCards = List.generate(report.suggestedDeckIds.length, (i) {
      final id = report.suggestedDeckIds[i];
      final name = i < report.suggestedDeckNames.length
          ? report.suggestedDeckNames[i]
          : '';
      return cardById[id] ?? cardByName[name.toLowerCase()];
    }).whereType<CrCard>().toList();

    final elixirCards = resolvedCards.where((c) => c.elixirCost != null).toList();
    final avgElixir = elixirCards.isEmpty
        ? null
        : elixirCards.map((c) => c.elixirCost!).reduce((a, b) => a + b) /
            elixirCards.length;

    // Build deck URL from verified player-collection IDs, not AI-returned ones.
    final resolvedDeckUrl = resolvedCards.length == 8
        ? AppConstants.buildDeckUrl(resolvedCards.map((c) => c.id).toList())
        : report.deckLinkUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Saved analysis banner ──────────────────────────────
          if (isFromCache && savedAt != null) ...[
            _buildCacheBanner(context, savedAt, profile, analyzedDeckIds),
            const SizedBox(height: 10),
          ],
          // ── Suggested deck hero ────────────────────────────────
          _buildSuggestedDeckHero(context, report, cardById, cardByName, avgElixir, resolvedDeckUrl),
          const SizedBox(height: 14),

          // ── Deck breakdown ─────────────────────────────────────
          if (report.deckBreakdown != null) ...[
            _buildDeckBreakdownCard(context, report.deckBreakdown!),
            const SizedBox(height: 14),
          ],

          // ── Archetype explanation ──────────────────────────────
          if (report.archetypeExplanation?.isNotEmpty == true) ...[
            _buildInfoSection(
              icon: Icons.lightbulb_outline,
              title: 'SOBRE ESTE ESTILO',
              content: report.archetypeExplanation!,
              color: AppColors.successAccent,
            ),
            const SizedBox(height: 14),
          ],

          // ── How to play CTA ────────────────────────────────────
          _buildHowToPlayCta(context, report),
          const SizedBox(height: 14),

          // ── Matchup tips ───────────────────────────────────────
          if (report.matchupTips?.isNotEmpty == true) ...[
            _buildMatchupTipsCard(context, report.matchupTips!),
            const SizedBox(height: 14),
          ],

          // ── Confidence ─────────────────────────────────────────
          _buildConfidenceCard(report),
          const SizedBox(height: 14),

          // ── Re-analyze ─────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _showArchetypeSelector(context, profile, battleLog),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.borderStrong),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.ondemand_video, size: 16),
            label: Text(l10n.reanalyzeWatchVideo, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppLocalizations.of(context)!.disclaimerText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 8,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheBanner(
    BuildContext context,
    DateTime savedAt,
    PlayerProfile profile,
    List<int> analyzedDeckIds,
  ) {
    final day = savedAt.day.toString().padLeft(2, '0');
    final month = savedAt.month.toString().padLeft(2, '0');
    final hour = savedAt.hour.toString().padLeft(2, '0');
    final min = savedAt.minute.toString().padLeft(2, '0');
    final label = '$day/$month às $hour:$min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.analysisSavedAt(label),
              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<AiStrategyCubit>().clearSavedAnalysis(profile.tag),
            child: const Icon(Icons.delete_outline, color: AppColors.accent, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedDeckHero(
    BuildContext context,
    AiStrategyReport report,
    Map<int, CrCard> cardById,
    Map<String, CrCard> cardByName,
    double? avgElixir,
    String resolvedDeckUrl,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.cardElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.style, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.suggestedDeckTitle,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                  ),
                ),
                if (avgElixir != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/ui_icons/elixir.png', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text(
                        avgElixir.toStringAsFixed(1),
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 4×2 card grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: report.suggestedDeckIds.length,
              itemBuilder: (context, index) {
                final id = report.suggestedDeckIds[index];
                final name = index < report.suggestedDeckNames.length
                    ? report.suggestedDeckNames[index]
                    : 'Unknown';
                final card = cardById[id] ?? cardByName[name.toLowerCase()];
                return _buildSuggestedTile(context, card, name);
              },
            ),
          ),
          const SizedBox(height: 14),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: resolvedDeckUrl.isNotEmpty
                        ? () async {
                            await Clipboard.setData(ClipboardData(text: resolvedDeckUrl));
                            if (!context.mounted) return;
                            final url = Uri.parse(resolvedDeckUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: Text(l10n.openClashRoyale, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: resolvedDeckUrl.isNotEmpty
                      ? () {
                          Clipboard.setData(ClipboardData(text: resolvedDeckUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copiado!'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy, size: 15),
                  label: Text(l10n.copyLinkLabel, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          if (resolvedDeckUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 11, color: AppColors.borderStrong),
                  const SizedBox(width: 4),
                  const Flexible(
                    child: Text(
                      'No CR: "Copiar para Baralho" na prévia do deck',
                      style: TextStyle(color: AppColors.borderStrong, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTile(BuildContext context, CrCard? card, String name) {
    final rarityTxtClr = _rarityTextColorFn(card?.rarity);
    return GestureDetector(
      onTap: () => CardGuideSheet.show(context, card ?? CrCard(id: 0, name: name, iconUrl: '')),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (card != null)
              SizedBox.expand(
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.network(
                    card.iconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.textDisabled, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black38,
                child: Center(
                  child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppColors.textDisabled, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            if (card?.elixirCost != null)
              Positioned(top: 4, left: 0, child: _buildElixirDrop(card!.elixirCost)),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                'Lv ${card?.level ?? '?'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: rarityTxtClr,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                    Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, -1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckBreakdownCard(BuildContext context, DeckBreakdown bd) {
    final l10n = AppLocalizations.of(context)!;
    final roles = <_RoleEntry>[];
    if (bd.winCondition?.isNotEmpty == true) roles.add(_RoleEntry(l10n.roleWinCondition, bd.winCondition!, AppColors.primary));
    if (bd.spells?.isNotEmpty == true) roles.add(_RoleEntry(l10n.roleSpells, bd.spells!, AppColors.accent));
    if (bd.airDefense?.isNotEmpty == true) roles.add(_RoleEntry(l10n.roleAirDefense, bd.airDefense!, AppColors.successAccent));
    if (bd.support?.isNotEmpty == true) roles.add(_RoleEntry(l10n.roleSupport, bd.support!, AppColors.accent));
    if (bd.buildings?.isNotEmpty == true) roles.add(_RoleEntry(l10n.roleBuildings, bd.buildings!, AppColors.warning));
    if (roles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(l10n.deckBreakdownTitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          ...roles.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, right: 8),
                      decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(r.role, style: TextStyle(color: r.color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                    Expanded(
                      child: Text(r.cards.join(', '), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHowToPlayCta(BuildContext context, AiStrategyReport report) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HowToPlayScreen(guide: report.battleGuide, archetype: report.archetypeExplanation ?? 'Clash Royale'),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.successAccent.withValues(alpha: 0.2), Colors.teal.withValues(alpha: 0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.successAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.military_tech, color: AppColors.successAccent, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.howToPlayLabel, style: const TextStyle(color: AppColors.successAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text('Abertura, defesa, condição de vitória e mais', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.successAccent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchupTipsCard(BuildContext context, List<MatchupTip> tips) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(l10n.matchupTipsTitle, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text('vs ${tip.enemyArchetype}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(height: 6),
                    Text(tip.tip, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(AiStrategyReport report) {
    final pct = (report.confidenceScore * 100).toInt();
    final color = report.confidenceScore >= 0.7
        ? AppColors.successAccent
        : report.confidenceScore >= 0.4
            ? AppColors.primary
            : AppColors.errorAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: color, size: 16),
              const SizedBox(width: 8),
              Text('CONFIANÇA DA ANÁLISE', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
              const Spacer(),
              Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.confidenceScore,
              backgroundColor: AppColors.borderMedium,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(CrCard card) => _buildCardTileWidget(card);

  Widget _buildElixirDrop(int? cost) => _buildElixirDropWidget(cost);

  Widget _buildHistoryTab(BuildContext context, List<CrBattle> battleLog) {
    final l10n = AppLocalizations.of(context)!;
    if (battleLog.isEmpty) {
      return const EmptyStateWidget(type: EmptyStateType.battles);
    }

    // Compute W/L/D from battleLog
    int wins = 0, losses = 0, draws = 0;
    for (final b in battleLog) {
      final tc = b.team.isNotEmpty ? b.team.first.crowns : 0;
      final oc = b.opponent.isNotEmpty ? b.opponent.first.crowns : 0;
      if (tc > oc) { wins++; }
      else if (tc < oc) { losses++; }
      else { draws++; }
    }
    return Column(
      children: [
        _buildBattlesSummaryRow(wins, losses, draws, battleLog.length),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey('battles'),
            padding: const EdgeInsets.all(16.0),
            itemCount: battleLog.length,
      itemBuilder: (context, index) {
        final battle = battleLog[index];
        final teamParticipant = battle.team.isNotEmpty
            ? battle.team.first
            : null;
        final oppParticipant = battle.opponent.isNotEmpty
            ? battle.opponent.first
            : null;

        final teamCrowns = teamParticipant?.crowns ?? 0;
        final oppCrowns = oppParticipant?.crowns ?? 0;
        final isWin = teamCrowns > oppCrowns;
        final isDraw = teamCrowns == oppCrowns;

        final resultColor = isWin
            ? AppColors.successAccent
            : (isDraw ? AppColors.textMuted : AppColors.errorAccent);
        final resultText = isWin
            ? l10n.victory
            : (isDraw ? l10n.draw : l10n.defeat);

        return Card(
          color: AppColors.border,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        battle.type.toUpperCase(),
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        oppParticipant?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$teamCrowns - $oppCrowns',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      resultText,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yourDeck,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBattleDeckGrid(context, teamParticipant?.cards ?? []),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.opponentDeck,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBattleDeckGrid(context, oppParticipant?.cards ?? []),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
        ),
      ],
    );
  }

  Widget _buildBattlesSummaryRow(int wins, int losses, int draws, int total) {
    final wr = total > 0 ? (wins / total * 100).toStringAsFixed(0) : '0';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryChip(Icons.check_circle_outline, '$wins', AppColors.battleVictory),
          if (draws > 0) _summaryChip(Icons.remove_circle_outline, '$draws', AppColors.battleDraw),
          _summaryChip(Icons.cancel_outlined, '$losses', AppColors.battleDefeat),
          Text(
            '$wr% WR',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildBattleDeckGrid(BuildContext context, List<CrCard> cards) {
    if (cards.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noCards,
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
      );
    }

    final deckUrl =
        AppConstants.buildDeckUrl(cards.map((c) => c.id).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.75,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return GestureDetector(
              onTap: () => CardGuideSheet.show(context, card),
              child: _buildCardTile(card),
            );
          },
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: deckUrl));
            if (!context.mounted) return;
            final url = Uri.parse(deckUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          icon: const Icon(
            Icons.download_rounded,
            size: 14,
            color: AppColors.successAccent,
          ),
          label: Text(
            AppLocalizations.of(context)!.importButton,
            style: const TextStyle(
              color: AppColors.successAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

}

// ── Card Grid Tab — isolated StatefulWidget so sort changes don't rebuild all tabs ──

class _CardGridTab extends StatefulWidget {
  final List<CrCard> cards;
  final String emptyMessage;
  const _CardGridTab({required this.cards, required this.emptyMessage});

  @override
  State<_CardGridTab> createState() => _CardGridTabState();
}

class _CardGridTabState extends State<_CardGridTab> {
  _SortBy _sortBy = _SortBy.level;

  Widget _buildSortChip(String label, _SortBy value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _sortBy = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.borderMedium,
      checkmarkColor: Colors.black,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderStrong),
    );
  }

  int _rarityOrder(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return 0;
      case 'rare':
        return 1;
      case 'epic':
        return 2;
      case 'legendary':
        return 3;
      case 'champion':
        return 4;
      default:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    final sorted = [...widget.cards];
    sorted.sort((a, b) {
      switch (_sortBy) {
        case _SortBy.level:
          return (b.level ?? 0).compareTo(a.level ?? 0);
        case _SortBy.rarity:
          return _rarityOrder(a.rarity).compareTo(_rarityOrder(b.rarity));
        case _SortBy.elixir:
          return (a.elixirCost ?? 0).compareTo(b.elixirCost ?? 0);
      }
    });

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildSortChip('Nível', _SortBy.level),
              const SizedBox(width: 6),
              _buildSortChip('Raridade', _SortBy.rarity),
              const SizedBox(width: 6),
              _buildSortChip('Elixir', _SortBy.elixir),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final card = sorted[index];
              return GestureDetector(
                onTap: () => CardGuideSheet.show(context, card),
                child: _buildCardTileWidget(card),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoleEntry {
  final String role;
  final List<String> cards;
  final Color color;
  const _RoleEntry(this.role, this.cards, this.color);
}

// ── Top-level card tile helpers (shared by _ProfileScreenState and _CardGridTabState) ──

Color _rarityTextColorFn(String? rarity) {
  switch (rarity?.toLowerCase()) {
    case 'common':
      return AppColors.rarityCommon;
    case 'rare':
      return AppColors.rarityRare;
    case 'epic':
      return AppColors.rarityEpic;
    case 'legendary':
      return AppColors.rarityLegendary;
    case 'champion':
      return AppColors.rarityChampion;
    default:
      return AppColors.rarityUnknown;
  }
}

Widget _buildElixirDropWidget(int? cost) {
  if (cost == null) return const SizedBox.shrink();
  return SizedBox(
    width: 22,
    height: 22,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/ui_icons/elixir.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
        ),
        Text(
          '$cost',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
      ],
    ),
  );
}

Widget _buildCardTileWidget(CrCard card) {
  final rarityTxtClr = _rarityTextColorFn(card.rarity);
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // Scale 1.1x to zoom past the transparent padding CR images have around the card art
        SizedBox.expand(
          child: Transform.scale(
            scale: 1.1,
            child: Image.network(
              card.iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  card.name.isNotEmpty ? card.name[0] : '?',
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Text(
            'Level ${card.level ?? '?'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: rarityTxtClr,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, -1)),
              ],
            ),
          ),
        ),
        if (MetaCards.isMeta(card.name))
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: const Text(
                'META',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        Positioned(top: 8, left: 0, child: _buildElixirDropWidget(card.elixirCost)),
      ],
    ),
  );
}

/// 3D pushable arena button — face slides down on press (pushable_button style).
class _AnimatedArenaButton extends StatefulWidget {
  final PlayerProfile profile;
  final VoidCallback onTap;

  const _AnimatedArenaButton({required this.profile, required this.onTap});

  @override
  State<_AnimatedArenaButton> createState() => _AnimatedArenaButtonState();
}

class _AnimatedArenaButtonState extends State<_AnimatedArenaButton> {
  static const double _elevation = 5.0;
  static const double _faceHeight = 62.0;
  static const double _radius = 14.0;
  static const Duration _dur = Duration(milliseconds: 80);

  bool _pressed = false;

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) {
    setState(() => _pressed = false);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final assetPath = ArenaAssets.forArena(widget.profile.arenaName);
    final offset = _pressed ? _elevation : 0.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        height: _faceHeight + _elevation,
        child: Stack(
          children: [
            // ── Bottom "side" layer ────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(_radius),
                ),
              ),
            ),
            // ── Face layer — slides down on press ──────────────
            AnimatedPositioned(
              duration: _dur,
              curve: Curves.easeOut,
              top: offset,
              left: 0,
              right: 0,
              height: _faceHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.warning],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        _buildArenaImage(assetPath),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Builder(builder: (ctx) {
                            final locale = Localizations.localeOf(ctx);
                            final name = ArenaAssets.localizedName(
                              widget.profile.arenaName,
                              locale.languageCode,
                            );
                            return Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.black54, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArenaImage(String? assetPath) {
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.castle, size: 36, color: Colors.black54),
      );
    }
    return const Icon(Icons.castle, size: 36, color: Colors.black54);
  }
}

class _Push3DButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Push3DButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_Push3DButton> createState() => _Push3DButtonState();
}

class _Push3DButtonState extends State<_Push3DButton> {
  static const double _elevation = 5.0;
  static const double _h = 52.0;
  static const Duration _dur = Duration(milliseconds: 80);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        height: _h + _elevation,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _dur,
              curve: Curves.easeOut,
              top: _pressed ? _elevation : 0,
              left: 0,
              right: 0,
              height: _h,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.warning],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


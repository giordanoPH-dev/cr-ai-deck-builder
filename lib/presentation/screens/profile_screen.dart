import 'package:cr_ai_deck_builder/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
import '../blocs/ai_strategy/saved_strategies_state.dart';
import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/battle_stats_dashboard.dart';
import '../widgets/error_display_widget.dart';
import '../widgets/strategy_report_card.dart';
import 'how_to_play_screen.dart';
import 'search_screen.dart';

enum _SortBy { level, rarity, elixir }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _SortBy _sortBy = _SortBy.level;
  String _selectedArchetype = 'Beatdown';
  bool _headerExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerState = context.read<PlayerCubit>().state;
      final aiState = context.read<AiStrategyCubit>().state;
      // Only restore from cache if player is already loaded AND no analysis
      // is in flight yet (SplashScreen may have already triggered the restore).
      if (playerState is PlayerLoaded && aiState is AiStrategyInitial) {
        context.read<AiStrategyCubit>().loadSavedAnalysis(playerState.profile.tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (playerState is PlayerLoading || playerState is PlayerInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D47A1),
            body: Center(child: SpinKitWave(color: Colors.amber, size: 40)),
          );
        }

        if (playerState is PlayerError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D47A1),
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
          return const Scaffold(
            backgroundColor: Color(0xFF0D47A1),
            body: Center(child: SpinKitWave(color: Colors.amber, size: 40)),
          );
        }

        final profile = playerState.profile;
        final battleLog = playerState.battles;

        // Fetch saved strategies when the profile is loaded
        context.read<SavedStrategiesCubit>().fetchSavedStrategies(profile.tag);

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D47A1),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                profile.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              actions: [
                if (playerState.isFromCache)
                  Builder(
                    builder: (ctx) {
                      final l10n = AppLocalizations.of(ctx)!;
                      return Tooltip(
                        message: l10n.cacheTooltip,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 14,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.offlineBadge,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<PlayerCubit>().fetchPlayer(profile.tag),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildProfileHeader(context, profile),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return TabBar(
                      labelColor: Colors.amber,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.amber,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      tabs: [
                        const Tab(
                          text: 'IA',
                          icon: Icon(Icons.auto_awesome, size: 18),
                        ),
                        Tab(
                          text: l10n.tabDeck,
                          icon: const Icon(Icons.style, size: 18),
                        ),
                        Tab(
                          text: l10n.tabCards,
                          icon: const Icon(Icons.grid_view, size: 18),
                        ),
                        Tab(
                          text: l10n.tabBattles,
                          icon: const Icon(Icons.history, size: 18),
                        ),
                        Tab(
                          text: l10n.tabStats,
                          icon: const Icon(Icons.bar_chart, size: 18),
                        ),
                      ],
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return TabBarView(
                          children: [
                            _buildAnalysisTab(context, profile, battleLog),
                            _buildDeck8Grid(
                              context,
                              profile.currentDeck,
                              profile: profile,
                              battleLog: battleLog,
                            ),
                            _buildCardGrid(
                              context,
                              profile.cards,
                              emptyMessage: l10n.cardsNotFound,
                            ),
                            _buildHistoryTab(context, battleLog),
                            _buildStatsTab(context, profile, battleLog),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Text(
                    AppLocalizations.of(context)!.disclaimerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const BannerAdWidget(adUnitId: 'ca-app-pub-8273819403150038/5940370812'),
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
    // (internalKey, displayLabel, icon) — key stays English for AI prompt
    final archetypes = [
      ('Beatdown', l10n.archetypeBeatdown, Icons.bolt),
      ('Control', l10n.archetypeControl, Icons.shield),
      ('Cycle', l10n.archetypeCycle, Icons.loop),
      ('Siege', l10n.archetypeSiege, Icons.castle),
      ('Bait', l10n.archetypeBait, Icons.pest_control),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.chooseArchetypeLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: archetypes
                .map((a) => _buildArchetypeChip(a.$1, a.$2, a.$3))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.unlockAnalysis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _triggerFullAnalysis(context, profile, battleLog),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(
              l10n.watchAdButton,
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
    final gradeColor = _gradeColor(report.grade);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: gradeColor, width: 2),
              ),
              child: Center(
                child: Text(
                  report.grade,
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.archetype.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.gradeExplanation,
                    style: const TextStyle(
                      color: Colors.white70,
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
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text('elixir médio', style: TextStyle(color: Colors.white38, fontSize: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'COMO JOGAR',
          style: TextStyle(
            color: Colors.greenAccent,
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
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
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
                      color: Colors.white,
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
                'PONTOS FORTES',
                report.strengths,
                Colors.greenAccent,
                Icons.thumb_up,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAnalysisSection(
                'PONTOS FRACOS',
                report.weaknesses,
                Colors.redAccent,
                Icons.thumb_down,
              ),
            ),
          ],
        ),
        if (report.suggestedSwaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'TROCA SUGERIDA',
            style: TextStyle(
              color: Colors.amber,
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
                    color: Colors.redAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.remove,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ),
                  const Icon(
                    Icons.add_circle,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.add,
                      style: const TextStyle(
                        color: Colors.greenAccent,
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
            color: Colors.white60,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _triggerFullAnalysis(context, profile, battleLog),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purpleAccent,
            side: const BorderSide(color: Colors.purpleAccent),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text(
            'Analisar Novamente',
            style: TextStyle(fontSize: 12),
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
                color: Colors.white70,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase().replaceAll('+', '').replaceAll('-', '')) {
      case 'S':
        return const Color(0xFFFFD700);
      case 'A':
        return Colors.greenAccent;
      case 'B':
        return Colors.lightBlueAccent;
      case 'C':
        return Colors.orangeAccent;
      case 'D':
        return Colors.deepOrangeAccent;
      default:
        return Colors.redAccent;
    }
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

  Widget _buildArchetypeChip(String key, String displayLabel, IconData icon) {
    final isSelected = _selectedArchetype == key;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.black : Colors.amber,
      ),
      label: Text(
        displayLabel,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedArchetype = key);
      },
      selectedColor: Colors.amber,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildProfileHeader(BuildContext context, PlayerProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Always visible: name + tag + chevron toggle
            GestureDetector(
              onTap: () => setState(() => _headerExpanded = !_headerExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            profile.tag,
                            style: const TextStyle(
                              color: Colors.amber,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _headerExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable section: arena button + divider + stats
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _headerExpanded
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: _buildArenaButton(context, profile),
                        ),
                        const Divider(
                          height: 32,
                          color: Colors.white24,
                          indent: 20,
                          endIndent: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    l10n.trophiesLabel,
                                    profile.trophies.toString(),
                                    Icons.emoji_events,
                                    Colors.amber,
                                  ),
                                  _buildStatDivider(),
                                  if (profile.bestTrophies != null) ...[
                                    _buildStatItem(
                                      l10n.bestRecordLabel,
                                      profile.bestTrophies.toString(),
                                      Icons.military_tech,
                                      Colors.orangeAccent,
                                    ),
                                    _buildStatDivider(),
                                  ],
                                  if (profile.expLevel != null)
                                    _buildStatItem(
                                      l10n.levelLabel,
                                      profile.expLevel.toString(),
                                      Icons.star,
                                      Colors.amber,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArenaButton(BuildContext context, PlayerProfile profile) {
    return _AnimatedArenaButton(
      profile: profile,
      onTap: () => _showArenaGuide(context, profile.arenaName),
    );
  }

  void _showDeckPopup(BuildContext context, String deckName, {String? deckUrl}) {
    final hasRealDeck = deckUrl != null && deckUrl.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, color: Colors.amber, size: 36),
              const SizedBox(height: 12),
              Text(
                deckName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                hasRealDeck
                    ? 'Abre o deck diretamente no Clash Royale'
                    : 'Você não possui todas as cartas deste deck',
                style: TextStyle(color: hasRealDeck ? Colors.white38 : Colors.amber.withValues(alpha: 0.7), fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (hasRealDeck)
                _Push3DButton(
                  label: 'Abrir no Clash Royale',
                  icon: Icons.open_in_new_rounded,
                  onTap: () async {
                    Clipboard.setData(ClipboardData(text: deckName));
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Consiga as cartas deste deck e a importação ficará disponível automaticamente.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
    return '${AppConstants.deckLinkBaseUrl}${resolved.map((c) => c.id).join(';')}';
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
            color: Color(0xFF0D2B6B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
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
                    const Icon(Icons.castle, color: Colors.amber, size: 28),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            guide.trophyRange,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      guide.overview,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGuideSection(
                      icon: Icons.style,
                      title: AppLocalizations.of(context)!.commonDecks,
                      color: Colors.amber,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: guide.commonDecks
                            .asMap()
                            .entries
                            .map(
                              (e) => GestureDetector(
                                onTap: () => _showDeckPopup(
                                  context,
                                  e.value,
                                  deckUrl: _resolveDeckUrl(
                                    ArenaGuide.cardsForDeck(e.value),
                                    cardByName,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        e.value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.amber),
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
                      color: Colors.purpleAccent,
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
                                        color: Colors.purpleAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.purpleAccent,
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
                                          color: Colors.white,
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
                      color: Colors.greenAccent,
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
                                      color: Colors.greenAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                          color: Colors.white,
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
      color: Colors.white.withValues(alpha: 0.1),
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
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
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
    if (cards.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.deckNotFound,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final deckUrl =
        '${AppConstants.deckLinkBaseUrl}${cards.map((c) => c.id).join(';')}';

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
                onTap: () => _showCardDialog(context, card),
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
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text(
              'Compartilhar Deck',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                    child: const Row(
                      children: [
                        Icon(Icons.analytics_rounded, color: Colors.purpleAccent, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'ANÁLISE DO DECK ATUAL',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                    title: 'ANÁLISE DO ESTILO DE JOGO',
                    content: stratReport.playstyleAnalysis,
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoSection(
                    icon: Icons.school,
                    title: 'COACHING DO META',
                    content: stratReport.metaCoaching,
                    color: Colors.blueAccent,
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
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.55)),
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
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitWave(color: Colors.amber, size: 36),
                    SizedBox(height: 16),
                    Text(
                      'Analisando deck e gerando sugestão...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          FullAnalysisLoaded(:final report, :final savedAt, :final isFromCache) =>
            _buildAnalysisContent(
              context, report.strategy, profile, battleLog,
              savedAt: savedAt, isFromCache: isFromCache,
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
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
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
  }) {
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
        ? '${AppConstants.deckLinkBaseUrl}${resolvedCards.map((c) => c.id).join(';')}'
        : report.deckLinkUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Saved analysis banner ──────────────────────────────
          if (isFromCache && savedAt != null) ...[
            _buildCacheBanner(context, savedAt, profile),
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
              color: Colors.tealAccent,
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
            onPressed: () => _triggerFullAnalysis(context, profile, battleLog),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.ondemand_video, size: 16),
            label: const Text('Reanalisar (assistir vídeo)', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheBanner(BuildContext context, DateTime savedAt, PlayerProfile profile) {
    final day = savedAt.day.toString().padLeft(2, '0');
    final month = savedAt.month.toString().padLeft(2, '0');
    final hour = savedAt.hour.toString().padLeft(2, '0');
    final min = savedAt.minute.toString().padLeft(2, '0');
    final label = '$day/$month às $hour:$min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Análise salva em $label',
              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<AiStrategyCubit>().clearSavedAnalysis(profile.tag),
            child: const Icon(Icons.delete_outline, color: Colors.blueAccent, size: 16),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.style, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DECK SUGERIDO',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
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
                        style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16),
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
                            final url = Uri.parse(resolvedDeckUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: const Text('Abrir no Clash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copiar link', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTile(BuildContext context, CrCard? card, String name) {
    final rarityTxtClr = _rarityTextColor(card?.rarity);
    return GestureDetector(
      onTap: () => _showCardDialog(context, card ?? CrCard(id: 0, name: name, level: null, maxLevel: null, iconUrl: '', rarity: null, elixirCost: null)),
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
                      child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black38,
                child: Center(
                  child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.bold)),
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
    final roles = <_RoleEntry>[];
    if (bd.winCondition?.isNotEmpty == true) roles.add(_RoleEntry('WIN CONDITION', bd.winCondition!, Colors.amber));
    if (bd.spells?.isNotEmpty == true) roles.add(_RoleEntry('FEITIÇOS', bd.spells!, Colors.blueAccent));
    if (bd.airDefense?.isNotEmpty == true) roles.add(_RoleEntry('DEF. AÉREA', bd.airDefense!, Colors.tealAccent));
    if (bd.support?.isNotEmpty == true) roles.add(_RoleEntry('SUPORTE', bd.support!, Colors.purpleAccent));
    if (bd.buildings?.isNotEmpty == true) roles.add(_RoleEntry('CONSTRUÇÕES', bd.buildings!, Colors.orangeAccent));
    if (roles.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_tree_outlined, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Text('COMPOSIÇÃO DO DECK', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
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
                      child: Text(r.cards.join(', '), style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHowToPlayCta(BuildContext context, AiStrategyReport report) {
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
            colors: [Colors.greenAccent.withValues(alpha: 0.2), Colors.teal.withValues(alpha: 0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.military_tech, color: Colors.greenAccent, size: 24),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMO JOGAR', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  SizedBox(height: 2),
                  Text('Abertura, defesa, condição de vitória e mais', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.greenAccent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchupTipsCard(BuildContext context, List<MatchupTip> tips) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text('DICAS DE MATCHUP', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0)),
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
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text('vs ${tip.enemyArchetype}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(height: 6),
                    Text(tip.tip, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
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
        ? Colors.greenAccent
        : report.confidenceScore >= 0.4
            ? Colors.amber
            : Colors.redAccent;

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
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(
    BuildContext context,
    List<CrCard> cards, {
    required String emptyMessage,
  }) {
    if (cards.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final sorted = [...cards];
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
                onTap: () => _showCardDialog(context, card),
                child: _buildCardTile(card),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, _SortBy value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _sortBy = value),
      selectedColor: Colors.amber,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      checkmarkColor: Colors.black,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.white24),
    );
  }

  Widget _buildCardTile(CrCard card) {
    final rarityTxtClr = _rarityTextColor(card.rarity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Scale 1.5× to zoom past the transparent padding CR images have around the card art
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
                      color: Colors.white38,
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
            child: _buildLevelBadge(card, rarityTxtClr),
          ),
          Positioned(top: 8, left: 0, child: _buildElixirDrop(card.elixirCost)),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(CrCard card, Color rarityTxtClr) {
    return Text(
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
    );
  }

  Widget _buildElixirDrop(int? cost) {
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
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityTextColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return const Color(0xFFA4D5FF);
      case 'rare':
        return const Color(0xFFF8CA65);
      case 'epic':
        return const Color(0xFFFD9BFD);
      case 'legendary':
        return const Color(0xFFAAFF76);
      case 'champion':
        return const Color(0xFFFDE305);
      default:
        return const Color(0xFF546E7A);
    }
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

  void _showCardDialog(BuildContext context, CrCard card) {
    final rarityColor = _rarityTextColor(card.rarity);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 200,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: rarityColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card image tile
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.05)),
                      Transform.scale(
                        scale: 1.1,
                        child: Image.network(
                          card.iconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              card.name.isNotEmpty ? card.name[0] : '?',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (card.elixirCost != null)
                        Positioned(
                          top: 6,
                          left: 0,
                          child: _buildElixirDrop(card.elixirCost),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (card.rarity != null) ...[
                const SizedBox(height: 4),
                Text(
                  card.rarity!.toUpperCase(),
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(ctx)!.cardLevelInfo(
                  (card.level ?? '?').toString(),
                  (card.maxLevel ?? '?').toString(),
                ),
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<CrBattle> battleLog) {
    final l10n = AppLocalizations.of(context)!;
    if (battleLog.isEmpty) {
      return Center(
        child: Text(
          l10n.noBattlesFound,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
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
            ? Colors.greenAccent
            : (isDraw ? Colors.white54 : Colors.redAccent);
        final resultText = isWin
            ? l10n.victory
            : (isDraw ? l10n.draw : l10n.defeat);

        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
                          color: Colors.white,
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
                        color: Colors.white,
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
                        color: Colors.white70,
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
                        color: Colors.white70,
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
    );
  }

  Widget _buildBattleDeckGrid(BuildContext context, List<CrCard> cards) {
    if (cards.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.noCards,
        style: const TextStyle(color: Colors.white30, fontSize: 10),
      );
    }

    final deckUrl =
        '${AppConstants.deckLinkBaseUrl}${cards.map((c) => c.id).join(';')}';

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
              onTap: () => _showCardDialog(context, card),
              child: _buildCardTile(card),
            );
          },
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () async {
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
            color: Colors.greenAccent,
          ),
          label: Text(
            AppLocalizations.of(context)!.importButton,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTab(BuildContext context, String playerTag) {
    return BlocBuilder<SavedStrategiesCubit, SavedStrategiesState>(
      builder: (context, state) {
        return switch (state) {
          SavedStrategiesLoading() => const Center(
              child: SpinKitPulse(color: Colors.amber, size: 40),
            ),
          SavedStrategiesLoaded(:final reports) => reports.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma estratégia salva ainda.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                        title: Text(
                          report.suggestedDeckNames.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          report.playstyleAnalysis,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                        onTap: () {
                          // Show full report in a dialog or navigate
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1A237E),
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.7,
                              maxChildSize: 0.9,
                              minChildSize: 0.5,
                              expand: false,
                              builder: (context, scrollController) => SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(24),
                                child: StrategyReportCard(
                                  report: report,
                                  playerCards: context.read<PlayerCubit>().state is PlayerLoaded
                                      ? (context.read<PlayerCubit>().state as PlayerLoaded).profile.cards
                                      : const [],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          SavedStrategiesError(:final failure) => Center(
              child: Text(
                failure.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          SavedStrategiesInitial() => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _RoleEntry {
  final String role;
  final List<String> cards;
  final Color color;
  const _RoleEntry(this.role, this.cards, this.color);
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
                  color: const Color(0xFFB8940A),
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
                    colors: [Color(0xFFFFD740), Color(0xFFFFC107)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.8)),
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
                  color: const Color(0xFFB8940A),
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
                    colors: [Color(0xFFFFD740), Color(0xFFFFC107)],
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


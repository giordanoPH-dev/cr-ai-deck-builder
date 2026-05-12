import 'card_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/battle.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';

/// Full battle statistics dashboard: charts, insights, and top cards.
class BattleStatsDashboard extends StatelessWidget {
  final PlayerProfile profile;
  final List<CrBattle> battles;

  const BattleStatsDashboard({
    super.key,
    required this.profile,
    required this.battles,
  });

  // ── computed stats ───────────────────────────────────────────────
  _Stats get _stats => _Stats.from(profile, battles);

  @override
  Widget build(BuildContext context) {
    final s = _stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPlayerStatsHeader(s),
        const SizedBox(height: 16),
        _buildWinRateSection(s),
        const SizedBox(height: 16),
        _buildTrophyProgressionSection(s),
        const SizedBox(height: 16),
        _buildCrownAnalysisSection(s),
        const SizedBox(height: 16),
        _buildTopCardsSection(s),
        const SizedBox(height: 16),
        _buildInsightsSection(s),
        const SizedBox(height: 16),
        _buildWinRateTrendSection(battles),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Player stats header ──────────────────────────────────────────
  Widget _buildPlayerStatsHeader(_Stats s) {
    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statTile('NÍVEL', '${profile.expLevel ?? '?'}', Icons.star, AppColors.primary),
              _vDivider(),
              _statTile('TROFÉUS', '${profile.trophies}', Icons.emoji_events, AppColors.primary),
              _vDivider(),
              _statTile('RECORDE', '${profile.bestTrophies ?? profile.trophies}', Icons.military_tech, AppColors.warning),
            ],
          ),
          if (profile.wins != null || profile.losses != null) ...[
            const Divider(color: AppColors.borderMedium, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statTile('VITÓRIAS', '${profile.wins ?? 0}', Icons.thumb_up, AppColors.successAccent),
                _vDivider(),
                _statTile('DERROTAS', '${profile.losses ?? 0}', Icons.thumb_down, AppColors.errorAccent),
                _vDivider(),
                _statTile('WIN RATE', '${s.lifetimeWinRate}%', Icons.trending_up, AppColors.accent),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: AppColors.borderMedium);

  // ── Win rate pie chart ────────────────────────────────────────────
  Widget _buildWinRateSection(_Stats s) {
    final total = s.wins + s.losses + s.draws;
    if (total == 0) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('RESULTADO DAS BATALHAS', Icons.pie_chart, AppColors.accent),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    sections: [
                      if (s.wins > 0)
                        PieChartSectionData(
                          value: s.wins.toDouble(),
                          color: AppColors.successAccent,
                          title: '${s.wins}',
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      if (s.losses > 0)
                        PieChartSectionData(
                          value: s.losses.toDouble(),
                          color: AppColors.errorAccent,
                          title: '${s.losses}',
                          radius: 40,
                          titleStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      if (s.draws > 0)
                        PieChartSectionData(
                          value: s.draws.toDouble(),
                          color: AppColors.textDisabled,
                          title: '${s.draws}',
                          radius: 40,
                          titleStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend(AppColors.successAccent, 'Vitórias', s.wins, total),
                    const SizedBox(height: 8),
                    _legend(AppColors.errorAccent, 'Derrotas', s.losses, total),
                    if (s.draws > 0) ...[
                      const SizedBox(height: 8),
                      _legend(AppColors.textDisabled, 'Empates', s.draws, total),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Win rate: ${s.recentWinRate}%',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Últimas $total batalhas',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label: $count ($pct%)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  // ── Trophy progression line chart ────────────────────────────────
  Widget _buildTrophyProgressionSection(_Stats s) {
    if (s.trophySpots.length < 2) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('PROGRESSÃO DE TROFÉUS', Icons.show_chart, AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Dados insuficientes. Jogue mais batalhas ladder para ver seu progresso.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final minY = (s.trophySpots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 50).clamp(0, double.infinity).toDouble();
    final maxY = s.trophySpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 80;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PROGRESSÃO DE TROFÉUS', Icons.show_chart, AppColors.primary),
          const SizedBox(height: 4),
          Text(
            'Baseado em ${s.trophySpots.length} batalhas ladder',
            style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: AppColors.textDisabled, fontSize: 9),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: s.trophySpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // best trophies reference line
                  if (s.bestTrophiesY != null)
                    LineChartBarData(
                      spots: [FlSpot(0, s.bestTrophiesY!), FlSpot((s.trophySpots.length - 1).toDouble(), s.bestTrophiesY!)],
                      isCurved: false,
                      color: AppColors.warning.withValues(alpha: 0.5),
                      barWidth: 1,
                      dashArray: [6, 4],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            ),
          ),
          if (s.bestTrophiesY != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(width: 16, height: 2, color: AppColors.warning.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text('Recorde: ${profile.bestTrophies}', style: const TextStyle(color: AppColors.textDisabled, fontSize: 10)),
                ],
              ),
            ),
          if (s.netTrophyChange != 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.netTrophyChange > 0
                    ? '+${s.netTrophyChange} troféus no período'
                    : '${s.netTrophyChange} troféus no período',
                style: TextStyle(
                  color: s.netTrophyChange > 0 ? AppColors.successAccent : AppColors.errorAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Crown analysis bar chart ──────────────────────────────────────
  Widget _buildCrownAnalysisSection(_Stats s) {
    final total = s.wins + s.losses + s.draws;
    if (total == 0) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ANÁLISE DE COROAS', Icons.filter_tilt_shift, AppColors.accent),
          const SizedBox(height: 4),
          Text(
            'Coroas médias: você ${s.avgPlayerCrowns} | adversário ${s.avgOpponentCrowns}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: (s.maxCrownCount + 1).toDouble(),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final labels = ['0 coroas', '1 coroa', '2 coroas', '3 coroas'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[i], style: const TextStyle(color: AppColors.textDisabled, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(4, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: s.playerCrownCounts[i].toDouble(),
                        color: AppColors.accent,
                        width: 12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: s.opponentCrownCounts[i].toDouble(),
                        color: AppColors.errorAccent.withValues(alpha: 0.6),
                        width: 12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(AppColors.accent, 'Suas coroas'),
              const SizedBox(width: 16),
              _legendDot(AppColors.errorAccent.withValues(alpha: 0.6), 'Coroas adversário'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      );

  // ── Most used cards ───────────────────────────────────────────────
  Widget _buildTopCardsSection(_Stats s) {
    if (s.topCards.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('CARTAS MAIS USADAS', Icons.style, AppColors.primary),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.78,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: s.topCards.length,
            itemBuilder: (context, index) {
              final entry = s.topCards[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderMedium),
                      ),
                      child: CardImage(
                        url: entry.card.iconUrl,
                        cardName: entry.card.name,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.count}x',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Educational insights ──────────────────────────────────────────
  Widget _buildInsightsSection(_Stats s) {
    final insights = s.generateInsights();
    if (insights.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('DICAS PARA EVOLUIR', Icons.school, AppColors.successAccent),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(insight.icon, color: insight.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(insight.title, style: TextStyle(color: insight.color, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(insight.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Win-rate trend sparkline ──────────────────────────────────────
  Widget _buildWinRateTrendSection(List<CrBattle> battles) {
    if (battles.length < 5) return const SizedBox.shrink();

    // Compute rolling 5-battle win rates (index i covers battles[i-4..i])
    final dots = <Color>[];
    for (int i = 4; i < battles.length; i++) {
      int wins = 0;
      for (int j = i - 4; j <= i; j++) {
        final teamP = battles[j].team.isNotEmpty ? battles[j].team.first : null;
        final oppP = battles[j].opponent.isNotEmpty ? battles[j].opponent.first : null;
        final tc = teamP?.crowns ?? 0;
        final oc = oppP?.crowns ?? 0;
        if (tc > oc) wins++;
      }
      final wr = wins / 5;
      if (wr >= 0.6) {
        dots.add(AppColors.battleVictory);
      } else if (wr >= 0.4) {
        dots.add(AppColors.battleDraw);
      } else {
        dots.add(AppColors.battleDefeat);
      }
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('TENDÊNCIA', Icons.show_chart, AppColors.primary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dots.map((color) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
      ],
    );
  }
}

// ── Styled card wrapper ───────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

// ── Stats computation ─────────────────────────────────────────────────
class _CardEntry {
  final CrCard card;
  int count;
  _CardEntry(this.card) : count = 1;
}

class _Insight {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  const _Insight({required this.title, required this.body, required this.icon, required this.color});
}

class _Stats {
  final int wins;
  final int losses;
  final int draws;
  final List<FlSpot> trophySpots;
  final double? bestTrophiesY;
  final int netTrophyChange;
  final List<int> playerCrownCounts;   // index 0-3
  final List<int> opponentCrownCounts; // index 0-3
  final String avgPlayerCrowns;
  final String avgOpponentCrowns;
  final List<_CardEntry> topCards;
  final String lifetimeWinRate;
  final String recentWinRate;

  const _Stats({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.trophySpots,
    this.bestTrophiesY,
    required this.netTrophyChange,
    required this.playerCrownCounts,
    required this.opponentCrownCounts,
    required this.avgPlayerCrowns,
    required this.avgOpponentCrowns,
    required this.topCards,
    required this.lifetimeWinRate,
    required this.recentWinRate,
  });

  int get maxCrownCount {
    final all = [...playerCrownCounts, ...opponentCrownCounts];
    return all.isEmpty ? 1 : all.reduce((a, b) => a > b ? a : b);
  }

  factory _Stats.from(PlayerProfile profile, List<CrBattle> battles) {
    int wins = 0, losses = 0, draws = 0;
    final playerCrowns = [0, 0, 0, 0];
    final oppCrowns = [0, 0, 0, 0];
    int totalPlayerCrowns = 0, totalOppCrowns = 0;
    final cardCounts = <int, _CardEntry>{};

    // Trophy data (ladder only, reversed to oldest-first)
    final ladderBattles = battles.reversed.where((b) {
      final p = b.team.isNotEmpty ? b.team.first : null;
      return p?.startingTrophies != null;
    }).toList();

    final trophySpots = <FlSpot>[];
    int netChange = 0;
    for (int i = 0; i < ladderBattles.length; i++) {
      final p = ladderBattles[i].team.first;
      trophySpots.add(FlSpot(i.toDouble(), p.startingTrophies!.toDouble()));
      netChange += p.trophyChange ?? 0;
    }
    // Add current trophies as final point
    if (trophySpots.isNotEmpty) {
      trophySpots.add(FlSpot(trophySpots.length.toDouble(), profile.trophies.toDouble()));
    }

    for (final battle in battles) {
      final teamP = battle.team.isNotEmpty ? battle.team.first : null;
      final oppP = battle.opponent.isNotEmpty ? battle.opponent.first : null;
      final tc = teamP?.crowns ?? 0;
      final oc = oppP?.crowns ?? 0;

      if (tc > oc) {
        wins++;
      } else if (tc < oc) {
        losses++;
      } else {
        draws++;
      }

      playerCrowns[tc.clamp(0, 3)]++;
      oppCrowns[oc.clamp(0, 3)]++;
      totalPlayerCrowns += tc;
      totalOppCrowns += oc;

      // Aggregate cards from player's deck
      for (final card in (teamP?.cards ?? [])) {
        if (cardCounts.containsKey(card.id)) {
          cardCounts[card.id]!.count++;
        } else {
          cardCounts[card.id] = _CardEntry(card);
        }
      }
    }

    final total = wins + losses + draws;
    final avgP = total > 0 ? (totalPlayerCrowns / total).toStringAsFixed(1) : '0';
    final avgO = total > 0 ? (totalOppCrowns / total).toStringAsFixed(1) : '0';

    final sortedCards = cardCounts.values.toList()..sort((a, b) => b.count.compareTo(a.count));
    final topCards = sortedCards.take(8).toList();

    // Lifetime win rate
    final ltWins = profile.wins ?? 0;
    final ltLosses = profile.losses ?? 0;
    final ltTotal = ltWins + ltLosses;
    final ltRate = ltTotal > 0 ? (ltWins / ltTotal * 100).toStringAsFixed(0) : '?';

    final recentRate = total > 0 ? (wins / total * 100).toStringAsFixed(0) : '0';

    double? bestY;
    if (profile.bestTrophies != null && trophySpots.isNotEmpty) {
      bestY = profile.bestTrophies!.toDouble();
    }

    return _Stats(
      wins: wins,
      losses: losses,
      draws: draws,
      trophySpots: trophySpots,
      bestTrophiesY: bestY,
      netTrophyChange: netChange,
      playerCrownCounts: playerCrowns,
      opponentCrownCounts: oppCrowns,
      avgPlayerCrowns: avgP,
      avgOpponentCrowns: avgO,
      topCards: topCards,
      lifetimeWinRate: ltRate,
      recentWinRate: recentRate,
    );
  }

  List<_Insight> generateInsights() {
    final insights = <_Insight>[];
    final total = wins + losses + draws;
    if (total == 0) return insights;

    final wr = wins / total;

    // Win rate insights
    if (wr < 0.35) {
      insights.add(const _Insight(
        title: 'Taxa de vitória baixa',
        body: 'Com menos de 35% de vitórias, considere experimentar um deck do meta atual. Foque em um único arquétipo por pelo menos 20 batalhas antes de trocar.',
        icon: Icons.warning_amber,
        color: AppColors.errorAccent,
      ));
    } else if (wr >= 0.55) {
      insights.add(const _Insight(
        title: 'Ótimo desempenho!',
        body: 'Win rate acima de 55% indica que você está dominando sua arena. Tente subir de nível — você está pronto para desafios maiores.',
        icon: Icons.rocket_launch,
        color: AppColors.successAccent,
      ));
    }

    // Crown defense
    final threeZeroLosses = opponentCrownCounts.isNotEmpty ? opponentCrownCounts[3] : 0;
    if (total > 5 && threeZeroLosses / total > 0.3) {
      insights.add(const _Insight(
        title: 'Problema defensivo',
        body: 'Você está perdendo muitos jogos com 3-0 (correu 3 torres). Isso indica dificuldade na defesa. Adicione ao seu deck: splash damage (Valkyrie, Wizard) ou defesas de área.',
        icon: Icons.shield,
        color: AppColors.warning,
      ));
    }

    // Crown offensive
    final zeroWins = playerCrownCounts.isNotEmpty ? playerCrownCounts[0] : 0;
    if (total > 5 && zeroWins / total > 0.25) {
      insights.add(const _Insight(
        title: 'Pressão ofensiva insuficiente',
        body: 'Em 25%+ das batalhas você não destrói nenhuma torre. Pratique pressionar a lane adversária logo após uma boa defesa — o contra-ataque é o momento mais forte.',
        icon: Icons.bolt,
        color: AppColors.primary,
      ));
    }

    // Trophy stagnation
    if (netTrophyChange.abs() < 30 && trophySpots.length >= 5) {
      insights.add(const _Insight(
        title: 'Progresso de troféus estagnado',
        body: 'Seus troféus estão oscilando sem crescimento. Isso é normal — significa que está na faixa certa. Para subir: domine seu deck atual em vez de trocar frequentemente.',
        icon: Icons.swap_vert,
        color: AppColors.accent,
      ));
    } else if (netTrophyChange < -100) {
      insights.add(const _Insight(
        title: 'Queda de troféus detectada',
        body: 'Você perdeu muitos troféus recentemente. Considere: (1) Trocar de deck se o meta mudou, (2) Jogar menos quando estiver cansado, (3) Assistir replays de derrotas.',
        icon: Icons.trending_down,
        color: AppColors.errorAccent,
      ));
    }

    // Elixir advantage
    final avgPlayerC = (wins + losses + draws) > 0
        ? (playerCrownCounts[1] + playerCrownCounts[2] * 2 + playerCrownCounts[3] * 3) /
            (wins + losses + draws)
        : 0.0;
    final avgOppC = (wins + losses + draws) > 0
        ? (opponentCrownCounts[1] + opponentCrownCounts[2] * 2 + opponentCrownCounts[3] * 3) /
            (wins + losses + draws)
        : 0.0;

    if (avgOppC > avgPlayerC + 0.5) {
      insights.add(const _Insight(
        title: 'Adversários causam mais dano',
        body: 'Os adversários destroem mais torres que você em média. Foco: (1) Gerencie melhor o elixir — nunca fique com 10, (2) Defenda sempre antes de atacar, (3) Use o contra-ataque após a defesa.',
        icon: Icons.analytics,
        color: AppColors.accent,
      ));
    }

    return insights;
  }
}

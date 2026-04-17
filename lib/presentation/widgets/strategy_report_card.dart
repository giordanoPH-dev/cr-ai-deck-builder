import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'card_image.dart';
import 'package:cr_ai_deck_builder/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/entities/card.dart';

class StrategyReportCard extends StatelessWidget {
  final AiStrategyReport report;
  final List<CrCard> playerCards;
  final VoidCallback? onReAnalyze;
  final VoidCallback? onSave;

  const StrategyReportCard({
    super.key,
    required this.report,
    required this.playerCards,
    this.onReAnalyze,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildConfidenceBar(context),
        const SizedBox(height: 16),

        if (report.archetypeExplanation != null) ...[
          _buildSection(
            icon: Icons.lightbulb_outline,
            title: l10n.archetypeExplanationTitle,
            content: report.archetypeExplanation!,
            color: Colors.tealAccent,
          ),
          const SizedBox(height: 12),
        ],

        _buildSection(
          icon: Icons.psychology,
          title: l10n.playstyleAnalysisTitle,
          content: report.playstyleAnalysis,
          color: Colors.purpleAccent,
        ),
        const SizedBox(height: 12),

        _buildSection(
          icon: Icons.school,
          title: l10n.metaCoachingTitle,
          content: report.metaCoaching,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 12),

        _buildDeckGrid8(context),
        const SizedBox(height: 8),

        if (report.deckBreakdown != null) ...[
          _buildDeckBreakdown(context),
          const SizedBox(height: 12),
        ],

        _buildBattleGuide(context),
        const SizedBox(height: 12),

        if (report.matchupTips != null && report.matchupTips!.isNotEmpty) ...[
          _buildMatchupTips(context),
          const SizedBox(height: 12),
        ],

        if (report.deckLinkUrl.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report.deckLinkUrl));
              final url = Uri.parse(report.deckLinkUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.download_rounded),
            label: Text(
              l10n.importDeckButton,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

        const SizedBox(height: 12),

        if (onReAnalyze != null)
          TextButton.icon(
            onPressed: onReAnalyze,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.amber),
            label: Text(
              l10n.reAnalyze,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    final percentage = (report.confidenceScore * 100).toInt();
    final color = report.confidenceScore >= 0.7
        ? Colors.greenAccent
        : report.confidenceScore >= 0.4
            ? Colors.amber
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.confidence(percentage),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.confidenceScore,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckGrid8(BuildContext context) {
    final cardById = {for (final c in playerCards) c.id: c};
    final cardByName = {for (final c in playerCards) c.name.toLowerCase(): c};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.suggestedDeckTitle,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
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
              return _buildSuggestedCardTile(context, card, name);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCardTile(BuildContext context, CrCard? card, String name) {
    return GestureDetector(
      onTap: () => _showCardDialog(context, card, name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CardImage(
                  url: card?.iconUrl ?? '',
                  cardName: card?.name ?? name,
                ),
              ),
            ),
            if (card != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Text(
                  'LVL ${card.level ?? '?'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCardDialog(BuildContext context, CrCard? card, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card != null)
              CardImage(url: card.iconUrl, cardName: card.name, size: 80),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (card != null) ...[
              Text(
                AppLocalizations.of(ctx)!.cardLevelInfo(
                  (card.level ?? '?').toString(),
                  (card.maxLevel ?? '?').toString(),
                ),
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.battleGuideTitle,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuidePhase(l10n.opening, report.battleGuide.opening),
          const SizedBox(height: 8),
          if (report.battleGuide.elixirManagement != null && report.battleGuide.elixirManagement!.isNotEmpty) ...[
            _buildGuidePhase(l10n.elixirManagementTitle, report.battleGuide.elixirManagement!),
            const SizedBox(height: 8),
          ],
          _buildGuidePhase(l10n.defense, report.battleGuide.defense),
          const SizedBox(height: 8),
          _buildGuidePhase(l10n.winConditionLabel, report.battleGuide.winCondition),
          if (report.battleGuide.doubleElixirStrategy != null && report.battleGuide.doubleElixirStrategy!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildGuidePhase(l10n.doubleElixirTitle, report.battleGuide.doubleElixirStrategy!),
          ],
          if (report.battleGuide.commonMistakes != null && report.battleGuide.commonMistakes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildGuidePhase(l10n.commonMistakesTitle, report.battleGuide.commonMistakes!),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidePhase(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDeckBreakdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bd = report.deckBreakdown!;
    final roles = <String, List<String>?>{
      l10n.roleWinCondition: bd.winCondition,
      l10n.roleSpells: bd.spells,
      l10n.roleAirDefense: bd.airDefense,
      l10n.roleSupport: bd.support,
      l10n.roleBuildings: bd.buildings,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deckBreakdownTitle,
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          ...roles.entries
              .where((e) => e.value != null && e.value!.isNotEmpty)
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Text(
                            e.value!.join(', '),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildMatchupTips(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.matchupTipsTitle,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...report.matchupTips!.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                      child: Text(
                        '${l10n.vsLabel} ${tip.enemyArchetype}',
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.tip,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

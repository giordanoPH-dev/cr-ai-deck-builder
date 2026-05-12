import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'card_guide_sheet.dart';
import 'card_image.dart';
import 'package:cr_ai_deck_builder/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
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
            color: AppColors.successAccent,
          ),
          const SizedBox(height: 12),
        ],

        _buildSection(
          icon: Icons.psychology,
          title: l10n.playstyleAnalysisTitle,
          content: report.playstyleAnalysis,
          color: AppColors.accent,
        ),
        const SizedBox(height: 12),

        _buildSection(
          icon: Icons.school,
          title: l10n.metaCoachingTitle,
          content: report.metaCoaching,
          color: AppColors.accent,
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
              HapticFeedback.mediumImpact();
              await Clipboard.setData(ClipboardData(text: report.deckLinkUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link do deck copiado!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              final url = Uri.parse(report.deckLinkUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successAccent,
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
            onPressed: () {
              HapticFeedback.selectionClick();
              onReAnalyze!();
            },
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
            label: Text(
              l10n.reAnalyze,
              style: const TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    final percentage = (report.confidenceScore * 100).toInt();
    final color = report.confidenceScore >= 0.7
        ? AppColors.successAccent
        : report.confidenceScore >= 0.4
            ? AppColors.primary
            : AppColors.errorAccent;

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
                backgroundColor: AppColors.borderMedium,
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
              color: AppColors.textPrimary,
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.suggestedDeckTitle,
                style: const TextStyle(
                  color: AppColors.primary,
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
      onTap: () => CardGuideSheet.show(context, card ?? CrCard(id: 0, name: name, iconUrl: '')),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
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
                  color: AppColors.primary,
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

  Widget _buildBattleGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech, color: AppColors.successAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.battleGuideTitle,
                style: const TextStyle(
                  color: AppColors.successAccent,
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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: AppColors.textSecondary,
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deckBreakdownTitle,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
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
                          child: Text(e.key, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Text(
                            e.value!.join(', '),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.matchupTipsTitle,
                style: const TextStyle(
                  color: AppColors.accent,
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
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${l10n.vsLabel} ${tip.enemyArchetype}',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.tip,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

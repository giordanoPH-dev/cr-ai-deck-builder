import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/ai_strategy_report.dart';

/// Widget that renders a structured [AiStrategyReport] into
/// organized, visually rich sections.
///
/// Unlike the old text-dump approach, each field is rendered
/// in its own card section with appropriate styling.
class StrategyReportCard extends StatelessWidget {
  final AiStrategyReport report;
  final VoidCallback? onReAnalyze;
  final VoidCallback? onSave;

  const StrategyReportCard({
    super.key,
    required this.report,
    this.onReAnalyze,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confidence indicator
        _buildConfidenceBar(),
        const SizedBox(height: 16),

        // Playstyle Analysis
        _buildSection(
          icon: Icons.psychology,
          title: 'ANÁLISE DO ESTILO',
          content: report.playstyleAnalysis,
          color: Colors.purpleAccent,
        ),
        const SizedBox(height: 12),

        // Meta Coaching
        _buildSection(
          icon: Icons.school,
          title: 'COACHING DE META',
          content: report.metaCoaching,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 12),

        // Suggested Deck
        _buildDeckSection(),
        const SizedBox(height: 12),

        // Battle Guide
        _buildBattleGuide(),
        const SizedBox(height: 16),

        // Import Deck Button
        if (report.deckLinkUrl.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () async {
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
            label: const Text(
              'IMPORTAR DECK NO CLASH ROYALE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

        const SizedBox(height: 12),

        // Save to Cloud Button
        if (onSave != null)
          OutlinedButton.icon(
            onPressed: onSave,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text(
              'SALVAR NA NUVEM (SUPABASE)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

        const SizedBox(height: 12),

        // Re-analyze button
        if (onReAnalyze != null)
          TextButton.icon(
            onPressed: onReAnalyze,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.amber),
            label: const Text(
              'RE-ANALISAR',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildConfidenceBar() {
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
            'Confiança: $percentage%',
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

  Widget _buildDeckSection() {
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
          const Row(
            children: [
              Icon(Icons.style, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'DECK SUGERIDO',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.suggestedDeckNames.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleGuide() {
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
          const Row(
            children: [
              Icon(Icons.military_tech, color: Colors.greenAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'GUIA DE BATALHA',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuidePhase('⚔️ Abertura', report.battleGuide.opening),
          const SizedBox(height: 8),
          _buildGuidePhase('🛡️ Defesa', report.battleGuide.defense),
          const SizedBox(height: 8),
          _buildGuidePhase('🏆 Vitória', report.battleGuide.winCondition),
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
}

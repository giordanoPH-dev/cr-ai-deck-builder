import 'package:flutter/material.dart';
import '../../domain/entities/ai_strategy_report.dart';

class HowToPlayScreen extends StatelessWidget {
  final BattleGuide guide;
  final String archetype;

  const HowToPlayScreen({
    super.key,
    required this.guide,
    required this.archetype,
  });

  @override
  Widget build(BuildContext context) {
    final phases = _buildPhases();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'COMO JOGAR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildArchetypeBanner(),
            const SizedBox(height: 20),
            ...phases.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPhaseCard(p),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildArchetypeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.25), Colors.amber.withValues(alpha: 0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: Colors.amber, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTILO DE JOGO',
                  style: TextStyle(color: Colors.amber, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  archetype.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Phase> _buildPhases() {
    final result = <_Phase>[];

    final opening = guide.openingMove?.isNotEmpty == true ? guide.openingMove! : guide.opening;
    if (opening.isNotEmpty) {
      result.add(_Phase(
        icon: Icons.play_circle_outline,
        title: 'ABERTURA',
        content: opening,
        color: Colors.greenAccent,
      ));
    }

    if (guide.elixirManagement?.isNotEmpty == true) {
      result.add(_Phase(
        icon: Icons.water_drop,
        title: 'GESTÃO DE ELIXIR',
        content: guide.elixirManagement!,
        color: const Color(0xFFCE93D8),
        assetIcon: 'assets/images/ui_icons/elixir.png',
      ));
    }

    if (guide.defense.isNotEmpty) {
      result.add(_Phase(
        icon: Icons.shield_outlined,
        title: 'DEFESA',
        content: guide.defense,
        color: Colors.blueAccent,
      ));
    }

    final winExec = guide.winConditionExecution?.isNotEmpty == true
        ? guide.winConditionExecution!
        : guide.winCondition;
    if (winExec.isNotEmpty) {
      result.add(_Phase(
        icon: Icons.bolt,
        title: 'CONDIÇÃO DE VITÓRIA',
        content: winExec,
        color: Colors.amber,
      ));
    }

    if (guide.doubleElixirStrategy?.isNotEmpty == true) {
      result.add(_Phase(
        icon: Icons.speed,
        title: 'DUPLO ELIXIR',
        content: guide.doubleElixirStrategy!,
        color: Colors.orangeAccent,
      ));
    }

    if (guide.commonMistakes?.isNotEmpty == true) {
      result.add(_Phase(
        icon: Icons.warning_amber_rounded,
        title: 'ERROS COMUNS',
        content: guide.commonMistakes!,
        color: Colors.redAccent,
      ));
    }

    return result;
  }

  Widget _buildPhaseCard(_Phase phase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phase.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: phase.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: phase.assetIcon != null
                      ? Image.asset(phase.assetIcon!, width: 20, height: 20)
                      : Icon(phase.icon, color: phase.color, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                phase.title,
                style: TextStyle(
                  color: phase.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            phase.content,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _Phase {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final String? assetIcon;

  const _Phase({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    this.assetIcon,
  });
}

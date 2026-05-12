import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum EmptyStateType { battles, cards, filteredCards, savedStrategies, generic }

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? customMessage;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.generic,
    this.customMessage,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configs[type]!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedIcon(icon: config.icon, color: config.color),
            const SizedBox(height: 16),
            Text(
              config.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ?? config.subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: config.color,
                  side: BorderSide(color: config.color.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(config.actionIcon ?? Icons.refresh, size: 16),
                label: Text(
                  actionLabel ?? 'Tentar novamente',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _configs = {
    EmptyStateType.battles: _EmptyConfig(
      icon: Icons.sports_kabaddi_rounded,
      color: AppColors.battleDefeat,
      title: 'Nenhuma batalha encontrada',
      subtitle: 'Jogue algumas partidas e volte aqui para ver seu histórico de batalhas.',
      actionIcon: Icons.refresh,
    ),
    EmptyStateType.cards: _EmptyConfig(
      icon: Icons.style_rounded,
      color: AppColors.accent,
      title: 'Coleção vazia',
      subtitle: 'Suas cartas aparecerão aqui depois que seu perfil for carregado.',
      actionIcon: Icons.refresh,
    ),
    EmptyStateType.filteredCards: _EmptyConfig(
      icon: Icons.filter_list_off_rounded,
      color: AppColors.roleDefault,
      title: 'Nenhuma carta encontrada',
      subtitle: 'Nenhuma carta corresponde ao filtro selecionado. Tente outro tipo.',
      actionIcon: Icons.clear,
    ),
    EmptyStateType.savedStrategies: _EmptyConfig(
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primary,
      title: 'Sem análises salvas',
      subtitle: 'Analise seu deck na aba IA para salvar sua primeira estratégia.',
      actionIcon: null,
    ),
    EmptyStateType.generic: _EmptyConfig(
      icon: Icons.inbox_rounded,
      color: AppColors.roleDefault,
      title: 'Nada por aqui',
      subtitle: 'Nenhum dado disponível no momento.',
      actionIcon: null,
    ),
  };
}

class _EmptyConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final IconData? actionIcon;

  const _EmptyConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionIcon,
  });
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedIcon({required this.icon, required this.color});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: widget.color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Icon(widget.icon, size: 36, color: widget.color.withValues(alpha: 0.8)),
      ),
    );
  }
}

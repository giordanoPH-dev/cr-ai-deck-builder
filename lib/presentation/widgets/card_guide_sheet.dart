import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/meta_cards.dart';
import '../../core/data/card_guide.dart';
import '../../domain/entities/card.dart';
import 'card_image.dart';

/// Bottom sheet that displays local card knowledge: role, tips, synergies, counters, best decks.
/// Tapping a synergy/counter card opens its own guide recursively.
class CardGuideSheet extends StatelessWidget {
  final CrCard card;
  final int depth;

  const CardGuideSheet({super.key, required this.card, this.depth = 0});

  static void show(BuildContext context, CrCard card, {int depth = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardGuideSheet(card: card, depth: depth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = CardGuide.forCard(card.name);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _DragHandle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(card: card, guide: guide),
                    const SizedBox(height: 16),
                    if (guide == null)
                      _NoDataWidget(cardName: card.name)
                    else ...[
                      _TipsSection(tips: guide.tips),
                      const SizedBox(height: 16),
                      if (guide.synergies.isNotEmpty)
                        _CardNameList(
                          label: 'Sinergias',
                          icon: Icons.favorite,
                          color: AppColors.successAccent,
                          cardNames: guide.synergies,
                          onTap: (name) => _openCardByName(context, name),
                        ),
                      const SizedBox(height: 16),
                      if (guide.counters.isNotEmpty)
                        _CardNameList(
                          label: 'Counters',
                          icon: Icons.shield,
                          color: AppColors.errorAccent,
                          cardNames: guide.counters,
                          onTap: (name) => _openCardByName(context, name),
                        ),
                      const SizedBox(height: 16),
                      if (guide.bestDecks.isNotEmpty)
                        _BestDecksSection(decks: guide.bestDecks),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCardByName(BuildContext context, String name) {
    if (depth >= 3) return;
    final guideData = CardGuide.forCard(name);
    if (guideData == null) return;
    final stub = CrCard(
      id: 0,
      name: guideData.name,
      iconUrl: '',
    );
    CardGuideSheet.show(context, stub, depth: depth + 1);
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final CrCard card;
  final CardGuideData? guide;

  const _CardHeader({required this.card, required this.guide});

  @override
  Widget build(BuildContext context) {
    final roleColor = guide != null ? _roleColor(guide!.role) : AppColors.roleDefault;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Improvement 2: Rarity color accent bar
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.rarityColor(card.rarity),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: roleColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: card.iconUrl.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: CardImage(url: card.iconUrl, cardName: card.name, size: 64),
                )
              : Center(
                  child: Text(
                    card.name.isNotEmpty ? card.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      card.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Improvement 3: Elixir cost circle
                  if (card.elixirCost != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B1FA2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${card.elixirCost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Improvement 1: META badge
                  if (MetaCards.isMeta(card.name)) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'META',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (guide != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    guide!.role.label,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (card.elixirCost != null) ...[
                    _StatBadge(label: '${card.elixirCost}', icon: '💧'),
                    const SizedBox(width: 6),
                  ],
                  if (card.level != null) ...[
                    _StatBadge(label: 'Nv ${card.level}', icon: '⭐'),
                    const SizedBox(width: 6),
                  ],
                  if (card.rarity != null)
                    _StatBadge(label: card.rarity!, icon: null),
                ],
              ),
              if (guide != null) ...[
                const SizedBox(height: 8),
                Text(
                  guide!.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
        ),
      ],
    );
  }

  Color _roleColor(CardRole role) {
    switch (role) {
      case CardRole.winCondition:
        return AppColors.roleWinCondition;
      case CardRole.tank:
        return AppColors.roleTank;
      case CardRole.miniTank:
        return AppColors.roleTank;
      case CardRole.spellHeavy:
        return AppColors.roleSpell;
      case CardRole.spellLight:
        return AppColors.roleSpell;
      case CardRole.building:
        return AppColors.roleBuilding;
      case CardRole.airUnit:
        return AppColors.roleAirDefense;
      case CardRole.swarm:
        return AppColors.roleSwarm;
      case CardRole.support:
        return AppColors.roleSupport;
      case CardRole.champion:
        return AppColors.rarityChampion;
      case CardRole.evolution:
        return AppColors.roleSupport;
    }
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String? icon;

  const _StatBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        icon != null ? '$icon $label' : label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  final List<String> tips;
  const _TipsSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'Como usar', icon: Icons.lightbulb_outline, color: AppColors.primary),
        const SizedBox(height: 10),
        ...tips.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardNameList extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> cardNames;
  final void Function(String name) onTap;

  const _CardNameList({
    required this.label,
    required this.icon,
    required this.color,
    required this.cardNames,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: label, icon: icon, color: color),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cardNames.map((name) {
            final hasGuide = CardGuide.forCard(name) != null;
            return GestureDetector(
              onTap: hasGuide
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap(name);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (hasGuide) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 14, color: color.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BestDecksSection extends StatelessWidget {
  final List<String> decks;
  const _BestDecksSection({required this.decks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'Melhor em',
          icon: Icons.grid_view_rounded,
          color: AppColors.accent,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: decks
              .map(
                (d) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentBorder),
                  ),
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _NoDataWidget extends StatelessWidget {
  final String cardName;
  const _NoDataWidget({required this.cardName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textDisabled, size: 32),
          const SizedBox(height: 12),
          Text(
            'Guia não disponível para $cardName ainda.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

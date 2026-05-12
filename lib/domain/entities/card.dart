import 'package:equatable/equatable.dart';

class CrCard extends Equatable {
  final int id;
  final String name;
  final int? level;
  final int? maxLevel;
  final String iconUrl;
  final int? elixirCost;
  final String? rarity;
  /// Non-null and > 0 when this card is placed in an Evolution slot in the current deck.
  final int? evolutionLevel;
  /// Non-null on all evolvable cards regardless of evolution state (1, 2, or 3).
  /// Indicates the player owns a card that can be evolved.
  final int? maxEvolutionLevel;

  const CrCard({
    required this.id,
    required this.name,
    this.level,
    this.maxLevel,
    required this.iconUrl,
    this.elixirCost,
    this.rarity,
    this.evolutionLevel,
    this.maxEvolutionLevel,
  });

  @override
  List<Object?> get props => [id, name, level, maxLevel, iconUrl, elixirCost, rarity, evolutionLevel, maxEvolutionLevel];
}

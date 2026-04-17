import 'package:equatable/equatable.dart';

class CrCard extends Equatable {
  final int id;
  final String name;
  final int? level;
  final int? maxLevel;
  final String iconUrl;
  final int? elixirCost;
  final String? rarity;

  const CrCard({
    required this.id,
    required this.name,
    this.level,
    this.maxLevel,
    required this.iconUrl,
    this.elixirCost,
    this.rarity,
  });

  @override
  List<Object?> get props => [id, name, level, maxLevel, iconUrl, elixirCost, rarity];
}

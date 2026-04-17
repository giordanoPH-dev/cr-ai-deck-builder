import '../../domain/entities/card.dart';

class CrCardModel extends CrCard {
  const CrCardModel({
    required super.id,
    required super.name,
    super.level,
    super.maxLevel,
    required super.iconUrl,
    super.elixirCost,
    super.rarity,
  });

  factory CrCardModel.fromJson(Map<String, dynamic> json) {
    final iconUrl =
        json['iconUrls']?['medium'] as String? ??
        json['iconUrls']?['large'] as String? ??
        json['iconUrl'] as String? ??
        '';
    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int?,
      maxLevel: json['maxLevel'] as int?,
      iconUrl: iconUrl,
      elixirCost: json['elixirCost'] as int?,
      rarity: json['rarity'] as String?,
    );
  }

  factory CrCardModel.fromCacheJson(Map<String, dynamic> json) {
    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int?,
      maxLevel: json['maxLevel'] as int?,
      iconUrl: json['iconUrl'] as String? ?? '',
      elixirCost: json['elixirCost'] as int?,
      rarity: json['rarity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'maxLevel': maxLevel,
      'iconUrl': iconUrl,
      'elixirCost': elixirCost,
      'rarity': rarity,
    };
  }
}

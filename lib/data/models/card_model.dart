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
    super.evolutionLevel,
    super.maxEvolutionLevel,
  });

  factory CrCardModel.fromJson(Map<String, dynamic> json) {
    final iconUrl =
        json['iconUrls']?['medium'] as String? ??
        json['iconUrls']?['large'] as String? ??
        json['iconUrl'] as String? ??
        '';

    int? level = json['level'] as int?;
    int? maxLevel = json['maxLevel'] as int?;

    // The CR API still returns rarity-relative levels (Common 1-13, Rare 1-11,
    // Epic 1-8, Legendary 1-5, Champion 1-3). Convert to the unified scale
    // (max 13) that the game now displays. Cards already on the unified scale
    // have maxLevel >= 13 and are left unchanged.
    if (level != null && maxLevel != null && maxLevel < 13) {
      level = level + (13 - maxLevel);
      maxLevel = 13;
    }

    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: level,
      maxLevel: maxLevel,
      iconUrl: iconUrl,
      elixirCost: json['elixirCost'] as int?,
      rarity: json['rarity'] as String?,
      evolutionLevel: json['evolutionLevel'] as int?,
      maxEvolutionLevel: json['maxEvolutionLevel'] as int?,
    );
  }

  factory CrCardModel.fromCacheJson(Map<String, dynamic> json) {
    int? level = json['level'] as int?;
    int? maxLevel = json['maxLevel'] as int?;

    // Same normalization for backward compatibility with pre-fix cached data.
    if (level != null && maxLevel != null && maxLevel < 13) {
      level = level + (13 - maxLevel);
      maxLevel = 13;
    }

    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: level,
      maxLevel: maxLevel,
      iconUrl: json['iconUrl'] as String? ?? '',
      elixirCost: json['elixirCost'] as int?,
      rarity: json['rarity'] as String?,
      evolutionLevel: json['evolutionLevel'] as int?,
      maxEvolutionLevel: json['maxEvolutionLevel'] as int?,
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
      'evolutionLevel': evolutionLevel,
      'maxEvolutionLevel': maxEvolutionLevel,
    };
  }
}

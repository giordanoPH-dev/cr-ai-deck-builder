import '../../domain/entities/card.dart';

/// Data model for [CrCard] with JSON serialization.
///
/// Extends the domain entity to add fromJson/toJson capabilities
/// while maintaining the clean separation of concerns.
class CrCardModel extends CrCard {
  const CrCardModel({
    required super.id,
    required super.name,
    super.level,
    super.maxLevel,
    required super.iconUrl,
  });

  factory CrCardModel.fromJson(Map<String, dynamic> json) {
    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int?,
      maxLevel: json['maxLevel'] as int?,
      iconUrl: json['iconUrls']?['medium'] ?? '',
    );
  }

  /// Creates a model from a cached JSON map (flat iconUrl, no nested iconUrls).
  factory CrCardModel.fromCacheJson(Map<String, dynamic> json) {
    return CrCardModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int?,
      maxLevel: json['maxLevel'] as int?,
      iconUrl: json['iconUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'maxLevel': maxLevel,
      'iconUrl': iconUrl,
    };
  }
}

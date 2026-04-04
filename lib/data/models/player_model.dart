import '../../domain/entities/player.dart';
import 'card_model.dart';

/// Data model for [PlayerProfile] with JSON serialization.
class PlayerProfileModel extends PlayerProfile {
  const PlayerProfileModel({
    required super.tag,
    required super.name,
    required super.trophies,
    required super.arenaName,
    super.currentDeck = const [],
    super.cards = const [],
  });

  factory PlayerProfileModel.fromJson(Map<String, dynamic> json) {
    final deckList = json['currentDeck'] as List? ?? [];
    final cardsList = json['cards'] as List? ?? [];

    return PlayerProfileModel(
      tag: json['tag'] as String,
      name: json['name'] as String,
      trophies: json['trophies'] as int,
      arenaName: json['arena']?['name'] ?? 'Unknown Arena',
      currentDeck: deckList.map((e) => CrCardModel.fromJson(e as Map<String, dynamic>)).toList(),
      cards: cardsList.map((e) => CrCardModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Reconstruct from SharedPreferences cache.
  factory PlayerProfileModel.fromCacheJson(Map<String, dynamic> json) {
    final deckList = json['currentDeck'] as List? ?? [];
    final cardsList = json['cards'] as List? ?? [];

    return PlayerProfileModel(
      tag: json['tag'] as String,
      name: json['name'] as String,
      trophies: json['trophies'] as int,
      arenaName: json['arenaName'] as String? ?? 'Unknown Arena',
      currentDeck: deckList.map((e) => CrCardModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
      cards: cardsList.map((e) => CrCardModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'trophies': trophies,
      'arenaName': arenaName,
      'currentDeck': currentDeck.map((c) => (c as CrCardModel).toJson()).toList(),
      'cards': cards.map((c) => (c as CrCardModel).toJson()).toList(),
    };
  }

  /// Create a model from a domain entity (for caching purposes).
  factory PlayerProfileModel.fromEntity(PlayerProfile entity) {
    return PlayerProfileModel(
      tag: entity.tag,
      name: entity.name,
      trophies: entity.trophies,
      arenaName: entity.arenaName,
      currentDeck: entity.currentDeck
          .map((c) => CrCardModel(
                id: c.id,
                name: c.name,
                level: c.level,
                maxLevel: c.maxLevel,
                iconUrl: c.iconUrl,
              ))
          .toList(),
      cards: entity.cards
          .map((c) => CrCardModel(
                id: c.id,
                name: c.name,
                level: c.level,
                maxLevel: c.maxLevel,
                iconUrl: c.iconUrl,
              ))
          .toList(),
    );
  }
}

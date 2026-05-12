import '../../domain/entities/player.dart';
import 'card_model.dart';

class PlayerProfileModel extends PlayerProfile {
  const PlayerProfileModel({
    required super.tag,
    required super.name,
    required super.trophies,
    super.bestTrophies,
    super.expLevel,
    super.wins,
    super.losses,
    required super.arenaName,
    super.arenaIconUrl,
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
      bestTrophies: json['bestTrophies'] as int?,
      expLevel: json['expLevel'] as int?,
      wins: json['wins'] as int?,
      losses: json['losses'] as int?,
      arenaName: json['arena']?['name'] ?? 'Unknown Arena',
      arenaIconUrl: json['arena']?['iconUrls']?['medium'] as String?,
      currentDeck: deckList.map((e) => CrCardModel.fromJson(e as Map<String, dynamic>)).toList(),
      cards: cardsList.map((e) => CrCardModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  factory PlayerProfileModel.fromCacheJson(Map<String, dynamic> json) {
    final deckList = json['currentDeck'] as List? ?? [];
    final cardsList = json['cards'] as List? ?? [];

    return PlayerProfileModel(
      tag: json['tag'] as String,
      name: json['name'] as String,
      trophies: json['trophies'] as int,
      bestTrophies: json['bestTrophies'] as int?,
      expLevel: json['expLevel'] as int?,
      wins: json['wins'] as int?,
      losses: json['losses'] as int?,
      arenaName: json['arenaName'] as String? ?? 'Unknown Arena',
      arenaIconUrl: json['arenaIconUrl'] as String?,
      currentDeck: deckList.map((e) => CrCardModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
      cards: cardsList.map((e) => CrCardModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'trophies': trophies,
      'bestTrophies': bestTrophies,
      'expLevel': expLevel,
      'wins': wins,
      'losses': losses,
      'arenaName': arenaName,
      'arenaIconUrl': arenaIconUrl,
      'currentDeck': currentDeck.map((c) => (c as CrCardModel).toJson()).toList(),
      'cards': cards.map((c) => (c as CrCardModel).toJson()).toList(),
    };
  }

  factory PlayerProfileModel.fromEntity(PlayerProfile entity) {
    return PlayerProfileModel(
      tag: entity.tag,
      name: entity.name,
      trophies: entity.trophies,
      bestTrophies: entity.bestTrophies,
      expLevel: entity.expLevel,
      wins: entity.wins,
      losses: entity.losses,
      arenaName: entity.arenaName,
      arenaIconUrl: entity.arenaIconUrl,
      currentDeck: entity.currentDeck
          .map((c) => CrCardModel(
                id: c.id,
                name: c.name,
                level: c.level,
                maxLevel: c.maxLevel,
                iconUrl: c.iconUrl,
                elixirCost: c.elixirCost,
                rarity: c.rarity,
                evolutionLevel: c.evolutionLevel,
                maxEvolutionLevel: c.maxEvolutionLevel,
              ))
          .toList(),
      cards: entity.cards
          .map((c) => CrCardModel(
                id: c.id,
                name: c.name,
                level: c.level,
                maxLevel: c.maxLevel,
                iconUrl: c.iconUrl,
                elixirCost: c.elixirCost,
                rarity: c.rarity,
                evolutionLevel: c.evolutionLevel,
                maxEvolutionLevel: c.maxEvolutionLevel,
              ))
          .toList(),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'card.dart';

class PlayerProfile extends Equatable {
  final String tag;
  final String name;
  final int trophies;
  final int? bestTrophies;
  final int? expLevel;
  final int? wins;
  final int? losses;
  final String arenaName;
  final String? arenaIconUrl;
  final List<CrCard> currentDeck;
  final List<CrCard> cards;

  const PlayerProfile({
    required this.tag,
    required this.name,
    required this.trophies,
    this.bestTrophies,
    this.expLevel,
    this.wins,
    this.losses,
    required this.arenaName,
    this.arenaIconUrl,
    this.currentDeck = const [],
    this.cards = const [],
  });

  @override
  List<Object?> get props => [tag, name, trophies, bestTrophies, expLevel, wins, losses, arenaName, arenaIconUrl, currentDeck, cards];
}

import 'package:equatable/equatable.dart';
import 'card.dart';

/// Pure domain entity representing a Clash Royale player profile.
class PlayerProfile extends Equatable {
  final String tag;
  final String name;
  final int trophies;
  final String arenaName;
  final List<CrCard> currentDeck;
  final List<CrCard> cards;

  const PlayerProfile({
    required this.tag,
    required this.name,
    required this.trophies,
    required this.arenaName,
    this.currentDeck = const [],
    this.cards = const [],
  });

  @override
  List<Object?> get props => [tag, name, trophies, arenaName, currentDeck, cards];
}

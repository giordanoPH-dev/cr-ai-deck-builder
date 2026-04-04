import 'package:equatable/equatable.dart';
import 'card.dart';

/// Pure domain entity representing a battle participant.
class BattleParticipant extends Equatable {
  final String tag;
  final String name;
  final int crowns;
  final List<CrCard> cards;

  const BattleParticipant({
    required this.tag,
    required this.name,
    required this.crowns,
    this.cards = const [],
  });

  @override
  List<Object?> get props => [tag, name, crowns, cards];
}

/// Pure domain entity representing a Clash Royale battle.
class CrBattle extends Equatable {
  final String type;
  final String battleTime;
  final List<BattleParticipant> team;
  final List<BattleParticipant> opponent;

  const CrBattle({
    required this.type,
    required this.battleTime,
    required this.team,
    required this.opponent,
  });

  @override
  List<Object?> get props => [type, battleTime, team, opponent];
}

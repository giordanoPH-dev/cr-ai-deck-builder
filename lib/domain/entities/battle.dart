import 'package:equatable/equatable.dart';
import 'card.dart';

class BattleParticipant extends Equatable {
  final String tag;
  final String name;
  final int crowns;
  final int? startingTrophies;
  final int? trophyChange;
  final List<CrCard> cards;

  const BattleParticipant({
    required this.tag,
    required this.name,
    required this.crowns,
    this.startingTrophies,
    this.trophyChange,
    this.cards = const [],
  });

  @override
  List<Object?> get props => [tag, name, crowns, startingTrophies, trophyChange, cards];
}

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

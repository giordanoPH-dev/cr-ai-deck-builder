import '../../domain/entities/battle.dart';
import 'card_model.dart';

class BattleParticipantModel extends BattleParticipant {
  const BattleParticipantModel({
    required super.tag,
    required super.name,
    required super.crowns,
    super.startingTrophies,
    super.trophyChange,
    super.cards = const [],
  });

  factory BattleParticipantModel.fromJson(Map<String, dynamic> json) {
    final cardsList = json['cards'] as List? ?? [];
    return BattleParticipantModel(
      tag: json['tag'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      crowns: json['crowns'] as int? ?? 0,
      startingTrophies: json['startingTrophies'] as int?,
      trophyChange: json['trophyChange'] as int?,
      cards: cardsList.map((e) => CrCardModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  factory BattleParticipantModel.fromCacheJson(Map<String, dynamic> json) {
    final cardsList = json['cards'] as List? ?? [];
    return BattleParticipantModel(
      tag: json['tag'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      crowns: json['crowns'] as int? ?? 0,
      startingTrophies: json['startingTrophies'] as int?,
      trophyChange: json['trophyChange'] as int?,
      cards: cardsList.map((e) => CrCardModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'crowns': crowns,
      'startingTrophies': startingTrophies,
      'trophyChange': trophyChange,
      'cards': cards.map((c) => (c as CrCardModel).toJson()).toList(),
    };
  }
}

class CrBattleModel extends CrBattle {
  const CrBattleModel({
    required super.type,
    required super.battleTime,
    required super.team,
    required super.opponent,
  });

  factory CrBattleModel.fromJson(Map<String, dynamic> json) {
    final teamList = json['team'] as List? ?? [];
    final opponentList = json['opponent'] as List? ?? [];

    return CrBattleModel(
      type: json['type'] as String? ?? 'Unknown',
      battleTime: json['battleTime'] as String? ?? '',
      team: teamList.map((e) => BattleParticipantModel.fromJson(e as Map<String, dynamic>)).toList(),
      opponent: opponentList.map((e) => BattleParticipantModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  factory CrBattleModel.fromCacheJson(Map<String, dynamic> json) {
    final teamList = json['team'] as List? ?? [];
    final opponentList = json['opponent'] as List? ?? [];

    return CrBattleModel(
      type: json['type'] as String? ?? 'Unknown',
      battleTime: json['battleTime'] as String? ?? '',
      team: teamList.map((e) => BattleParticipantModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
      opponent: opponentList.map((e) => BattleParticipantModel.fromCacheJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'battleTime': battleTime,
      'team': team.map((p) => (p as BattleParticipantModel).toJson()).toList(),
      'opponent': opponent.map((p) => (p as BattleParticipantModel).toJson()).toList(),
    };
  }
}

class CrCard {
  final int id;
  final String name;
  final int? level;
  final int? maxLevel;
  final String iconUrl;

  CrCard({
    required this.id,
    required this.name,
    this.level,
    this.maxLevel,
    required this.iconUrl,
  });

  factory CrCard.fromJson(Map<String, dynamic> json) {
    return CrCard(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int?,
      maxLevel: json['maxLevel'] as int?,
      iconUrl: json['iconUrls']?['medium'] ?? '',
    );
  }
}

class PlayerProfile {
  final String tag;
  final String name;
  final int trophies;
  final String arenaName;
  final List<CrCard> currentDeck;
  final List<CrCard> cards;

  PlayerProfile({
    required this.tag,
    required this.name,
    required this.trophies,
    required this.arenaName,
    this.currentDeck = const [],
    this.cards = const [],
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    var deckList = json['currentDeck'] as List? ?? [];
    List<CrCard> currentDeck = deckList.map((e) => CrCard.fromJson(e)).toList();

    var cardsList = json['cards'] as List? ?? [];
    List<CrCard> cards = cardsList.map((e) => CrCard.fromJson(e)).toList();

    return PlayerProfile(
      tag: json['tag'] as String,
      name: json['name'] as String,
      trophies: json['trophies'] as int,
      arenaName: json['arena']?['name'] ?? 'Unknown Arena',
      currentDeck: currentDeck,
      cards: cards,
    );
  }
}

class CrBattleParticipant {
  final String tag;
  final String name;
  final int crowns;
  final List<CrCard> cards;

  CrBattleParticipant({
    required this.tag,
    required this.name,
    required this.crowns,
    this.cards = const [],
  });

  factory CrBattleParticipant.fromJson(Map<String, dynamic> json) {
    var cardsList = json['cards'] as List? ?? [];
    return CrBattleParticipant(
      tag: json['tag'] as String,
      name: json['name'] as String,
      crowns: json['crowns'] as int,
      cards: cardsList.map((e) => CrCard.fromJson(e)).toList(),
    );
  }
}

class CrBattle {
  final String type;
  final String battleTime;
  final List<CrBattleParticipant> team;
  final List<CrBattleParticipant> opponent;

  CrBattle({
    required this.type,
    required this.battleTime,
    required this.team,
    required this.opponent,
  });

  factory CrBattle.fromJson(Map<String, dynamic> json) {
    var teamList = json['team'] as List? ?? [];
    var opponentList = json['opponent'] as List? ?? [];

    return CrBattle(
      type: json['type'] as String? ?? 'Unknown',
      battleTime: json['battleTime'] as String? ?? '',
      team: teamList.map((e) => CrBattleParticipant.fromJson(e)).toList(),
      opponent: opponentList.map((e) => CrBattleParticipant.fromJson(e)).toList(),
    );
  }
}

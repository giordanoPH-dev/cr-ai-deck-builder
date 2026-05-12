abstract class ArenaAssets {
  static const String _base = 'assets/images/arenas';

  static const Map<String, String> _assetMap = {
    'training camp': '$_base/training_camp_arena.png',
    'goblin stadium': '$_base/goblin_stadium_arena.png',
    'bone pit': '$_base/bone_pit_arena.png',
    "pekka's playhouse": '$_base/p.e.k.k.a\'s_playhouse_arena.png',
    "p.e.k.k.a's playhouse": '$_base/p.e.k.k.a\'s_playhouse_arena.png',
    'spell valley': '$_base/spell_valley_arena.png',
    'royal arena': '$_base/royal_arena.png',
    'frozen peak': '$_base/frozen_peak_arena.png',
    'jungle arena': '$_base/jungle_arena.png',
    'hog mountain': '$_base/hog_mountain_arena.png',
    'electro valley': '$_base/electro_valley_arena.png',
    'spooky town': '$_base/spooky_town_arena.png',
    "rascal's hideout": '$_base/rascal\'s_hideout_arena.png',
    'serenity peak': '$_base/serenity_peak_arena.png',
    "miner's mine": '$_base/miner\'s_mine_arena.png',
    "executioner's kitchen": '$_base/executioner\'s_kitchen_arena.png',
    "builder's kitchen": '$_base/executioner\'s_kitchen_arena.png',
    'dragon spa': '$_base/dragon_spa_arena.png',
    'legendary arena': '$_base/legendary_arena.png',
    'royal crypt': '$_base/royal_crypt_arena.png',
    'silent sanctuary': '$_base/silent_sanctuary_arena.png',
    'boot camp': '$_base/boot_camp_arena.png',
  };

  static const Map<String, String> _ptNames = {
    'training camp': 'Campo de Treinamento',
    'goblin stadium': 'Estádio Goblin',
    'bone pit': 'Poço de Ossos',
    'barbarian bowl': 'Pista dos Bárbaros',
    "pekka's playhouse": 'Casa da P.E.K.K.A',
    "p.e.k.k.a's playhouse": 'Casa da P.E.K.K.A',
    'spell valley': 'Vale dos Feitiços',
    "builder's workshop": 'Oficina do Construtor',
    'royal arena': 'Arena Real',
    'frozen peak': 'Pico Gelado',
    'jungle arena': 'Arena da Selva',
    'hog mountain': 'Montanha do Porco',
    'electro valley': 'Vale Elétrico',
    'spooky town': 'Cidade Fantasma',
    "rascal's hideout": 'Covil dos Patifes',
    'serenity peak': 'Pico da Serenidade',
    "miner's mine": 'Mina do Mineiro',
    "executioner's kitchen": 'Cozinha do Executor',
    "builder's kitchen": 'Cozinha do Construtor',
    'dragon spa': 'Spa dos Dragões',
    'glacial peak': 'Pico Glacial',
    'legendary arena': 'Arena Lendária',
    'royal crypt': 'Cripta Real',
    'silent sanctuary': 'Santuário Silencioso',
    'challenger i': 'Desafiante I',
    'challenger ii': 'Desafiante II',
    'challenger iii': 'Desafiante III',
    'master i': 'Mestre I',
    'master ii': 'Mestre II',
    'master iii': 'Mestre III',
    'champion': 'Campeão',
    'grand champion': 'Grande Campeão',
    'royal champion': 'Campeão Real',
    'ultimate champion': 'Campeão Ultimate',
  };

  static const Map<String, String> _esNames = {
    'training camp': 'Campo de Entrenamiento',
    'goblin stadium': 'Estadio Goblin',
    'bone pit': 'Foso de Huesos',
    'barbarian bowl': 'Pista de los Bárbaros',
    "pekka's playhouse": 'Sala de Juegos de P.E.K.K.A',
    "p.e.k.k.a's playhouse": 'Sala de Juegos de P.E.K.K.A',
    'spell valley': 'Valle de los Hechizos',
    "builder's workshop": 'Taller del Constructor',
    'royal arena': 'Arena Real',
    'frozen peak': 'Pico Helado',
    'jungle arena': 'Arena de la Selva',
    'hog mountain': 'Montaña del Cerdo',
    'electro valley': 'Valle Eléctrico',
    'spooky town': 'Ciudad Fantasmal',
    "rascal's hideout": 'Guarida de los Rufianes',
    'serenity peak': 'Pico de la Serenidad',
    "miner's mine": 'Mina del Minero',
    "executioner's kitchen": 'Cocina del Ejecutor',
    "builder's kitchen": 'Cocina del Constructor',
    'dragon spa': 'Spa del Dragón',
    'glacial peak': 'Pico Glaciar',
    'legendary arena': 'Arena Legendaria',
    'royal crypt': 'Cripta Real',
    'silent sanctuary': 'Santuario Silencioso',
    'challenger i': 'Retador I',
    'challenger ii': 'Retador II',
    'challenger iii': 'Retador III',
    'master i': 'Maestro I',
    'master ii': 'Maestro II',
    'master iii': 'Maestro III',
    'champion': 'Campeón',
    'grand champion': 'Gran Campeón',
    'royal champion': 'Campeón Real',
    'ultimate champion': 'Campeón Ultimate',
  };

  /// Returns the local asset path for [arenaName], or null if not found.
  /// Tries exact match first, then partial match on map keys.
  static String? forArena(String arenaName) {
    final key = arenaName.toLowerCase().trim();
    if (_assetMap.containsKey(key)) return _assetMap[key];
    // Partial match: useful for minor name changes (e.g. "P.E.K.K.A" variants)
    for (final entry in _assetMap.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Returns the localized display name for [englishName] given a [languageCode].
  static String localizedName(String englishName, String languageCode) {
    final key = englishName.toLowerCase().trim();
    if (languageCode == 'pt') return _ptNames[key] ?? englishName;
    if (languageCode == 'es') return _esNames[key] ?? englishName;
    return englishName;
  }
}

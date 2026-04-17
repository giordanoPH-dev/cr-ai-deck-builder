abstract class ArenaAssets {
  static const String _base = 'assets/images/arenas';

  static const Map<String, String> _assetMap = {
    'training camp': '$_base/training_camp_arena.png',
    'goblin stadium': '$_base/goblin_stadium_arena.png',
    'bone pit': '$_base/bone_pit_arena.png',
    "pekka's playhouse": '$_base/p.e.k.k.a\'s_playhouse_arena.png',
    'spell valley': '$_base/spell_valley_arena.png',
    'royal arena': '$_base/royal_arena.png',
    'frozen peak': '$_base/frozen_peak_arena.png',
    'jungle arena': '$_base/jungle_arena.png',
    'hog mountain': '$_base/hog_mountain_arena.png',
    'electro valley': '$_base/electro_valley_arena.png',
    'spooky town': '$_base/spooky_town_arena.png',
    "rascal's hideout": '$_base/rascal\'s_hideout_arena.png',
    'serenity peak': '$_base/serenity_peak_arena.png',
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
    'glacial peak': 'Pico Glacial',
    'legendary arena': 'Arena Lendária',
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
    'glacial peak': 'Pico Glaciar',
    'legendary arena': 'Arena Legendaria',
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
  static String? forArena(String arenaName) =>
      _assetMap[arenaName.toLowerCase().trim()];

  /// Returns the localized display name for [englishName] given a [languageCode].
  static String localizedName(String englishName, String languageCode) {
    final key = englishName.toLowerCase().trim();
    if (languageCode == 'pt') return _ptNames[key] ?? englishName;
    if (languageCode == 'es') return _esNames[key] ?? englishName;
    return englishName;
  }
}

abstract class MetaCards {
  // Derived from the meta deck templates in AiDatasource._deckKnowledgeBase().
  // Used to show META badge in the card collection tab.
  static const Set<String> _names = {
    // LavaLoon
    'Lava Hound', 'Balloon', 'Mega Minion', 'Minions', 'Barbarians',
    'Tombstone', 'Fireball', 'Baby Dragon', 'Miner', 'Lightning', 'Arrows',
    // Hog Cycle
    'Hog Rider', 'Ice Golem', 'Skeletons', 'Ice Spirit', 'Musketeer', 'Cannon',
    'Log', 'Valkyrie', 'Goblins', 'Executioner', 'Tornado', 'Rocket',
    // Golem
    'Golem', 'Night Witch', 'Lumberjack', 'Barbarian Barrel', 'Mini Pekka', 'Bomber',
    // Graveyard
    'Graveyard', 'Knight', 'Ice Wizard', 'Goblin Hut', 'Poison',
    // X-Bow
    'X-Bow', 'Tesla', 'Archers',
    // Bait
    'Goblin Barrel', 'Goblin Gang', 'Princess', 'Inferno Tower',
    'Rascals', 'Dart Goblin', 'Prince',
    // PEKKA Bridge Spam
    'Battle Ram', 'PEKKA', 'Bandit', 'Electro Wizard', 'Dark Prince',
    'Royal Ghost', 'Zap',
    // Mortar Cycle
    'Mortar', 'Bats', 'Minion Horde', 'Spear Goblins',
    // Giant
    'Giant', 'Skeleton Army',
    // Elixir Golem
    'Elixir Golem', 'Battle Healer', 'Electro Dragon', 'Earthquake',
    // Wall Breakers
    'Wall Breakers', 'Bomb Tower', 'Mega Knight',
    // Common spell/cycle
    'Rage', 'Freeze',
  };

  static bool isMeta(String cardName) {
    final normalized = cardName.trim();
    return _names.any(
      (n) => n.toLowerCase() == normalized.toLowerCase(),
    );
  }
}

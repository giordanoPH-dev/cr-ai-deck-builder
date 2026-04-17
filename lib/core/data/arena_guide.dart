/// Local knowledge base with strategies and meta info for each Clash Royale arena.
class ArenaGuide {
  final String arenaName;
  final String trophyRange;
  final String overview;
  final List<String> commonDecks;

  /// Optional CR deck deep-links parallel to [commonDecks].
  /// Each entry is either a full `https://link.clashroyale.com/deck/…` URL
  /// (with real card IDs) or null when no link is available yet.
  final List<String?> commonDeckUrls;

  final List<String> strategies;
  final List<String> winTips;

  /// Condensed text injected into the Gemini prompt for context.
  final String aiContext;

  const ArenaGuide({
    required this.arenaName,
    required this.trophyRange,
    required this.overview,
    required this.commonDecks,
    this.commonDeckUrls = const [],
    required this.strategies,
    required this.winTips,
    required this.aiContext,
  });

  /// Returns the 8 card names for a well-known meta deck name, or null when
  /// the deck description doesn't match a known composition.
  /// Patterns are checked in order from most specific to most general.
  static List<String>? cardsForDeck(String deckName) {
    final lower = deckName.toLowerCase();

    // LavaLoon variants — check Freeze variant first
    if (lower.contains('lavaloon') && lower.contains('freeze')) {
      return const ['Lava Hound', 'Balloon', 'Freeze', 'Mega Minion', 'Baby Dragon', 'Arrows', 'Tombstone', 'Lightning'];
    }
    if (lower.contains('lavaloon') || (lower.contains('lava hound') && lower.contains('balloon'))) {
      return const ['Lava Hound', 'Balloon', 'Tombstone', 'Mega Minion', 'Baby Dragon', 'Arrows', 'Barbarians', 'Lightning'];
    }

    // Golem variants — check Electro Dragon variant first
    if (lower.contains('golem') && lower.contains('electro dragon')) {
      return const ['Golem', 'Night Witch', 'Electro Dragon', 'Mega Minion', 'Lightning', 'Tornado', 'Baby Dragon', 'Lumberjack'];
    }
    if (lower.contains('golem')) {
      return const ['Golem', 'Night Witch', 'Baby Dragon', 'Mega Minion', 'Lightning', 'Tornado', 'Skeleton Army', 'Lumberjack'];
    }

    // Hog Rider cycle
    if (lower.contains('hog 2.6') || lower.contains('hog 2.9') || lower.contains('hog rider 2')) {
      return const ['Hog Rider', 'Musketeer', 'Valkyrie', 'Cannon', 'Fireball', 'Zap', 'Ice Golem', 'Ice Spirit'];
    }

    // Miner + Poison control
    if (lower.contains('miner') && (lower.contains('poison') || lower.contains('control'))) {
      return const ['Miner', 'Poison', 'Mega Minion', 'Tornado', 'Knight', 'Goblin Gang', 'Baby Dragon', 'Barbarian Barrel'];
    }

    // Graveyard
    if (lower.contains('graveyard')) {
      return const ['Graveyard', 'Poison', 'Tornado', 'Lumberjack', 'Mega Minion', 'Skeleton Army', 'Knight', 'Barbarian Barrel'];
    }

    // Bridge Spam (PEKKA + Battle Ram)
    if (lower.contains('bridge spam') || (lower.contains('pekka') && lower.contains('battle ram'))) {
      return const ['PEKKA', 'Battle Ram', 'Bandit', 'Electro Wizard', 'Dark Prince', 'Royal Ghost', 'Zap', 'Poison'];
    }

    // X-Bow Siege
    if (lower.contains('x-bow') || lower.contains('xbow')) {
      return const ['X-Bow', 'Tesla', 'Ice Golem', 'Skeletons', 'Archers', 'The Log', 'Fireball', 'Knight'];
    }

    // Mortar Cycle
    if (lower.contains('mortar')) {
      return const ['Mortar', 'Rocket', 'Ice Golem', 'Skeletons', 'Arrows', 'Ice Spirit', 'Knight', 'The Log'];
    }

    // Balloon + Freeze (non-LavaLoon)
    if (lower.contains('balloon') && lower.contains('freeze')) {
      return const ['Balloon', 'Freeze', 'Baby Dragon', 'Arrows', 'Barbarians', 'Lumberjack', 'Tombstone', 'Lightning'];
    }

    return null;
  }

  /// Finds a guide by arena name using case-insensitive partial matching.
  /// Falls back to the highest-level guide for any unknown arena names so
  /// the app never shows "arena not found" for new or event arenas.
  static ArenaGuide? findByName(String name) {
    final lower = name.toLowerCase().trim();
    for (final guide in all) {
      if (lower == guide.arenaName.toLowerCase() ||
          lower.contains(guide.arenaName.toLowerCase()) ||
          guide.arenaName.toLowerCase().contains(lower)) {
        return guide;
      }
    }
    // Fallback patterns for event/challenge arenas and future arena names
    if (lower.contains('mosh pit') || lower.contains('moshpit')) {
      return all.firstWhere((g) => g.arenaName == 'Ultimate Mosh Pit',
          orElse: () => all.last);
    }
    if (lower.contains('champion') || lower.contains('master') ||
        lower.contains('legendary') || lower.contains('challenger')) {
      return all.last;
    }
    // Generic fallback: return the highest-level guide
    return all.last;
  }

  static const List<ArenaGuide> all = [
    ArenaGuide(
      arenaName: 'Training Camp',
      trophyRange: 'Tutorial',
      overview:
          'Arena de treinamento com bots. Não há troféus em jogo — o objetivo é aprender as mecânicas básicas do jogo.',
      commonDecks: [
        'Qualquer combinação de cartas iniciais',
        'Giant + Archers básico',
      ],
      strategies: [
        'Pratique gerenciar o elixir — nunca deixe acumular além de 10',
        'Aprenda a defender antes de atacar',
        'Teste o range e o timing de deploy de cada carta',
      ],
      winTips: [
        'Coloque tanques à frente e suporte atrás deles',
        'Use feitiços para limpar grupos de unidades pequenas',
        'Não jogue todas as cartas ao mesmo tempo',
      ],
      aiContext:
          'Jogador no Training Camp (tutorial). Recomendar deck simples com poucas sinergias para facilitar o aprendizado.',
    ),

    // ── Arena 1 ──
    ArenaGuide(
      arenaName: 'Goblin Stadium',
      trophyRange: '0 – 299 troféus',
      overview:
          'Primeira arena competitiva. Os jogadores ainda estão aprendendo; decks são improvisados e erros básicos são frequentes. Cartas de nível baixo dominam.',
      commonDecks: [
        'Giant + Archers / Goblins',
        'Hog Rider + feitiços simples',
        'Ciclo básico com Knight e Skeletons',
        'Balloon + Minions',
      ],
      strategies: [
        'Mantenha custo médio de elixir abaixo de 4.0 para ter mais jogadas por partida',
        'Defenda e faça contra-ataque com o elixir que sobrou da defesa',
        'Não jogue cartas caras uma após a outra — você ficará sem elixir para defender',
        'Arrows é essencial para limpar Goblins e Skeleton Army',
      ],
      winTips: [
        'Giant no centro-traseiro acumula elixir antes de chegar na ponte — padrão de abertura',
        'Hog Rider + feitiço destrói qualquer torre se o adversário não tiver resposta',
        'Nunca fique com menos de 3 de elixir; sempre reserve para a defesa',
        'Pressione a lane com a torre mais fraca, ou ambas se o oponente errar',
      ],
      aiContext:
          'Goblin Stadium (0-299 troféus): meta casual. Priorizar sinergia básica, custo médio de elixir baixo e win condition simples como Giant ou Hog Rider.',
    ),

    // ── Arena 2 ──
    ArenaGuide(
      arenaName: 'Bone Pit',
      trophyRange: '300 – 599 troféus',
      overview:
          'Os jogadores começam a entender papéis de cartas. Giant e Hog Rider dominam. O uso de feitiços ainda é inconsistente.',
      commonDecks: [
        'Giant + Musketeer',
        'Hog Rider + Goblin Barrel',
        'Balloon + Minions',
        'Knight + Archers ciclo',
      ],
      strategies: [
        'Giant no centro-traseiro é o push mais comum — prepare defesa anti-tanque',
        'Hog Rider contra torre sem suporte fecha o jogo rapidamente',
        'Use Mini PEKKA ou Valkyrie para matar o Giant adversário',
        'Mantenha defesa aérea (Musketeer, Mega Minion) sempre disponível para Balloon',
      ],
      winTips: [
        'Contra Giant: coloque defesa na lateral para separar o suporte',
        'Hog Rider funciona melhor quando o adversário acabou de gastar elixir',
        'Balloon + Minions + Arrows: combo letal se o adversário não tiver defesa aérea',
        'Pressione a lane oposta logo após defender um push grande',
      ],
      aiContext:
          'Bone Pit (300-599 troféus): Giant e Hog Rider dominam. Deck precisa de resposta a tanques (Mini PEKKA, Valkyrie) e cobertura aérea anti-Balloon.',
    ),

    // ── Arena 3 ──
    ArenaGuide(
      arenaName: 'Barbarian Bowl',
      trophyRange: '600 – 999 troféus',
      overview:
          'Meta começa a se diversificar. Barbarians são populares. PEKKA aparece com mais frequência e o uso estratégico de feitiços fica essencial.',
      commonDecks: [
        'Giant + PEKKA',
        'Hog Rider 2.9 Ciclo',
        'Balloon + Freeze',
        'Three Musketeers',
        'Barbarians + feitiços',
      ],
      strategies: [
        'Barbarians são excelentes para matar tanques — tenha Fireball para limpar grupos',
        'PEKKA precisa de suporte de feitiço ou unidades menores para protegê-la',
        'Double lane pressure força o adversário a dividir elixir',
        'Não jogue tudo em um único push — reserve elixir para a defesa',
      ],
      winTips: [
        'Fireball + Zap elimina Barbarians e Three Musketeers — carregue sempre esse combo',
        'Contra Balloon: mantenha Arrows e unidade aérea sempre disponíveis',
        'PEKKA funciona melhor no contra-ataque; deixe o oponente atacar primeiro',
        'Use o double elixir para pressionar com pushes duplos nas duas lanes',
      ],
      aiContext:
          'Barbarian Bowl (600-999 troféus): PEKKA, Giant e Barbarians são ameaças. Feitiços de área (Fireball, Arrows) e defesa aérea são obrigatórios no deck.',
    ),

    // ── Arena 4 ──
    ArenaGuide(
      arenaName: "PEKKA's Playhouse",
      trophyRange: '1.000 – 1.299 troféus',
      overview:
          'Meta mais competitivo com PEKKA dominando. Spell cycling começa a ser relevante. Decks de Beatdown com tanques pesados são o padrão.',
      commonDecks: [
        'PEKKA + Witch',
        'Giant Beatdown + Night Witch',
        'Hog Rider 2.9 Ciclo',
        'Balloon + Freeze',
        'Royal Giant + Musketeers',
      ],
      strategies: [
        'PEKKA exige suporte — sozinha ela é lenta e vulnerável a swarms',
        'Hog Rider ciclo mantém pressão constante gastando pouco elixir',
        'Balloon + Freeze é devastador se o adversário não tiver defesa aérea',
        'Identifique o deck adversário nas primeiras trocas antes de fazer push grande',
      ],
      winTips: [
        'Contra PEKKA: use Inferno Tower ou Inferno Dragon para derreter rapidamente',
        'Royal Giant com Musketeers: Fireball tira as Musketeers e danifica a torre ao mesmo tempo',
        'Spell cycling (Fireball + feitiço secundário) acumula dano direto decisivo',
        'No double elixir, pressione as duas lanes para não dar resposta ao adversário',
      ],
      aiContext:
          "PEKKA's Playhouse (1.000-1.299 troféus): PEKKA e tanques pesados dominam. Inferno Tower e spell cycling começam a ser relevantes. Deck precisa de suporte anti-swarm.",
    ),

    // ── Arena 5 ──
    ArenaGuide(
      arenaName: 'Spell Valley',
      trophyRange: '1.300 – 1.599 troféus',
      overview:
          'Feitiços ganham importância estratégica. Balloon Freeze, Giant Beatdown e Hog Rider são os arquétipos dominantes. Gerenciamento de elixir fica crítico.',
      commonDecks: [
        'Balloon + Freeze',
        'Giant + Night Witch + Lumberjack',
        'Hog Rider + Goblin Barrel',
        'Miner + Minion Horde ciclo',
        'Golem (começa a aparecer)',
      ],
      strategies: [
        'Spell damage acumula rápido — use Fireball diretamente na torre quando for seguro',
        'Balloon é a maior ameaça desta arena — defesa aérea em todo deck é obrigatória',
        'Freeze está no meta — nunca gaste toda sua defesa de uma vez contra um push',
        'Miner é excelente para chip damage enquanto você defende a pressão adversária',
      ],
      winTips: [
        'Balloon: coloque com suporte (Freeze ou tanque na frente) para maximizar dano na torre',
        'Contra Freeze: mantenha suas unidades defensivas separadas para não serem todas congeladas',
        'Hog + Goblin Barrel: pressione as duas lanes ao mesmo tempo para confundir a defesa',
        'Timing de Freeze: use só quando o Balloon chegar próximo à torre, não antes',
      ],
      aiContext:
          'Spell Valley (1.300-1.599 troféus): Balloon Freeze e Hog Ciclo dominam. Defesa aérea obrigatória. Feitiços com dano direto na torre (Fireball, Rocket) são muito eficazes.',
    ),

    // ── Arena 6 ──
    ArenaGuide(
      arenaName: "Builder's Workshop",
      trophyRange: '1.600 – 1.999 troféus',
      overview:
          'Meta diversificado e competitivo. Golem Beatdown, LavaLoon e Hog 2.6 Ciclo são os decks mais fortes. Os jogadores começam a ler o deck adversário.',
      commonDecks: [
        'Golem + Night Witch + Lumberjack',
        'LavaLoon (Lava Hound + Balloon)',
        'Hog 2.6 Ciclo (Hog + Valkyrie + Musketeer)',
        'Miner Poison Control',
        'Electro Giant + suporte',
      ],
      strategies: [
        'Golem no centro-traseiro: prepare defesa imediatamente ao ver essa jogada',
        'LavaLoon: Lava Hound na frente absorve defesa aérea para o Balloon passar',
        'Hog 2.6: cicle rápido e sempre tenha o Hog disponível para pressionar',
        'Leia o deck adversário e não jogue seu win condition em resposta ao deles',
      ],
      winTips: [
        'Contra Golem: Inferno Tower + Tornado para separar suporte é a defesa padrão',
        'LavaLoon: Musketeer, Mega Minion ou Executioner são as melhores defesas aéreas',
        'Hog 2.6: Fireball prediction no Musketeers ou Witch adversário é a jogada mais importante',
        'No double elixir, Golem + Night Witch + Lumberjack = push quase irresistível',
      ],
      aiContext:
          "Builder's Workshop (1.600-1.999 troféus): Golem, LavaLoon e Hog 2.6 Ciclo são os pilares. Inferno Tower é crucial. Sinergia entre cartas é mais importante que nível individual.",
    ),

    // ── Arena 7 ──
    ArenaGuide(
      arenaName: 'Royal Arena',
      trophyRange: '2.000 – 2.299 troféus',
      overview:
          'Jogadores mais experientes com decks otimizados. Mega Knight, Royal Giant e Miner Control aparecem. Erros de timing são explorados imediatamente.',
      commonDecks: [
        'Mega Knight + suporte',
        'Royal Giant + Musketeers',
        'Miner + Poison Control',
        'Golem Beatdown',
        'Three Musketeers + Elixir Collector',
      ],
      strategies: [
        'Mega Knight é excelente para contra-ataque — deixe o oponente atacar primeiro',
        'Royal Giant: mantenha pressão constante para manter o adversário na defesa',
        'Three Musketeers: split no centro-traseiro para dividir o elixir adversário',
        'Poison + Miner é um combo de chip damage lento mas devastador',
      ],
      winTips: [
        'Contra Mega Knight: Inferno Dragon, PEKKA ou Tesla resolvem',
        'Contra Three Musketeers: Lightning ou Rocket em duas Musketeers ao mesmo tempo',
        'Royal Giant tem range longo: Inferno Tower ou Cannon atrás da torre é a defesa ideal',
        'Miner + Goblin Barrel no double elixir: pressione as duas lanes simultaneamente',
      ],
      aiContext:
          'Royal Arena (2.000-2.299 troféus): Mega Knight, Royal Giant e Miner Control dominam. Defesa reativa e contra-ataque são a estratégia padrão.',
    ),

    // ── Arena 8 ──
    ArenaGuide(
      arenaName: 'Frozen Peak',
      trophyRange: '2.300 – 2.599 troféus',
      overview:
          'Nível de jogo elevado. PEKKA Bridge Spam, Hog 2.6 e Golem são os decks mais temidos. Gerenciamento de elixir precisa ser quase perfeito.',
      commonDecks: [
        'PEKKA Bridge Spam (PEKKA + Battle Ram + Bandit)',
        'Hog 2.6 Ciclo',
        'Golem + Night Witch',
        'Miner + Poison Control',
        'X-Bow Siege',
      ],
      strategies: [
        'Bridge Spam: pressione antes do oponente se organizar — velocidade é tudo',
        'X-Bow: coloque sempre com defesa (Ice Golem, Skeletons) na frente',
        'Hog 2.6: cicle rapidamente e faça prediction Fireball nas defesas adversárias',
        'Identifique se o adversário usa ciclo rápido ou lento e adapte a pressão',
      ],
      winTips: [
        'Contra Bridge Spam: Tornado + splash (Witch, Wizard) para agrupar as unidades',
        'Contra X-Bow: pressione a lane oposta imediatamente para forçar a troca',
        'Hog 2.6: Fireball prediction no Musketeer ou Witch adversário é a jogada de skill número 1',
        'No overtime, priorize defender torres com pouca vida antes de atacar',
      ],
      aiContext:
          'Frozen Peak (2.300-2.599 troféus): Bridge Spam, X-Bow Siege e Hog Ciclo exigem alta precisão. Timing de spell e elixir é crítico. Ciclo rápido é vantagem real.',
    ),

    // ── Arena 9 ──
    ArenaGuide(
      arenaName: 'Jungle Arena',
      trophyRange: '2.600 – 2.999 troféus',
      overview:
          'Meta altamente competitivo. Os arquétipos são bem definidos e os jogadores conhecem seus matchups. Decks sem resposta ao meta perdem sistematicamente.',
      commonDecks: [
        'LavaLoon (Lava Hound + Balloon + Invisibility Spell)',
        'Miner + Poison Control',
        'Hog 2.6 / Hog 2.9 Ciclo',
        'Golem Night Witch',
        'Graveyard + Poison',
      ],
      strategies: [
        'LavaLoon: Lava Hound absorve a defesa anti-aérea enquanto o Balloon avança',
        'Graveyard: use Poison para limpar a área antes de jogar o Graveyard',
        'Miner Control: chip contínuo enquanto você controla a lane com feitiços',
        'Saiba seus matchups — Controle bate Beatdown, Ciclo bate Controle',
      ],
      winTips: [
        'LavaLoon: nunca jogue Lava Hound sem elixir reserva para o Balloon',
        'Contra LavaLoon: Electro Dragon + Mega Minion ou Musketeer são as melhores defesas',
        'Graveyard no double elixir com Poison = dano massivo; antecipe e defenda com Skeletons',
        'Miner Control: force o adversário a desperdiçar feitiços antes de aplicar Poison',
      ],
      aiContext:
          'Jungle Arena (2.600-2.999 troféus): LavaLoon, Graveyard e Miner Control são os pilares. Defesa aérea obrigatória. Conhecimento de matchups é essencial.',
    ),

    // ── Arena 10 ──
    ArenaGuide(
      arenaName: 'Hog Mountain',
      trophyRange: '3.000 – 3.299 troféus',
      overview:
          'Alto nível de competição. Jogadores entendem matchups, timing e prediction shots. Decks sem sinergias claras perdem consistentemente.',
      commonDecks: [
        'Hog 2.6 Ciclo (meta dominante)',
        'Golem + Night Witch + Electro Dragon',
        'LavaLoon',
        'Miner + Poison Control',
        'Ebarbs + Ram Rider',
      ],
      strategies: [
        'Hog 2.6 é o deck mais consistente — cicle rápido e aplique pressão constante',
        'Prediction Fireball em posição de Musketeer ou Witch adversária é decisivo',
        'Golem push no double elixir com dois suportes fecha a maioria dos jogos',
        'Ebarbs: jogue na bridge quando o oponente acabou de usar uma carta cara',
      ],
      winTips: [
        'Contra Hog 2.6: sempre tenha Cannon ou Inferno Tower disponível e cicle em resposta',
        'Contra Golem: Inferno Tower + Tornado para afastar suporte',
        'Contra Ebarbs: Lightning ou Fireball — sem isso, eles derrubam a torre',
        'No overtime, pressione com o win condition mais rápido disponível no seu ciclo',
      ],
      aiContext:
          'Hog Mountain (3.000-3.299 troféus): Hog 2.6 é o deck mais jogado. Prediction spells são comuns. Deck precisa de resposta clara a Hog Rider e tanques pesados.',
    ),

    // ── Arena 11 ──
    ArenaGuide(
      arenaName: 'Electro Valley',
      trophyRange: '3.300 – 3.699 troféus',
      overview:
          'Jogadores de nível alto que dominam as mecânicas. Electro Giant, Hog 2.6 e Miner Poison são o novo meta. Erros custam troféus rapidamente.',
      commonDecks: [
        'Electro Giant + Barbarian Barrel + Tornado',
        'Hog 2.6 Ciclo',
        'Miner + Poison Control',
        'Mortar Ciclo',
        'Royal Recruits + Tornado',
      ],
      strategies: [
        'Electro Giant: posicione na center-back para acumular elixir antes de avançar',
        'Mortar Ciclo: mantenha pressão constante de Mortar e cicle suportes rapidamente',
        'Royal Recruits: split no centro com feitiço de suporte divide a atenção adversária',
        'Miner: faça prediction shots na posição de defesas adversárias',
      ],
      winTips: [
        'Contra E-Giant: PEKKA ou Inferno Tower + Tornado são as melhores respostas',
        'Mortar Ciclo: pressione a lane oposta ao Mortar para criar dilema de defesa',
        'Hog 2.6: não jogue cartas fora do core do ciclo — velocidade é tudo',
        'Prediction Rocket ou Fireball na torre + unidade adversária é frequentemente decisivo',
      ],
      aiContext:
          'Electro Valley (3.300-3.699 troféus): Electro Giant, Mortar Ciclo e Miner Poison dominam. Deck precisa de sinergias claras e respostas a múltiplos arquétipos.',
    ),

    // ── Spooky Town ──
    ArenaGuide(
      arenaName: 'Spooky Town',
      trophyRange: '3.700 – 4.299 troféus',
      overview:
          'Borda do nível competitivo mais alto. Jogadores refinados exploram cada erro. Decks fora do meta são fortemente punidos.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'Miner + Poison Control',
        'LavaLoon',
        'Golem + Night Witch + Electro Dragon',
        'Graveyard + Poison',
      ],
      strategies: [
        'Ler o deck adversário é obrigatório — identifique nas primeiras 4 cartas jogadas',
        'Nunca jogue seu win condition sem elixir de sobra para suporte',
        'Chip damage de feitiço na torre ao longo da partida acumula 300–500 de dano',
        'No double elixir, faça push duplo apenas com vantagem de elixir garantida',
      ],
      winTips: [
        'Graveyard: use sempre com Poison para limpar as unidades defensivas adversárias',
        'Contra LavaLoon: tenha Electro Dragon ou Mega Minion sempre disponível',
        'Miner + feitiço = chip damage seguro sem arriscar uma torre',
        'No overtime, defenda a torre mais fraca e aplique pressão leve na outra lane',
      ],
      aiContext:
          'Spooky Town (3.700-4.299 troféus): meta de alto nível com Graveyard, LavaLoon e Miner Poison. Leitura de deck e chip damage com feitiços são estratégias dominantes.',
    ),

    // ── Rascal's Hideout ──
    ArenaGuide(
      arenaName: "Rascal's Hideout",
      trophyRange: '4.300 – 4.999 troféus',
      overview:
          'Próximo ao topo competitivo. Apenas decks otimizados sobrevivem. O meta é definido por poucos arquétipos dominantes e a execução precisa ser impecável.',
      commonDecks: [
        'Hog 2.6 Ciclo (meta mais forte)',
        'Miner + Poison Control',
        'LavaLoon + Freeze',
        'Golem Night Witch',
        'X-Bow Siege',
      ],
      strategies: [
        'Hog 2.6: mantenha o core do ciclo (Hog, defesa, Musketeer, ciclo) intocado',
        'X-Bow: nunca coloque no início sem defesa suficiente na frente',
        'LavaLoon: treine o timing de Balloon após o Lava Hound absorver as defesas',
        'Miner Control: alterne Miner e Goblin Barrel para nunca deixar o adversário respirar',
      ],
      winTips: [
        'Um erro de timing nesta arena custa a partida — jogue devagar com vantagem',
        'Rocket cycling na torre é uma vitória lenta mas consistente contra decks defensivos',
        'Contra X-Bow: pressione a lane oposta com ciclo rápido para forçar reposicionamento',
        'LavaLoon no double elixir: Lava Hound + Balloon + Freeze é push quase irresistível',
      ],
      aiContext:
          "Rascal's Hideout (4.300-4.999 troféus): meta de topo com Hog 2.6, LavaLoon e Miner Control. Decks precisam ser otimizados para matchups específicos. Erros de elixir são fatais.",
    ),

    // ── Serenity Peak ──
    ArenaGuide(
      arenaName: 'Serenity Peak',
      trophyRange: '5.000 – 5.499 troféus',
      overview:
          'Topo do jogo fora das ligas. Os melhores jogadores com decks maximizados. O meta é ultra-refinado e muda com cada atualização.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon + Freeze',
        'Miner + Poison Control',
        'Bridge Spam (PEKKA + Battle Ram)',
        'Golem Night Witch',
      ],
      strategies: [
        'Domine um deck completamente — especialização bate generalização neste nível',
        'Saiba seus matchups de cor: favorável, desfavorável, neutro',
        'Adapte micro-decisões ao estilo de jogo adversário revelado no ciclo 1',
        'Spell cycling correto termina partidas mesmo contra torres com HP cheio',
      ],
      winTips: [
        'Prediction perfeita de feitiços decide até 30% das partidas neste nível',
        'Nunca deixe o adversário ter vantagem de elixir por mais de 2 cartas',
        'Chip damage consistente é a forma mais segura de vencer — não arrisque',
        'No overtime, jogue defensivamente e espere o adversário errar',
      ],
      aiContext:
          'Serenity Peak (5.000-5.499 troféus): elite com decks maximizados. Especialização em um arquétipo e domínio completo de matchups são obrigatórios.',
    ),

    // ── Legendary Arena ──
    // ── Glacier Peak (Arena 15 — adicionada em 2024) ──
    ArenaGuide(
      arenaName: 'Glacial Peak',
      trophyRange: '5.500 – 5.999 troféus',
      overview:
          'Arena intermediária de alto nível, entre Serenity Peak e Legendary. Jogadores refinados com decks próximos do meta perfeito.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon',
        'Miner + Poison Control',
        'Golem Beatdown',
        'Bridge Spam',
      ],
      strategies: [
        'Execute seu arquétipo com consistência — inovar neste nível é arriscado',
        'Spell cycling eficiente pode decidir partidas empatadas',
        'Leia o deck adversário e identifique a carta defensiva chave',
        'No double elixir, priorize o push mais rápido do seu ciclo',
      ],
      winTips: [
        'Nesta arena, a melhor jogada é geralmente a mais segura, não a mais criativa',
        'Chip damage acumulado com Miner ou feitiços decide jogos empatados',
        'Defenda com o mínimo de elixir para maximizar o contra-ataque',
        'No overtime, uma torre é suficiente — jogue no relógio se necessário',
      ],
      aiContext:
          'Glacial Peak (5.500-5.999 troféus): arena de transição para o topo. Decks refinados com execução consistente são obrigatórios.',
    ),

    // ── Tournament Arena (aparecer em batalhas de torneio) ──
    ArenaGuide(
      arenaName: 'Tournament',
      trophyRange: 'Torneios',
      overview:
          'Arena usada em torneios clássicos e events especiais. As regras de torneio limitam o nível das cartas ao máximo de torneio, igualando todos os jogadores.',
      commonDecks: [
        'Hog 2.6 Ciclo (meta de torneio)',
        'LavaLoon',
        'Golem Night Witch',
        'Miner Poison',
        'Bridge Spam',
      ],
      strategies: [
        'No torneio, todas as cartas ficam no mesmo nível — skill e deck knowledge são os únicos diferenciais',
        'Os decks meta de torneio são os mesmos do ladder de topo — use os mais consistentes',
        'Sem vantagem de nível, a sinergia do deck é ainda mais crítica',
        'Gerencie sua energia mental — torneios são longas sessões de alta concentração',
      ],
      winTips: [
        'Estude o meta de torneio antes de cada evento — ele pode diferir do ladder',
        'Consistência bate criatividade em torneios de eliminação',
        'Faça boas trocas: vencer sem usar muito elixir preserva seu ritmo',
        'Nos tie-breaks, jogue no relógio — a pressão aumenta nos últimos 60 segundos',
      ],
      aiContext:
          'Torneio (Tournament): ambiente competitivo com cartas niveladas. Deck skill e execução são os únicos fatores. Recomendar decks tier-1 do meta de torneio.',
    ),

    ArenaGuide(
      arenaName: 'Legendary Arena',
      trophyRange: '4.000+ troféus',
      overview:
          'Arena lendária. Jogadores experientes com decks bem construídos. O meta é diversificado mas com arquétipos dominantes claros.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon',
        'Miner + Poison Control',
        'Golem Beatdown',
        'Graveyard + Poison',
        'Bridge Spam',
      ],
      strategies: [
        'Estude o meta atual — os decks top mudam a cada atualização',
        'Domine um único arquétipo em vez de jogar vários decks mediocres',
        'Elixir management perfeito: nunca gaste mais do que pode defender',
        'Acompanhe replays dos melhores jogadores do seu arquétipo',
      ],
      winTips: [
        'Prediction spells são comuns — antecipe a posição das defesas adversárias',
        'No overtime, prefira empate a arriscar troféus desnecessariamente',
        'Identifique o win condition adversário e bloqueie-o antes de tudo',
        'Use cada partida para treinar uma tomada de decisão específica',
      ],
      aiContext:
          'Legendary Arena (4.000+ troféus): jogadores experientes com decks refinados. Meta diversificado mas com arquétipos tier-1 dominando. Sinergia de deck é crítica.',
    ),

    // ── Leagues ──
    ArenaGuide(
      arenaName: 'Challenger I',
      trophyRange: '5.000 – 5.299 troféus',
      overview:
          'Primeiro nível de liga competitiva. Jogadores altamente habilidosos com decks otimizados para o meta atual.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'Miner + Poison Control',
        'LavaLoon',
        'Golem Beatdown',
        'Mortar / X-Bow Siege',
      ],
      strategies: [
        'Domine seu arquétipo e conheça todos os seus matchups',
        'Chip damage de feitiço acumulado é frequentemente o fator decisivo',
        'Leia o deck adversário e adapte a estratégia no ciclo 2',
        'Últimos 60 segundos decidem jogos equilibrados — pressione no clock final',
      ],
      winTips: [
        'Prediction Fireball ou Rocket mata unidade de suporte e danifica a torre ao mesmo tempo',
        'Nunca jogue seu win condition contra elixir cheio do adversário',
        'Defenda com o mínimo de elixir possível para ter mais recursos no contra-ataque',
        'Identifique a carta defensiva chave do oponente e force-o a usá-la antes do push',
      ],
      aiContext:
          'Challenger I (5.000-5.299 troféus): liga competitiva com meta refinado. Decks tier-1 e execução consistente são obrigatórios.',
    ),

    ArenaGuide(
      arenaName: 'Challenger II',
      trophyRange: '5.300 – 5.599 troféus',
      overview:
          'Competição intensa. Os jogadores exploram cada vantagem de elixir. Metade dos decks usados são os mesmos top 5 do meta.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'Miner + Poison',
        'LavaLoon',
        'Bridge Spam',
        'Graveyard + Poison',
      ],
      strategies: [
        'Ciclo de cartas é fundamental — saiba exatamente quantas cartas faltam para o win condition',
        'Forçar o adversário a defender as duas lanes ao mesmo tempo é a estratégia dominante',
        'Spell cycling na torre quando a partida está empatada ganha jogos',
        'Identifique se o adversário tem resposta ao seu win condition e jogue de acordo',
      ],
      winTips: [
        'Double lane pressure no double elixir separa jogadores bons dos ótimos',
        'Graveyard + Poison: aplique o combo quando o adversário ficar sem feitiço',
        'LavaLoon: treine o timing de Balloon para cair na torre logo após Lava Hound morrer',
        'Hog 2.6: Fireball prediction no Musketeer/Tesla adversária é a jogada de habilidade número 1',
      ],
      aiContext:
          'Challenger II (5.300-5.599 troféus): spell cycling e double lane pressure são estratégias dominantes. Decks precisam ter rotação defensiva rápida.',
    ),

    ArenaGuide(
      arenaName: 'Challenger III',
      trophyRange: '5.600 – 5.899 troféus',
      overview:
          'Topo da categoria Challenger. Jogadores entendem profundamente o meta e executam suas estratégias quase sem erros.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'Miner + Poison',
        'LavaLoon + Freeze',
        'Golem Night Witch',
        'X-Bow Siege Ciclo',
      ],
      strategies: [
        'Ler o ciclo adversário é tão importante quanto executar o seu próprio',
        'Sacrifique um push menor para garantir vantagem de elixir no push decisivo',
        'Conheça o timing exato de deploy de cada combo do seu deck',
        'Pressão de chip constante com Miner ou feitiços acumula dano que decide a partida',
      ],
      winTips: [
        'Saiba quando aceitar perder uma torre para ganhar a partida (troca de torres)',
        'X-Bow + Ice Golem + Tesla é quase impenetrável com timing correto',
        'Contra Golem: nunca enfrente o push direto — defenda na lateral com Tornado',
        'No overtime, um erro de elixir = torre perdida neste nível de precisão',
      ],
      aiContext:
          'Challenger III (5.600-5.899 troféus): elite dos Challengers. Precisão no ciclo e leitura do ciclo adversário são as principais habilidades diferenciadoras.',
    ),

    ArenaGuide(
      arenaName: 'Master I',
      trophyRange: '5.900 – 6.199 troféus',
      overview:
          'Liga Master. Jogadores de nível mundial com decks no nível máximo e execução refinada.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon',
        'Miner + Poison Control',
        'Golem Beatdown',
        'Bridge Spam PEKKA',
      ],
      strategies: [
        'Cada carta jogada deve ter um propósito claro: ataque, defesa ou ciclo',
        'Matchup knowledge: saiba qual carta bate qual no meta atual',
        'Gerencie o ciclo adversário — conte mentalmente o que ele já usou',
        'Ajuste sua estratégia no ciclo 2 com base no que o adversário revelou',
      ],
      winTips: [
        'Fazer o adversário revelar o win condition antes de você é uma vantagem enorme',
        'Contra Bridge Spam: defenda na sua side com mínimo de cartas e contra-ataque imediato',
        'LavaLoon: o timing do Balloon após Lava Hound morrer decide o jogo',
        'Rocket cycling garante vitória em 3-4 ciclos se a torre estiver com pouca vida',
      ],
      aiContext:
          'Master I (5.900-6.199 troféus): liga Master com execução de nível mundial. Matchup knowledge e leitura do ciclo adversário são obrigatórios.',
    ),

    ArenaGuide(
      arenaName: 'Master II',
      trophyRange: '6.200 – 6.499 troféus',
      overview:
          'Nível de torneio. Cada detalhe importa: posicionamento, timing e prediction são parte do jogo padrão.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'Miner Control',
        'LavaLoon',
        'Golem Night Witch',
        'Mortar Ciclo',
      ],
      strategies: [
        'Posicionamento de cartas é ciência: centralize tanques, lateralize win conditions de ciclo',
        'Prediction shots com Rocket ou Fireball valem mais do que a maioria das jogadas defensivas',
        'Saiba sua rotação de defesa aérea — quando você usa uma, qual é a próxima no ciclo?',
        'Não reaja impulsivamente a todo push adversário — avalie o elixir antes de defender',
      ],
      winTips: [
        'Uma vitória de torre no ciclo 1 geralmente determina o vencedor da partida',
        'Contra Golem: Inferno Tower + Tornado para afastar Baby Dragon e Night Witch',
        'Miner + Goblin Barrel no double elixir: pressione juntos para forçar dois pontos de defesa',
        'Timing de Freeze: espere o adversário colocar as defesas antes de congelar',
      ],
      aiContext:
          'Master II (6.200-6.499 troféus): nível de torneio com posicionamento e prediction como jogadas padrão. Deck precisa de rotação defensiva sólida.',
    ),

    ArenaGuide(
      arenaName: 'Master III',
      trophyRange: '6.500 – 6.799 troféus',
      overview:
          'Top 0.1% de jogadores. O jogo é levado ao limite das mecânicas. Cada elixir desperdiçado é uma ameaça de derrota.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon + Freeze',
        'Miner + Poison',
        'Golem + Night Witch',
        'Bridge Spam',
      ],
      strategies: [
        'Zero desperdício de elixir: toda carta deve servir a ataque ou defesa naquele instante',
        'Pressione apenas com vantagem de elixir confirmada',
        'Conheça os combos do adversário e bloqueie-os no nascimento',
        'Use o temporizador da partida para calcular o push decisivo',
      ],
      winTips: [
        'Defesa mínima para máximo contra-ataque é a fórmula de ouro',
        'Rocket + Fireball ou Lightning destrói qualquer torre em 4-5 ciclos',
        'Freeze no momento exato (quando torre atirando) multiplica o dano exponencialmente',
        'No overtime, jogue defensivamente e espere o adversário errar',
      ],
      aiContext:
          'Master III (6.500-6.799 troféus): top competitivo global. Zero desperdício de elixir. Decks sem sinergia clara ou win condition consistente não sobrevivem.',
    ),

    ArenaGuide(
      arenaName: 'Champion',
      trophyRange: '6.800 – 7.099 troféus',
      overview:
          'Liga Champion. Menos de 0.1% dos jogadores chegam aqui. O meta é dominado pelos decks mais refinados do mundo.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon',
        'Miner + Poison',
        'Golem Beatdown',
        'X-Bow Siege',
      ],
      strategies: [
        'Domine completamente 1 deck — especialização bate generalização neste nível',
        'Saiba de cor cada matchup: favorável, desfavorável e como jogar os neutros',
        'Adapte micro-decisões ao estilo adversário identificado no ciclo 1',
        'Use replays para identificar padrões repetitivos no seu próprio jogo',
      ],
      winTips: [
        'Prediction perfeita de feitiços decide até 30% das partidas neste nível',
        'Identifique se o adversário é agressivo ou passivo e ajuste sua abertura',
        'Nunca deixe o adversário acumular +2 de vantagem de elixir por mais de 3 segundos',
        'Chip damage consistente garante vitória — não arrisque jogadas desnecessárias',
      ],
      aiContext:
          'Champion (6.800-7.099 troféus): liga de elite global. Especialização em um único arquétipo e domínio completo dos matchups são obrigatórios.',
    ),

    ArenaGuide(
      arenaName: 'Grand Champion',
      trophyRange: '7.100 – 7.399 troféus',
      overview:
          'Topo absoluto do jogo competitivo. Os melhores jogadores do mundo se encontram aqui. O meta é ultra-refinado.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon + Freeze',
        'Miner + Poison',
        'Bridge Spam',
        'Golem Night Witch',
      ],
      strategies: [
        'A decisão já é tomada antes do deploy — planejamento supera reação',
        'Leia o ciclo adversário e force-o a defender com suas cartas mais caras',
        'Micro-positioning é crítico: centímetros de posição mudam o resultado',
        'Identifique o padrão de abertura adversário nos primeiros 30 segundos',
      ],
      winTips: [
        'Push com +2 de elixir de vantagem é quase irresistível neste nível',
        'Spell cycling correto termina partidas mesmo contra torres com HP cheio',
        'A vitória vem de execução superior, não de erro adversário — os adversários não erram',
        'Foco total durante toda a partida: distrações custam jogos neste nível de precisão',
      ],
      aiContext:
          'Grand Champion (7.100-7.399 troféus): top mundial. Execução perfeita, leitura de ciclo e micro-posicionamento são o padrão mínimo de jogo.',
    ),

    ArenaGuide(
      arenaName: 'Royal Champion',
      trophyRange: '7.400 – 7.699 troféus',
      overview:
          'Elite mundial. Apenas os 1.000 melhores jogadores alcançam este nível. O meta varia com cada atualização do jogo.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon',
        'Miner + Poison',
        'Golem Night Witch',
        'X-Bow / Mortar Siege',
      ],
      strategies: [
        'Acompanhe o meta semanal — um deck dominante pode mudar em 48 horas após patch',
        'Treine situações específicas: como defender um push com elixir negativo',
        'Cada jogada é calculada com base no ciclo adversário atual, não no instinto',
        'Pressão psicológica: forçar o adversário a pensar antes de jogar é vantagem real',
      ],
      winTips: [
        'Decks de ciclo rápido têm vantagem porque chegam ao win condition mais vezes',
        'Contra Golem: nunca enfrente direto — Tornado + splash na lateral',
        'Nível de carta máximo é obrigatório — desvantagem de nível é desvantagem real',
        'Vitórias 0-1 de torre são mais comuns que 2-0 — cada torre é uma vitória',
      ],
      aiContext:
          'Royal Champion (7.400-7.699 troféus): top 1.000 mundial. Meta ultra-definido. Apenas decks tier-1 com execução impecável sobem consistentemente.',
    ),

    // ── Ultimate Mosh Pit (evento / arena especial) ──
    ArenaGuide(
      arenaName: 'Ultimate Mosh Pit',
      trophyRange: 'Evento especial / alto nível',
      overview:
          'Arena de evento especial do Clash Royale. O meta é dinâmico e pode diferir do ladder padrão. Jogadores de alto nível competem com regras especiais ou formatos alternativos.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon + Freeze',
        'Miner + Poison Control',
        'Bridge Spam PEKKA',
        'Golem Night Witch',
      ],
      strategies: [
        'Adapte seu deck ao formato do evento — as regras podem mudar o meta drasticamente',
        'Ciclo rápido tem vantagem em eventos com elixir acelerado',
        'Decks de controle e feitiços são mais eficientes em tempos de partida reduzidos',
        'Priorize sinergias sobre nível individual das cartas',
      ],
      winTips: [
        'Leia o formato do evento antes de decidir o deck — cada Mosh Pit tem regras únicas',
        'Em eventos com elixir dobrado, decks pesados como Golem ficam ainda mais fortes',
        'Pressão constante nas duas lanes é a estratégia dominante em eventos de alta velocidade',
        'Feitiços de área (Fireball, Lightning) valem mais em eventos com swarms',
      ],
      aiContext:
          'Ultimate Mosh Pit (evento especial): arena de evento com regras possivelmente diferentes do ladder. Recomendar decks versáteis e bem estabelecidos no meta de alto nível.',
    ),

    ArenaGuide(
      arenaName: 'Ultimate Champion',
      trophyRange: '7.700+ troféus',
      overview:
          'Lenda absoluta do Clash Royale. Menos de 500 jogadores no mundo alcançam este nível. O meta é definido POR estes jogadores.',
      commonDecks: [
        'Hog 2.6 Ciclo',
        'LavaLoon + Freeze',
        'Miner + Poison',
        'Bridge Spam PEKKA',
        'Golem Night Witch',
      ],
      strategies: [
        'Inovação é necessária — os adversários conhecem todos os decks meta de cor',
        'Pequenos ajustes no deck (1 carta) mudam completamente um matchup difícil',
        'Consistência mental é tão importante quanto habilidade técnica neste nível',
        'Adapte sua estratégia mid-game com base no que o adversário revelou',
      ],
      winTips: [
        'A diferença entre vitória e derrota é frequentemente uma única carta jogada no timing errado',
        'Estude os TOP 10 globais do seu arquétipo e adapte as jogadas deles',
        'Gerenciar tilting e manter foco em sessões longas é fundamental para subir',
        'No overtime, a paciência vence — espere o momento certo antes de atacar',
      ],
      aiContext:
          'Ultimate Champion (7.700+ troféus): top 500 mundial. Inovação, consistência mental e adaptação mid-game são os diferenciadores reais entre jogadores deste nível.',
    ),
  ];
}

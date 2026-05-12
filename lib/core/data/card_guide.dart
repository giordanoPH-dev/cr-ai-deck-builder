/// Local knowledge base for Clash Royale cards.
/// Contains usage tips, synergies, counters and best decks for ~110 cards.
/// All descriptions are in Portuguese (pt-BR).
library;

enum CardRole {
  winCondition,
  tank,
  miniTank,
  spellHeavy,
  spellLight,
  building,
  airUnit,
  swarm,
  support,
  champion,
  evolution,
}

extension CardRoleLabel on CardRole {
  String get label {
    switch (this) {
      case CardRole.winCondition:
        return 'Condição de Vitória';
      case CardRole.tank:
        return 'Tanque';
      case CardRole.miniTank:
        return 'Mini-Tanque';
      case CardRole.spellHeavy:
        return 'Feitiço Pesado';
      case CardRole.spellLight:
        return 'Feitiço Leve';
      case CardRole.building:
        return 'Construção';
      case CardRole.airUnit:
        return 'Unidade Aérea';
      case CardRole.swarm:
        return 'Enxame/Ciclo';
      case CardRole.support:
        return 'Suporte';
      case CardRole.champion:
        return 'Campeão';
      case CardRole.evolution:
        return 'Evolução';
    }
  }
}

class CardGuideData {
  final String name;
  final CardRole role;
  final String description;
  final List<String> tips;
  final List<String> synergies;
  final List<String> counters;
  final List<String> bestDecks;

  const CardGuideData({
    required this.name,
    required this.role,
    required this.description,
    required this.tips,
    required this.synergies,
    required this.counters,
    required this.bestDecks,
  });
}

abstract class CardGuide {
  static const Map<String, CardGuideData> _data = {
    // ── Win Conditions ────────────────────────────────────────────────────────

    'hog rider': CardGuideData(
      name: 'Hog Rider',
      role: CardRole.winCondition,
      description:
          'Tropa terrestre de alto dano que pula obstáculos e ataca diretamente a torre.',
      tips: [
        'Jogue na ponte para maximizar a distância percorrida até a torre.',
        'Combine com um suporte atrás (Musketeer, Ice Golem) para criar uma push poderosa.',
        'Use após uma defesa bem-sucedida aproveitando o contra-ataque com elixir positivo.',
        'Varie a lane para forçar seu adversário a reagir em ambos os lados.',
      ],
      synergies: ['Ice Golem', 'Musketeer', 'Valkyrie', 'Ice Spirit', 'Fireball'],
      counters: ['Inferno Tower', 'Skeleton Army', 'Mega Knight', 'Tesla'],
      bestDecks: ['Hog Cycle', 'Hog Exnado', 'Double Prince'],
    ),

    'goblin barrel': CardGuideData(
      name: 'Goblin Barrel',
      role: CardRole.winCondition,
      description:
          'Feitiço que lança 3 goblins diretamente na torre adversária — difícil de defender sem o Log.',
      tips: [
        'Varie o posicionamento a cada lançamento: frente, lado, trás da torre.',
        'Espere o adversário gastar o Log ou Arrows antes de jogar o barrel.',
        'Na arena perto da torre, os goblins ficam expostos por menos tempo.',
        'Combine com Archer Queen para forçar dois feitiços ao mesmo tempo.',
      ],
      synergies: ['Princess', 'Dart Goblin', 'Goblin Gang', 'Archer Queen'],
      counters: ['Log', 'Arrows', 'Zap', 'Wizard'],
      bestDecks: ['Log Bait', 'Goblin Barrel Cycle'],
    ),

    'golem': CardGuideData(
      name: 'Golem',
      role: CardRole.winCondition,
      description:
          'O maior tanque do jogo. Absorve dano massivo e ao morrer explode em dois Golemites.',
      tips: [
        'Sempre coloque o Golem na fila atrás da torre do rei com 10 de elixir.',
        'Nunca coloque na ponte — você perde a vantagem de construir elixir atrás.',
        'Combine Night Witch + Baby Dragon atrás para cobertura total aérea e terrestre.',
        'Ligue a habilidade do Monk para proteger o push de feitiços inimigos.',
      ],
      synergies: ['Night Witch', 'Baby Dragon', 'Mega Minion', 'Lumberjack', 'Monk'],
      counters: ['Lightning', 'Tornado', 'Pekka', 'Inferno Tower'],
      bestDecks: ['Golem Beatdown', 'Golem Night Witch'],
    ),

    'giant': CardGuideData(
      name: 'Giant',
      role: CardRole.winCondition,
      description:
          'Tanque versátil e econômico que ataca apenas construções, ideal para proteger suportes.',
      tips: [
        'Coloque na fila na parte traseira para acumular elixir enquanto avança.',
        'Combine com Graveyard para um push letal: Giant absorve o dano enquanto os esqueletos atacam.',
        'Zap ou Electro Spirit são essenciais para resetar o Inferno Tower/Dragon.',
        'Variante Double Prince: Prince + Dark Prince atrás do Giant é devastador.',
      ],
      synergies: ['Graveyard', 'Prince', 'Dark Prince', 'Witch', 'Electro Wizard'],
      counters: ['Pekka', 'Mini Pekka', 'Inferno Tower', 'Tornado'],
      bestDecks: ['Giant Graveyard', 'Giant Double Prince', 'Giant Beatdown'],
    ),

    'balloon': CardGuideData(
      name: 'Balloon',
      role: CardRole.winCondition,
      description:
          'Unidade aérea que causa dano massivo à torre e ao morrer lança uma bomba de tempo.',
      tips: [
        'Combine com Freeze para paralisar defesas enquanto o Balloon golpeia.',
        'No LavaLoon, jogue o Lava Hound primeiro para atrair as defesas anti-ar.',
        'A bomba de morte pode destruir unidades próximas — posicione inimigos perto da torre.',
        'Electro Dragon atrás do Balloon garante proteção aérea e atordoa defensores.',
      ],
      synergies: ['Lava Hound', 'Freeze', 'Mega Minion', 'Minions', 'Electro Dragon'],
      counters: ['Minion Horde', 'Mega Minion', 'Arrows', 'Bats'],
      bestDecks: ['LavaLoon', 'Balloon Freeze', 'Balloon Cycle'],
    ),

    'lava hound': CardGuideData(
      name: 'Lava Hound',
      role: CardRole.winCondition,
      description:
          'O maior tanque aéreo do jogo. Ao morrer libera 6 Lava Pups que continuam atacando.',
      tips: [
        'Sempre jogue na fila atrás da torre do rei com 10 de elixir.',
        'Coloque o Balloon logo atrás do Lava Hound para formar o push LavaLoon.',
        'Use Mega Minion ou Baby Dragon para proteger o push de unidades aéreas inimigas.',
        'O adversário frequentemente gasta muito elixir defendendo — contra-ataque na outra lane.',
      ],
      synergies: ['Balloon', 'Mega Minion', 'Baby Dragon', 'Minions', 'Tombstone'],
      counters: ['Minion Horde', 'Electro Dragon', 'Inferno Dragon', 'Arrows'],
      bestDecks: ['LavaLoon', 'LavaLoon Freeze'],
    ),

    'x-bow': CardGuideData(
      name: 'X-Bow',
      role: CardRole.winCondition,
      description:
          'Construção de longo alcance que ataca a torre inimiga diretamente do seu lado do mapa.',
      tips: [
        'Posicione na beira do rio no lado direito ou esquerdo para maximizar cobertura.',
        'Tesla logo atrás do X-Bow é OBRIGATÓRIO para protegê-lo de tropas terrestres.',
        'Jogue defensivamente: X-Bow defende e ataca ao mesmo tempo.',
        'Rocket ou Fireball para limpar unidades que tentem destruir o X-Bow.',
      ],
      synergies: ['Tesla', 'Ice Spirit', 'Skeletons', 'Log', 'Archers'],
      counters: ['Rocket', 'Earthquake', 'Goblin Barrel', 'Balloon'],
      bestDecks: ['X-Bow Siege', 'X-Bow Control'],
    ),

    'mortar': CardGuideData(
      name: 'Mortar',
      role: CardRole.winCondition,
      description:
          'Construção de artilharia que lança projéteis de área com dano considerável à distância.',
      tips: [
        'Rocket é OBRIGATÓRIO no deck de Mortar — garante dano direto à torre.',
        'Posicione no centro traseiro do campo para maximizar o alcance.',
        'Miner é um excelente parceiro: você pressiona na frente e atrás simultaneamente.',
        'Alterne Mortar e Miner para desgastar o adversário em dois flancos.',
      ],
      synergies: ['Rocket', 'Knight', 'Archers', 'Ice Spirit', 'Miner'],
      counters: ['Earthquake', 'Rocket', 'Giant', 'Hog Rider'],
      bestDecks: ['Mortar Cycle', 'Mortar Bait'],
    ),

    'wall breakers': CardGuideData(
      name: 'Wall Breakers',
      role: CardRole.winCondition,
      description:
          'Par de bombardeiros em moto que ignoram tropas e vão direto para construções e torres.',
      tips: [
        'Sempre combine com Miner: os Wall Breakers atraem o feitiço, o Miner acerta a torre.',
        'Jogue na lane oposta ao push principal para criar pressão dupla.',
        'Custo baixo (2 elixir) permite ciclo rápido — coloque assim que reciclar.',
        'Bomb Tower atrás defende e age como âncora para o contra-ataque.',
      ],
      synergies: ['Miner', 'Knight', 'Bats', 'Spear Goblins', 'Log'],
      counters: ['Arrows', 'Zap', 'Tesla', 'Cannon'],
      bestDecks: ['Wall Breakers Cycle', 'Miner Wall Breakers'],
    ),

    'miner': CardGuideData(
      name: 'Miner',
      role: CardRole.winCondition,
      description:
          'Tropa que entra subterrânea em qualquer lugar do mapa — ataca torres e distrações.',
      tips: [
        'Envie na torre inimiga enquanto defende para acumular dano chip.',
        'Combine com Poison: posicione o Poison cobrindo o Miner E a torre simultaneamente.',
        'Use para eliminar Princess, Dart Goblin e outras unidades de suporte inimigo.',
        'Alterne lanes para dificultar o posicionamento defensivo do adversário.',
      ],
      synergies: ['Poison', 'Goblin Gang', 'Minions', 'Wall Breakers', 'Mighty Miner'],
      counters: ['Skeleton Army', 'Guards', 'Inferno Tower'],
      bestDecks: ['Miner Control', 'Miner Poison', 'Wall Breakers Cycle'],
    ),

    'graveyard': CardGuideData(
      name: 'Graveyard',
      role: CardRole.winCondition,
      description:
          'Feitiço que invoca esqueletos aleatoriamente na área da torre inimiga por 10 segundos.',
      tips: [
        'Sempre combine com Poison: coloque o Poison cobrindo toda a área do Graveyard.',
        'Use um tanque (Giant, Golem) na frente para atrair o dano enquanto os esqueletos atacam.',
        'Coloque o Graveyard imediatamente após o adversário gastar elixir na defesa.',
        'Ice Wizard é o parceiro ideal: slow + dano atrasa a defesa dos esqueletos.',
      ],
      synergies: ['Poison', 'Ice Wizard', 'Giant', 'Baby Dragon', 'Tornado'],
      counters: ['Valkyrie', 'Wizard', 'Arrows', 'Baby Dragon'],
      bestDecks: ['Giant Graveyard', 'Golem Graveyard', 'Graveyard Control'],
    ),

    'three musketeers': CardGuideData(
      name: 'Three Musketeers',
      role: CardRole.winCondition,
      description:
          'Trio de musketeers que ao ser separado no centro cria pressão devastadora em duas lanes.',
      tips: [
        'SEMPRE jogue no centro do mapa para dividir automaticamente nas duas lanes.',
        'Use Elixir Collector primeiro para atrair o feitiço pesado adversário.',
        'Battle Ram ou Royal Hogs como segunda condição de vitória criam pressão dupla.',
        'Nunca jogue Three Musketeers com menos de 9 elixir ou sem Elixir Collector.',
      ],
      synergies: ['Elixir Collector', 'Battle Ram', 'Ice Golem', 'Log'],
      counters: ['Lightning', 'Fireball', 'Rocket', 'Tornado'],
      bestDecks: ['Three Musketeers Split', '3M Battle Ram'],
    ),

    'royal giant': CardGuideData(
      name: 'Royal Giant',
      role: CardRole.winCondition,
      description:
          'Tanque de alcance que ataca construções à distância, difícil de kitar com buildings.',
      tips: [
        'Coloque na fila na traseira para construir elixir antes do push.',
        'Electro Wizard atrás reseta Inferno Tower/Dragon que é o principal counter.',
        'Combine com Furnace para swarm de Fire Spirits que protege flancos.',
        'Bottle neck: a vantagem é que não é possível kitá-lo com Tesla ou Cannon.',
      ],
      synergies: ['Electro Wizard', 'Furnace', 'Mega Minion', 'Fireball'],
      counters: ['Inferno Dragon', 'Mini Pekka', 'Pekka', 'Cannon Cart'],
      bestDecks: ['Royal Giant Cycle', 'Royal Giant Furnace'],
    ),

    'battle ram': CardGuideData(
      name: 'Battle Ram',
      role: CardRole.winCondition,
      description:
          'Carneiro com dois Bárbaros que carrega em alta velocidade para a torre — os Bárbaros continuam após a morte.',
      tips: [
        'Use na bridge para velocidade máxima de ataque à torre.',
        'Combine com PEKKA para um push esmagador: PEKKA defende, Battle Ram ataca.',
        'Os dois Bárbaros que ficam após a destruição do carneiro ainda causam dano significativo.',
        'Golden Knight pode Dash junto ao Battle Ram para um ataque sincronizado.',
      ],
      synergies: ['Pekka', 'Bandit', 'Dark Prince', 'Royal Ghost', 'Golden Knight'],
      counters: ['Skeleton Army', 'Mega Knight', 'Inferno Dragon', 'Valkyrie'],
      bestDecks: ['PEKKA Bridge Spam', 'Battle Ram Bridge Spam'],
    ),

    'elixir golem': CardGuideData(
      name: 'Elixir Golem',
      role: CardRole.winCondition,
      description:
          'Tanque barato que ao morrer dá elixir ao inimigo — exige Battle Healer OBRIGATÓRIO.',
      tips: [
        'NUNCA jogue Elixir Golem sem Battle Healer no deck — as partes dão elixir ao adversário.',
        'Coloque na fila na traseira com Battle Healer atrás para heal contínuo.',
        'Electro Dragon é essencial para limpar as partes do Golem quando morrem.',
        'Night Witch atrás cria esqueletos que neutralizam os blobs de elixir.',
      ],
      synergies: ['Battle Healer', 'Night Witch', 'Electro Dragon', 'Baby Dragon', 'Tornado'],
      counters: ['Lightning', 'Tornado', 'Inferno Tower', 'Pekka'],
      bestDecks: ['Elixir Golem Beatdown'],
    ),

    'ram rider': CardGuideData(
      name: 'Ram Rider',
      role: CardRole.winCondition,
      description:
          'Cavaleira em carneiro que prende e desacelera a tropa alvo enquanto ataca com slow.',
      tips: [
        'Excelente para prender Hog Rider, Balloon e outras tropas de alto impacto.',
        'Combine com Balloon para push aéreo: Ram Rider prende defesas terrestres.',
        'O snare do Ram Rider é especialmente eficaz contra win conditions que precisam de velocidade.',
        'Use na bridge para velocidade máxima — ela carrega igual ao Battle Ram.',
      ],
      synergies: ['Balloon', 'Fireball', 'Bats', 'Mega Minion'],
      counters: ['Inferno Dragon', 'Minion Horde', 'Tesla', 'Skeleton Army'],
      bestDecks: ['Ram Rider Balloon', 'Ram Rider Cycle'],
    ),

    'goblin giant': CardGuideData(
      name: 'Goblin Giant',
      role: CardRole.winCondition,
      description:
          'Tanque gigante com dois Spear Goblins nas costas que atacam aérea e terrestremente.',
      tips: [
        'Os Spear Goblins nas costas cobrem aéreos automaticamente — ponto forte contra Minions.',
        'Combine com Sparky: o Sparky atrás do Giant é devastador.',
        'Balloon atrás do Goblin Giant cria dupla ameaça difícil de defender.',
        'Fireball é essencial para limpar suporte inimigo que venha defender o Giant.',
      ],
      synergies: ['Sparky', 'Balloon', 'Fireball', 'Electro Wizard'],
      counters: ['Inferno Tower', 'Pekka', 'Tornado', 'Mini Pekka'],
      bestDecks: ['Goblin Giant Sparky', 'Goblin Giant Balloon'],
    ),

    'royal hogs': CardGuideData(
      name: 'Royal Hogs',
      role: CardRole.winCondition,
      description:
          'Quatro porcos montados que atacam apenas construções — pressão massiva por 3 elixir.',
      tips: [
        'Com apenas 3 elixir, criam troca positiva quase sempre.',
        'Combine com Fireball para limpar as tropas defensivas antes de enviar os Hogs.',
        'São counters perfeitos para Elixir Collector adversário.',
        'Three Musketeers + Royal Hogs cria push duplo impossível de defender com pouco elixir.',
      ],
      synergies: ['Fireball', 'Three Musketeers', 'Ice Golem', 'The Log'],
      counters: ['Tesla', 'Cannon', 'Tornado', 'Skeleton Army'],
      bestDecks: ['Royal Hogs Cycle', 'Three Musketeers Royal Hogs'],
    ),

    // ── Tanks ─────────────────────────────────────────────────────────────────

    'pekka': CardGuideData(
      name: 'PEKKA',
      role: CardRole.tank,
      description:
          'A maior tropa terrestre — enorme dano por golpe, mas lenta e cara (7 elixir).',
      tips: [
        'PEKKA é SUPORTE, não win condition — sozinha ela não mata a torre.',
        'Use na defesa primeiro, depois contra-ataque imediatamente com Battle Ram ou suporte.',
        'Electro Wizard ou Zap são essenciais para resetar Inferno Tower/Dragon que destroem a PEKKA.',
        'Nunca coloque PEKKA no lado do adversário sem um win condition na frente.',
      ],
      synergies: ['Battle Ram', 'Electro Wizard', 'Zap', 'Dark Prince', 'Bandit'],
      counters: ['Tornado', 'Inferno Dragon', 'Mini Pekka', 'Skeleton Army'],
      bestDecks: ['PEKKA Bridge Spam', 'PEKKA Control'],
    ),

    'mega knight': CardGuideData(
      name: 'Mega Knight',
      role: CardRole.tank,
      description:
          'Cavaleiro gigante que causa dano de salto em área ao ser posicionado — excelente defensor.',
      tips: [
        'Mega Knight é DEFENSOR — coloque quando o inimigo tem push formado para o dano de salto máximo.',
        'Combine com Skeleton Army ou Night Witch para limpar o que ficou após o salto.',
        'No contra-ataque, coloque um win condition na frente (Balloon, Hog Rider) do Mega Knight.',
        'NUNCA use como win condition principal — sem suporte, ele para na torre.',
      ],
      synergies: ['Skeleton Army', 'Night Witch', 'Balloon', 'Sparky'],
      counters: ['Inferno Dragon', 'Tornado + Tower', 'Mini Pekka', 'Pekka'],
      bestDecks: ['Mega Knight Balloon', 'Mega Knight Skeleton Army'],
    ),

    'electro giant': CardGuideData(
      name: 'Electro Giant',
      role: CardRole.tank,
      description:
          'Tanque que cria um escudo elétrico ao redor de si, atordoando tropas que se aproximam.',
      tips: [
        'O escudo elétrico anula Inferno Tower e Inferno Dragon automaticamente — grande vantagem.',
        'Jogue na fila traseira com 10 elixir para maximizar o push.',
        'Mega Minion atrás cobre ameaças aéreas que o Electro Giant não atinge.',
        'Use Lightning para limpar suporte pesado inimigo antes que chegue ao Giant.',
      ],
      synergies: ['Mega Minion', 'Lightning', 'Night Witch', 'Tornado'],
      counters: ['Pekka', 'Mini Pekka', 'Arrows', 'Rocket'],
      bestDecks: ['Electro Giant Beatdown'],
    ),

    'giant skeleton': CardGuideData(
      name: 'Giant Skeleton',
      role: CardRole.tank,
      description:
          'Tanque lento que ao morrer deixa uma bomba com timer que causa dano massivo em área.',
      tips: [
        'A bomba de morte é o poder real — posicione onde causará mais dano ao morrer.',
        'Combine com Mirror para uma segunda bomba surpresa.',
        'Dark Prince e Night Witch atrás criam um push que o adversário terá dificuldade de parar.',
        'Coloque do seu lado da arena e deixe a push se formar naturalmente.',
      ],
      synergies: ['Dark Prince', 'Night Witch', 'Mirror', 'Tornado'],
      counters: ['Pekka', 'Inferno Tower', 'Lightning'],
      bestDecks: ['Giant Skeleton Push'],
    ),

    // ── Mini Tanks ────────────────────────────────────────────────────────────

    'ice golem': CardGuideData(
      name: 'Ice Golem',
      role: CardRole.miniTank,
      description:
          'Mini-tanque barato (2 elixir) que congela tropas ao morrer — perfeito para kitar.',
      tips: [
        'Use na frente do Hog Rider para absorver o dano e desacelerar defensores.',
        'Coloque no rio para kitar (atrair) tropas inimiges para longe da torre.',
        'Ao morrer, o gelo lento defende contra enxames e tropas rápidas.',
        'Excelente em decks de ciclo — baixo custo permite reciclar rapidamente.',
      ],
      synergies: ['Hog Rider', 'Balloon', 'Three Musketeers', 'Giant'],
      counters: ['Fireball', 'Tornado', 'Baby Dragon'],
      bestDecks: ['Hog Cycle', 'Three Musketeers'],
    ),

    'knight': CardGuideData(
      name: 'Knight',
      role: CardRole.miniTank,
      description:
          'Mini-tanque versátil de 3 elixir com escudo — um dos melhores defensores do jogo.',
      tips: [
        'Use para defender Hog Rider, Balloon e pushes médias na sua side.',
        'Combine com Musketeer: Knight tanqueia, Musketeer causa dano atrás.',
        'No contra-ataque, o Knight frente ao Miner ou Hog Rider protege bem.',
        'O escudo absorve um golpe extra — eficaz contra cartas de alto dano por hit.',
      ],
      synergies: ['Musketeer', 'Miner', 'Tombstone', 'Poison'],
      counters: ['Fireball', 'Wizard', 'Mini Pekka'],
      bestDecks: ['Miner Control', 'Hog Cycle', 'X-Bow'],
    ),

    'valkyrie': CardGuideData(
      name: 'Valkyrie',
      role: CardRole.miniTank,
      description:
          'Mini-tanque com giro de ataque em área — devastadora contra enxames e grupos.',
      tips: [
        'Posicione no centro para que o giro atinja o máximo de tropas.',
        'Excelente counter para Goblin Gang, Skeleton Army e Rascals.',
        'No Hog Exnado, Valkyrie + Executioner + Tornado limpam qualquer push.',
        'Combine com Hog Rider: Valkyrie defende swarms, Hog ataca a torre.',
      ],
      synergies: ['Hog Rider', 'Executioner', 'Tornado', 'Ice Spirit'],
      counters: ['Fireball', 'Rocket', 'Pekka', 'Mini Pekka'],
      bestDecks: ['Hog Exnado', 'Hog Cycle'],
    ),

    'mini pekka': CardGuideData(
      name: 'Mini PEKKA',
      role: CardRole.miniTank,
      description:
          'Tropa com alto dano por golpe — excelente counter para tanques e win conditions.',
      tips: [
        'Use na defesa contra Hog Rider, Giant e outros tanques — ela mata rápido.',
        'Combine com Musketeer para defesa completa aérea + terrestre.',
        'No contra-ataque, Mini PEKKA com uma spell de suporte causa dano sólido.',
        'Cuida com Tornado — ela pode ser puxada para longe perdendo a ofensiva.',
      ],
      synergies: ['Musketeer', 'Fireball', 'Giant', 'Graveyard'],
      counters: ['Skeleton Army', 'Goblin Gang', 'Wizard', 'Tornado'],
      bestDecks: ['Giant Graveyard', 'Miner Mini PEKKA'],
    ),

    'dark prince': CardGuideData(
      name: 'Dark Prince',
      role: CardRole.miniTank,
      description:
          'Mini-tanque com escudo que carrega causando splash — híbrido de tanque e suporte.',
      tips: [
        'O escudo absorve o primeiro golpe — útil em defensivas.',
        'Carrega em linha reta: posicione para que o splash atinja o máximo de tropas.',
        'Combine com PEKKA no Bridge Spam: enquanto a PEKKA defende, Dark Prince pressiona.',
        'Excelente para limpar Goblins, Spear Goblins e pequenos enxames.',
      ],
      synergies: ['Pekka', 'Bandit', 'Battle Ram', 'Royal Ghost'],
      counters: ['Inferno Dragon', 'Wizard', 'Mega Knight'],
      bestDecks: ['PEKKA Bridge Spam', 'Giant Double Prince'],
    ),

    'prince': CardGuideData(
      name: 'Prince',
      role: CardRole.miniTank,
      description:
          'Cavaleiro de alta velocidade que carrega com velocidade dupla causando grande dano.',
      tips: [
        'O primeiro golpe com carga causa dano em área — posicione para maximizar o impacto.',
        'Combine com Dark Prince para o "Double Prince" push — um defende, o outro ataca.',
        'Use no bridge para speed máxima e dano de carga na primeira hit.',
        'Skeleton Army para a carga do Prince — use Zap ou Log para limpar antes.',
      ],
      synergies: ['Dark Prince', 'Giant', 'Witch', 'Electro Wizard'],
      counters: ['Skeleton Army', 'Inferno Dragon', 'Tornado'],
      bestDecks: ['Giant Double Prince', 'Double Prince Balloon'],
    ),

    'battle healer': CardGuideData(
      name: 'Battle Healer',
      role: CardRole.miniTank,
      description:
          'Tropa que se cura ao atacar e cura tropas próximas — essencial no Elixir Golem.',
      tips: [
        'OBRIGATÓRIA no deck de Elixir Golem — sem ela, os blobs dão elixir ao adversário.',
        'Coloque logo atrás do Elixir Golem para cura contínua durante todo o push.',
        'Combine com Baby Dragon e Night Witch para push completo e autossustentável.',
        'Fireball ou Lightning do adversário são a maior ameaça — tenha spells para rebater.',
      ],
      synergies: ['Elixir Golem', 'Night Witch', 'Baby Dragon', 'Electro Dragon'],
      counters: ['Lightning', 'Rocket', 'Fireball', 'Tornado'],
      bestDecks: ['Elixir Golem Beatdown'],
    ),

    // ── Support ───────────────────────────────────────────────────────────────

    'musketeer': CardGuideData(
      name: 'Musketeer',
      role: CardRole.support,
      description:
          'Tropa de longo alcance que atinge alvos aéreos e terrestres — pilar de muitos decks.',
      tips: [
        'Posicione atrás da torre para cobertura máxima de alcance antes de avançar.',
        'Excelente counter para unidades aéreas: Balloon, Lava Hound, Baby Dragon.',
        'Combine com Knight para defesa completa: Knight tanqueia, Musketeer causa dano.',
        'Use no contra-ataque atrás de um tanque para maximizar o dano à torre.',
      ],
      synergies: ['Knight', 'Hog Rider', 'Giant', 'Ice Golem'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Hog Cycle', 'Miner Control', 'Giant Beatdown'],
    ),

    'wizard': CardGuideData(
      name: 'Wizard',
      role: CardRole.support,
      description:
          'Mago de dano em área que neutraliza enxames e Graveyard — suporte pesado de 5 elixir.',
      tips: [
        'Counter natural para Goblin Barrel, Graveyard e qualquer deck de swarm.',
        'Combine com Giant ou Golem para suporte de área durante o push.',
        'O Wizard tem dano de área em 360 graus — posicione centralmente.',
        'Custo alto (5 elixir) — use com planejamento, nunca como jogada impulsiva.',
      ],
      synergies: ['Giant', 'Golem', 'Hog Rider', 'Ice Golem'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Giant Wizard', 'Hog Wizard'],
    ),

    'electro wizard': CardGuideData(
      name: 'Electro Wizard',
      role: CardRole.support,
      description:
          'Cria um raio ao ser invocado que atordoa e causa dano — reseta Inferno Tower/Dragon.',
      tips: [
        'Spawn lightning reseta Inferno Tower ou Inferno Dragon automaticamente ao ser colocado.',
        'Atordoa dois alvos simultaneamente — excelente contra pushes de múltiplas unidades.',
        'Use em decks com Golem ou Giant para garantir o reset do Inferno.',
        'Counter para Sparky: o Electro Wizard a reseta continuamente.',
      ],
      synergies: ['Golem', 'Giant', 'Pekka', 'Hog Rider'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Golem Beatdown', 'Hog Exnado'],
    ),

    'ice wizard': CardGuideData(
      name: 'Ice Wizard',
      role: CardRole.support,
      description:
          'Mago que desacelera tropas com cada ataque — incrível no Graveyard Control.',
      tips: [
        'Slow em área transforma defesas simples em eficientes.',
        'Combine com Tornado para arrastar tropas ao raio de slow e matar na torre.',
        'Imprescindível no Graveyard Control: esqueletos ficam muito mais tempo vivos.',
        'Baby Dragon + Ice Wizard + Tornado = a trindade defensiva do controle.',
      ],
      synergies: ['Tornado', 'Graveyard', 'Baby Dragon', 'Goblin Cage'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Graveyard Control', 'X-Bow Control'],
    ),

    'night witch': CardGuideData(
      name: 'Night Witch',
      role: CardRole.support,
      description:
          'Invoca Morcegos periodicamente e ao morrer libera um grupo — pilar do Golem Beatdown.',
      tips: [
        'Os morcegos invocados cobrem ataques aéreos — essenciais contra Balloon e Minions.',
        'Combine com Golem ou Lava Hound: Night Witch vai atrás do tanque gerando swarm.',
        'Ao morrer, os morcegos continuam atacando — o inimigo precisa gastar spell.',
        'Fireball inimiga é a maior ameaça — Skeleton Army ou Guards para servir de isca.',
      ],
      synergies: ['Golem', 'Lava Hound', 'Baby Dragon', 'Mega Minion'],
      counters: ['Arrows', 'Fireball', 'Valkyrie', 'Wizard'],
      bestDecks: ['Golem Beatdown', 'Golem Night Witch'],
    ),

    'witch': CardGuideData(
      name: 'Witch',
      role: CardRole.support,
      description:
          'Invoca esqueletos e tem ataque em área — boa contra swarms e push médias.',
      tips: [
        'Combine com Giant para um push que se renova automaticamente com esqueletos.',
        'O ataque splash destrói enxames — útil contra Goblin Gang e Rascals.',
        'Arqueiros e Firecracker são counters fáceis pelo alto HP da Witch ser mediocre.',
        'Use no counter-push depois de uma defesa bem-sucedida.',
      ],
      synergies: ['Giant', 'Prince', 'Hog Rider', 'Ice Golem'],
      counters: ['Fireball', 'Lightning', 'Executioner'],
      bestDecks: ['Giant Witch', 'Hog Witch'],
    ),

    'baby dragon': CardGuideData(
      name: 'Baby Dragon',
      role: CardRole.airUnit,
      description:
          'Unidade aérea de splash que cobre tanto aéreos quanto terrestres — versátil e resistente.',
      tips: [
        'Combo clássico: Baby Dragon + Tornado para arrastar todas as tropas para a torre.',
        'Posicione atrás do Golem/Giant para cobertura de área durante o push.',
        'Voa sobre muralhas — use para chegar mais rápido ao centro do mapa.',
        'Excelente counter para Graveyard: splash mata os esqueletos enquanto você defende.',
      ],
      synergies: ['Golem', 'Tornado', 'Night Witch', 'Graveyard', 'Ice Wizard'],
      counters: ['Minion Horde', 'Mega Minion', 'Inferno Dragon'],
      bestDecks: ['Golem Beatdown', 'Graveyard Control', 'LavaLoon'],
    ),

    'mega minion': CardGuideData(
      name: 'Mega Minion',
      role: CardRole.airUnit,
      description:
          'Minion tanque de 3 elixir — alto HP e dano consistente, versátil em qualquer deck.',
      tips: [
        'Counter confiável para Balloon e Lava Hound — o dano é alto o suficiente.',
        'Combine com Golem ou Giant como suporte aéreo do push.',
        'Use sozinho na defesa para lidar com Hog Rider (com support da torre).',
        'É o "queridinho" para preencher o slot de unidade aérea em qualquer deck.',
      ],
      synergies: ['Golem', 'Lava Hound', 'Giant', 'Hog Rider'],
      counters: ['Arrows', 'Fireball', 'Zap'],
      bestDecks: ['Golem Beatdown', 'LavaLoon', 'Hog Cycle'],
    ),

    'inferno dragon': CardGuideData(
      name: 'Inferno Dragon',
      role: CardRole.airUnit,
      description:
          'Unidade aérea com dano crescente — mata qualquer tanque se não for resetado.',
      tips: [
        'O dano aumenta continuamente — leva 2-3 segundos para atingir o pico.',
        'Counter absoluto para Golem, Giant e qualquer tanque sem reset.',
        'Zap ou Electro Wizard do adversário resetam o dano — sempre tenha cuidado.',
        'Combine com Balloon no LavaLoon para cobertura aérea total.',
      ],
      synergies: ['Lava Hound', 'Tombstone', 'Minions', 'Balloon'],
      counters: ['Zap', 'Electro Wizard', 'Electro Spirit', 'Minion Horde'],
      bestDecks: ['LavaLoon', 'Inferno Dragon Cycle'],
    ),

    'flying machine': CardGuideData(
      name: 'Flying Machine',
      role: CardRole.airUnit,
      description:
          'Unidade aérea de longo alcance que atira de longe — difícil de atingir com algumas defesas.',
      tips: [
        'O longo alcance permite atacar a torre sem entrar no range de muitas defesas.',
        'Posicione na traseira para cobertura durante pushes de beatdown.',
        'Excelente no LavaLoon para cobertura de alcance que não requer chegar perto.',
        'Counter para unidades terrestres que não alcançam ela facilmente.',
      ],
      synergies: ['Golem', 'Lava Hound', 'Giant', 'Night Witch'],
      counters: ['Arrows', 'Fireball', 'Mega Minion', 'Minion Horde'],
      bestDecks: ['Golem Beatdown', 'LavaLoon'],
    ),

    'minions': CardGuideData(
      name: 'Minions',
      role: CardRole.airUnit,
      description:
          'Trio de minions rápidos e baratos — versáteis na defesa e no suporte de pushes.',
      tips: [
        'Counter para unidades terrestres lentas: Golem, Giant, PEKKA.',
        'Combine com Lava Hound para cobertura aérea e DPS adicional.',
        'Custo baixo (3 elixir) — ótimos para ciclo e respostas rápidas.',
        'Arrows ou Zap inimigos os eliminam rapidamente — use com cuidado.',
      ],
      synergies: ['Lava Hound', 'Balloon', 'Hog Rider', 'Giant'],
      counters: ['Arrows', 'Fireball', 'Zap', 'Wizard'],
      bestDecks: ['LavaLoon', 'Hog Cycle', 'Miner Control'],
    ),

    'minion horde': CardGuideData(
      name: 'Minion Horde',
      role: CardRole.airUnit,
      description:
          'Seis minions de uma vez — DPS altíssimo mas vulnerável a qualquer feitiço de área.',
      tips: [
        'Counter absoluto para Balloon — mata antes de chegar à torre.',
        'Use apenas quando tiver certeza que o adversário já gastou os feitiços de área.',
        'Excelente no counter-push junto a win conditions pesadas.',
        'Nunca use como sua única defesa se o adversário tem Arrows ou Fireball em mão.',
      ],
      synergies: ['Giant', 'Hog Rider', 'Golem'],
      counters: ['Arrows', 'Fireball', 'Zap', 'Wizard'],
      bestDecks: ['Giant Beatdown', 'Hog Beatdown'],
    ),

    'bats': CardGuideData(
      name: 'Bats',
      role: CardRole.swarm,
      description:
          'Quatro morcegos baratos (2 elixir) — extremamente rápidos e difíceis de defender sem spell.',
      tips: [
        'Use imediatamente após o adversário gastar Zap ou Arrows.',
        'Excelente para pressão rápida ou defesa contra terrestres lentos.',
        'Combine com Wall Breakers para ciclo ultra-rápido e pressão dupla.',
        'Counter para unidades sem ataque aéreo: Hog Rider, Miner, Wall Breakers.',
      ],
      synergies: ['Wall Breakers', 'Miner', 'Hog Rider', 'Ram Rider'],
      counters: ['Zap', 'Arrows', 'Wizard', 'Baby Dragon'],
      bestDecks: ['Wall Breakers Cycle', 'Miner Control'],
    ),

    // ── Swarm/Cycle ───────────────────────────────────────────────────────────

    'skeletons': CardGuideData(
      name: 'Skeletons',
      role: CardRole.swarm,
      description:
          'Três esqueletos por 1 elixir — o melhor card de ciclo do jogo, counter absurdo para o custo.',
      tips: [
        'Use para kitar (atrair e desviar) o Hog Rider, Prince e outras tropas de alto dano.',
        'Posicione diagonalmente de uma tropa carregada para distrair por mais tempo.',
        'Excelente para ciclar rapidamente — 1 elixir permite rodar o deck mais rápido.',
        'Combine com Tornado para arrastar tropas ao dano das torres.',
      ],
      synergies: ['Tornado', 'X-Bow', 'Hog Rider', 'Giant'],
      counters: ['Zap', 'Log', 'Arrows', 'Fireball'],
      bestDecks: ['Hog Cycle', 'X-Bow Siege', 'Miner Cycle'],
    ),

    'goblins': CardGuideData(
      name: 'Goblins',
      role: CardRole.swarm,
      description:
          'Três goblins com adagas — alta velocidade de ataque e excelente relação custo-benefício.',
      tips: [
        'Use para kitar o Hog Rider na defesa: goblins o distraem por bastante tempo.',
        'Combine com Miner: o Miner atrai as defesas, os Goblins atacam livremente.',
        'No contra-ataque, envie atrás de um mini-tank para maximizar o dano.',
        'Log inimigo os elimina facilmente — use quando o adversário já gastou o Log.',
      ],
      synergies: ['Miner', 'Hog Rider', 'Ice Golem', 'Tombstone'],
      counters: ['Log', 'Zap', 'Fireball', 'Arrows'],
      bestDecks: ['Miner Control', 'Hog Cycle'],
    ),

    'goblin gang': CardGuideData(
      name: 'Goblin Gang',
      role: CardRole.swarm,
      description:
          'Cinco goblins (3 com facas + 2 com lanças) por 3 elixir — excelente isca para feitiços.',
      tips: [
        'Isca dois feitiços ao mesmo tempo: Log mata apenas metade, Arrows mata todos.',
        'Use como principal isca no Log Bait junto com Goblin Barrel e Princess.',
        'Combine com Miner: Miner atrai a defesa, Goblin Gang causa dano ao lado.',
        'Ao dividir em dois grupos, é difícil de defender com uma única tropa.',
      ],
      synergies: ['Miner', 'Goblin Barrel', 'Princess', 'Dart Goblin'],
      counters: ['Arrows', 'Fireball', 'Valkyrie', 'Wizard'],
      bestDecks: ['Log Bait', 'Miner Control'],
    ),

    'spear goblins': CardGuideData(
      name: 'Spear Goblins',
      role: CardRole.swarm,
      description:
          'Três goblins com lanças de ataque à distância — baratos e versáteis para ciclo.',
      tips: [
        'Boa resposta contra Balloon e unidades aéreas que precisam ser stopadas rápido.',
        'Use para ciclar rapidamente (2 elixir) e aplicar pressão constante.',
        'Combine com Wall Breakers para pressão dupla muito barata.',
        'Split na arena para criar ameaça em ambas as lanes por apenas 2 elixir.',
      ],
      synergies: ['Wall Breakers', 'Miner', 'Mortar', 'Hog Rider'],
      counters: ['Log', 'Zap', 'Arrows'],
      bestDecks: ['Wall Breakers Cycle', 'Mortar Cycle'],
    ),

    'skeleton army': CardGuideData(
      name: 'Skeleton Army',
      role: CardRole.swarm,
      description:
          'Quinze esqueletos de uma vez — mata qualquer tropa de alto dano em segundos.',
      tips: [
        'Counter perfeito para Hog Rider, Prince, Battle Ram e outras tropas rápidas.',
        'NUNCA use se o adversário tem Zap, Log ou Arrows na mão.',
        'Use defensivamente após confirmar que o adversário gastou seus feitiços de área.',
        'Combine com Zap do adversário adversário — sim, como isca para ele desperdiçar o spell.',
      ],
      synergies: ['Mega Knight', 'Golden Knight', 'Balloon', 'Skeleton King'],
      counters: ['Zap', 'Log', 'Arrows', 'Fireball', 'Tornado'],
      bestDecks: ['Mega Knight Balloon', 'Skeleton Army Balloon'],
    ),

    'rascals': CardGuideData(
      name: 'Rascals',
      role: CardRole.swarm,
      description:
          'Um garoto de melee + duas garotas à distância — split defensivo por apenas 5 elixir.',
      tips: [
        'Isca eficaz para Log: o garoto central morre, as garotas sobrevivem.',
        'As garotas atacam à distância — posicione centralmente para cobertura dupla.',
        'Combine no Log Bait: junto com Princess e Goblin Barrel, força múltiplos feitiços.',
        'Use split na arena para ameaçar ambas as lanes ao mesmo tempo.',
      ],
      synergies: ['Goblin Barrel', 'Princess', 'Dart Goblin', 'Hog Rider'],
      counters: ['Arrows', 'Fireball', 'Wizard', 'Valkyrie'],
      bestDecks: ['Log Bait', 'Mortar Bait'],
    ),

    'ice spirit': CardGuideData(
      name: 'Ice Spirit',
      role: CardRole.swarm,
      description:
          'Congelar uma tropa por 1 segundo por apenas 1 elixir — o melhor reset barato do jogo.',
      tips: [
        'Use para congelar Inferno Tower momentaneamente enquanto o Hog ataca.',
        'Em double elixir, Ice Spirit + qualquer tropa cria plays poderosas de 1 elixir.',
        'Combine com Tornado para uma sinco letal que paralisa e arrasta tropas.',
        'Counter econômico para a maioria das pushes de 1 elixir — cicla muito rápido.',
      ],
      synergies: ['Hog Rider', 'Tornado', 'X-Bow', 'Musketeer'],
      counters: ['Zap', 'Arrows', 'Tesla'],
      bestDecks: ['Hog Cycle', 'X-Bow Siege'],
    ),

    'electro spirit': CardGuideData(
      name: 'Electro Spirit',
      role: CardRole.swarm,
      description:
          'Atordoa um grupo de tropas por 1 elixir — reset barato e versátil para ciclo.',
      tips: [
        'Use para resetar Inferno Tower/Dragon em vez do Zap — mesma função, mesmo custo.',
        'Atinge múltiplos alvos no impacto — útil contra grupos de tropas.',
        'Combine com Goblin Giant ou Ram Rider para reset de Inferno enquanto avança.',
        'Ciclo de 1 elixir — use para ciclar rápido e chegar ao Hog Rider ou Rocket.',
      ],
      synergies: ['Hog Rider', 'Royal Giant', 'Goblin Giant', 'Miner'],
      counters: ['Tesla', 'Arrows'],
      bestDecks: ['Hog Cycle', 'Royal Giant Cycle'],
    ),

    'fire spirit': CardGuideData(
      name: 'Fire Spirit',
      role: CardRole.swarm,
      description:
          'Espírito de fogo que explode em área ao impacto — contra-measure barata para grupos.',
      tips: [
        'Counter para Minions, Bats e outros grupos de unidades baratas.',
        'Combine com Furnace que os gera automaticamente — pressão constante grátis.',
        'Use defensivamente para eliminar enxames que acompanham a push inimiga.',
        'Por apenas 1 elixir, é um dos melhores counter-swarm do jogo.',
      ],
      synergies: ['Furnace', 'Royal Giant', 'Goblin Barrel', 'Hog Rider'],
      counters: ['Zap', 'Arrows', 'Ice Wizard'],
      bestDecks: ['Royal Giant Furnace', 'Furnace Cycle'],
    ),

    // ── Spells ────────────────────────────────────────────────────────────────

    'fireball': CardGuideData(
      name: 'Fireball',
      role: CardRole.spellHeavy,
      description:
          'Feitiço de dano médio que elimina tropas de nível médio e danifica torres.',
      tips: [
        'Use para eliminar Musketeer, Wizard e outros suportes de custo médio.',
        'Combine com Log ou Zap para limpar grupos: Fireball mata, Log/Zap finaliza.',
        'Chip dano na torre acumula — use quando o adversário tem tropa junto à torre.',
        'Counter para Elixir Collector: 4 elixir nele é uma troca positiva.',
      ],
      synergies: ['Log', 'Zap', 'Hog Rider', 'Goblin Barrel'],
      counters: [],
      bestDecks: ['Hog Cycle', 'Log Bait', 'Royal Giant'],
    ),

    'lightning': CardGuideData(
      name: 'Lightning',
      role: CardRole.spellHeavy,
      description:
          'Atinge as 3 tropas/construções mais fortes na área com dano altíssimo por 6 elixir.',
      tips: [
        'Counter para Inferno Tower + Night Witch + outra tropa de suporte simultaneamente.',
        'Use para eliminar Elixir Collector + suporte adversário de uma vez.',
        'Timing crítico: use quando TRÊS alvos valiosos estão na área.',
        '6 elixir é caro — garanta que vai acertar múltiplos alvos de alto valor.',
      ],
      synergies: ['Golem', 'Giant', 'Lava Hound', 'Elixir Golem'],
      counters: [],
      bestDecks: ['Golem Beatdown', 'LavaLoon', 'Elixir Golem'],
    ),

    'rocket': CardGuideData(
      name: 'Rocket',
      role: CardRole.spellHeavy,
      description:
          'O feitiço de maior dano do jogo — elimina grupos de tropas e danifica torres.',
      tips: [
        'Use direto na torre nos turnos finais para vitória por chip dano.',
        'Counter para Three Musketeers: Rocket as elimina de uma vez.',
        'Combine com Mortar: Rocket garante dano à torre quando Mortar não está ativo.',
        'O lançamento é lento — adversário pode mover tropas para fora do alcance.',
      ],
      synergies: ['Mortar', 'Hog Rider', 'Goblin Barrel', 'X-Bow'],
      counters: [],
      bestDecks: ['Mortar Cycle', 'Log Bait', 'Hog Rocket'],
    ),

    'poison': CardGuideData(
      name: 'Poison',
      role: CardRole.spellHeavy,
      description:
          'Área de veneno que causa dano contínuo por 8 segundos — devastador no controle.',
      tips: [
        'Combine com Miner: Miner cava até a torre, Poison cobre a área de aterrissagem.',
        'Counter para Graveyard: Poison elimina os esqueletos enquanto eles surgem.',
        'Use em Elixir Collector inimigo — o veneno o destrói em alguns segundos.',
        'Slow implícito: as tropas dentro do Poison ficam com HP mais baixo — facilita defesa.',
      ],
      synergies: ['Miner', 'Graveyard', 'Goblin Gang', 'Giant'],
      counters: [],
      bestDecks: ['Miner Control', 'Graveyard Poison', 'Giant Graveyard'],
    ),

    'earthquake': CardGuideData(
      name: 'Earthquake',
      role: CardRole.spellHeavy,
      description:
          'Causa dano contínuo em construções por 6 segundos — destroi buildings baratas rápido.',
      tips: [
        'Counter especifico para X-Bow e Mortar — os destrói em segundos.',
        'Use para eliminar Elixir Collector adversário de forma eficiente.',
        'Não atinge tropas aéreas nem faz dano a unidades — só construções e terrestre.',
        'Combine com Hog Rider: Earthquake destroi a Tesla/Cannon enquanto Hog ataca.',
      ],
      synergies: ['Hog Rider', 'Elixir Golem', 'Ram Rider'],
      counters: [],
      bestDecks: ['Elixir Golem', 'Hog Earthquake'],
    ),

    'arrows': CardGuideData(
      name: 'Arrows',
      role: CardRole.spellLight,
      description:
          'Chuva de flechas de baixo dano em área — elimina a maioria das tropas baratas e aéreas.',
      tips: [
        'Counter para Princess, Bats, Minions e qualquer enxame leve.',
        'Use no Goblin Barrel para limpar os goblins rapidamente.',
        'Combine com Hog Rider: Arrows limpam a defesa, Hog ataca a torre.',
        'Mais lento que Zap/Log — preveja o movimento das tropas ao usar.',
      ],
      synergies: ['Hog Rider', 'Goblin Barrel', 'Miner', 'Balloon'],
      counters: [],
      bestDecks: ['Log Bait', 'Miner Control', 'LavaLoon'],
    ),

    'the log': CardGuideData(
      name: 'The Log',
      role: CardRole.spellLight,
      description:
          'Rola empurrando tropas terrestres e causando pequeno dano — o feitiço mais eficiente do jogo.',
      tips: [
        'Empurra tropas para trás — use antes do Goblin Barrel chegar para impedir a defesa.',
        'Counter para Princess, Bats e Goblin Barrel — alto valor por 2 elixir.',
        'Use para empurrar o Skeleton Army ou Goblin Gang para fora da posição.',
        'No final da batalha, o push pode garantir vitória empurrando tropas para baixo.',
      ],
      synergies: ['Goblin Barrel', 'Hog Rider', 'X-Bow', 'Miner'],
      counters: [],
      bestDecks: ['Log Bait', 'Hog Cycle', 'X-Bow Siege'],
    ),

    'zap': CardGuideData(
      name: 'Zap',
      role: CardRole.spellLight,
      description:
          'Atordoa e causa dano mínimo em área — o reset mais rápido do jogo por 2 elixir.',
      tips: [
        'Use para resetar Inferno Tower e Sparky — timing crítico para o Hog Rider sobreviver.',
        'Counter para Bats, Skeleton Army e enxames pequenos.',
        'Zap + Hog Rider é a combinação mais básica do jogo — Zap limpa, Hog ataca.',
        'Em decks de ciclo, Zap de 2 elixir é essencial para rodar o deck rápido.',
      ],
      synergies: ['Hog Rider', 'Balloon', 'Goblin Barrel', 'Royal Giant'],
      counters: [],
      bestDecks: ['Hog Cycle', 'LavaLoon', 'Log Bait'],
    ),

    'snowball': CardGuideData(
      name: 'Snowball',
      role: CardRole.spellLight,
      description:
          'Empurra e lentifica tropas em área — versão snow do Log com maior cobertura.',
      tips: [
        'Slow adicional é o diferencial — tropas ficam mais lentas após serem atingidas.',
        'Use para empurrar enxames para o alcance da torre ou para desviar de win conditions.',
        'Combine com Tornado: Snowball lentifica, Tornado arrasta para a torre do rei.',
        'Alternativa ao Log quando precisar de mais área de slow.',
      ],
      synergies: ['Tornado', 'Hog Rider', 'Miner', 'X-Bow'],
      counters: [],
      bestDecks: ['Hog Cycle', 'Miner Cycle'],
    ),

    'freeze': CardGuideData(
      name: 'Freeze',
      role: CardRole.spellLight,
      description:
          'Congela todas as tropas e towers na área por vários segundos — poderoso e situacional.',
      tips: [
        'Use quando o Balloon está chegando à torre: Freeze paralisa todas as defesas.',
        'Timing é tudo — use quando o Balloon ou outra win condition está na posição certa.',
        'Counter para Inferno Tower e Inferno Dragon que destroem tanques rapidamente.',
        'Não use cedo demais — espere o push estar estabelecido antes de congelar.',
      ],
      synergies: ['Balloon', 'Giant', 'Lava Hound', 'Hog Rider'],
      counters: [],
      bestDecks: ['LavaLoon Freeze', 'Balloon Freeze'],
    ),

    'tornado': CardGuideData(
      name: 'Tornado',
      role: CardRole.spellLight,
      description:
          'Atrai tropas para o centro da área — ativa a torre do rei e cria sinergias únicas.',
      tips: [
        'Use para ativar a Torre do Rei arrastando uma tropa para o centro — vantagem enorme.',
        'Combo com Baby Dragon: Tornado arrasta, Baby Dragon causa splash em todos.',
        'Combine com Executioner para um clear devastador: Tornado agrupa, Executioner golpeia.',
        'Counter para Balloon: arraste-o para longe antes que chegue à torre.',
      ],
      synergies: ['Baby Dragon', 'Executioner', 'Ice Wizard', 'Golem'],
      counters: [],
      bestDecks: ['Graveyard Control', 'Golem Beatdown', 'Hog Exnado'],
    ),

    'barbarian barrel': CardGuideData(
      name: 'Barbarian Barrel',
      role: CardRole.spellLight,
      description:
          'Rola como o Log e deixa um Bárbaro no final — combina spell e tropa.',
      tips: [
        'O Bárbaro que sobra cria pressão adicional na torre após o roll.',
        'Use como alternativa ao Log em decks que precisam de um mini-tank deixado.',
        'Counter para Princess e Dart Goblin: o roll os elimina pelo caminho.',
        'Combine com Hog Rider: o Bárbaro distrai a defesa enquanto o Hog ataca.',
      ],
      synergies: ['Hog Rider', 'Goblin Giant', 'Mortar', 'Golem'],
      counters: [],
      bestDecks: ['Golem Beatdown', 'Hog Cycle', 'Mortar Bait'],
    ),

    'clone': CardGuideData(
      name: 'Clone',
      role: CardRole.spellLight,
      description:
          'Cria cópias com 1 HP de todas as tropas na área — dobra a pressão instantaneamente.',
      tips: [
        'Use quando o push está estabelecido na torre inimiga para dobrar o dano.',
        'Combine com Balloon: dois Balloons na torre são quase impossíveis de defender.',
        'As cópias tem 1 HP — qualquer spell de área as elimina, então use no momento certo.',
        'Freeze + Clone é a combinação clássica: Freeze paralisa, Clone dobra.',
      ],
      synergies: ['Balloon', 'Giant', 'Three Musketeers', 'Freeze'],
      counters: [],
      bestDecks: ['Balloon Clone', 'Giant Clone'],
    ),

    'mirror': CardGuideData(
      name: 'Mirror',
      role: CardRole.spellLight,
      description:
          'Copia a última carta jogada com 1 nível a mais — poderosa mas situacional.',
      tips: [
        'Use com Three Musketeers para ter 6 musketeers no campo simultaneamente.',
        'Mirror + Rocket garante dois rockets em sequência — devastador para a torre.',
        'Use com Elixir Collector para dobrar a geração de elixir rápido.',
        'Situacional demais para decks competitivos — geralmente substituída por cards mais confiáveis.',
      ],
      synergies: ['Three Musketeers', 'Rocket', 'Elixir Collector', 'Giant Skeleton'],
      counters: [],
      bestDecks: ['Three Musketeers Mirror'],
    ),

    'royal delivery': CardGuideData(
      name: 'Royal Delivery',
      role: CardRole.spellLight,
      description:
          'Entrega um Royal Recruit + dano em área — mais valor que uma spell pura.',
      tips: [
        'O Royal Recruit deixado causa pressão adicional após o dano da entrega.',
        'Use para limpar enxames enquanto deixa um defensor no campo.',
        'Combine com Mortar ou X-Bow para defesa e counter-push simultâneos.',
        'Alternativa versátil ao Log quando precisar de uma tropa extra.',
      ],
      synergies: ['Mortar', 'X-Bow', 'Hog Rider'],
      counters: [],
      bestDecks: ['Mortar Cycle', 'X-Bow Siege'],
    ),

    // ── Buildings ─────────────────────────────────────────────────────────────

    'cannon': CardGuideData(
      name: 'Cannon',
      role: CardRole.building,
      description:
          'Construção defensiva barata de alto DPS contra terrestres — clássica em Hog Cycle.',
      tips: [
        'Posicione no centro para kitar (atrair) o Hog Rider para longe da torre.',
        'Combine com Musketeer para defesa completa: Cannon kita terrestres, Musketeer cobre aéreos.',
        'Em Hog Cycle, Cannon é o core defensivo — sempre tenha em mão.',
        'Upgrade natural: se tiver Evo Cannon disponível, é um upgrade direto.',
      ],
      synergies: ['Hog Rider', 'Musketeer', 'Ice Spirit', 'Fireball'],
      counters: ['Earthquake', 'Rocket', 'Goblin Barrel'],
      bestDecks: ['Hog Cycle', 'Hog 2.6'],
    ),

    'tesla': CardGuideData(
      name: 'Tesla',
      role: CardRole.building,
      description:
          'Defende underground até ser ativado — atordoa e tem alto DPS, especialmente eficaz no X-Bow.',
      tips: [
        'OBRIGATÓRIO no deck de X-Bow — protege a building principal.',
        'Fica underground até ser ativado: adversário não sabe onde está até revelar.',
        'Use como kiter para Hog Rider e outras tropas terrestres.',
        'Combine com Ice Spirit para defesa de custo mínimo com reset integrado.',
      ],
      synergies: ['X-Bow', 'Ice Spirit', 'Skeletons', 'Log'],
      counters: ['Earthquake', 'Rocket', 'Giant'],
      bestDecks: ['X-Bow Siege', 'Hog Cycle'],
    ),

    'inferno tower': CardGuideData(
      name: 'Inferno Tower',
      role: CardRole.building,
      description:
          'Dano crescente que mata qualquer tanque em segundos — o melhor anti-tank do jogo.',
      tips: [
        'Counter definitivo para Golem, Giant, Balloon e qualquer tanque pesado.',
        'Posicione com antecedência antes do push chegar — não coloque na última hora.',
        'O Zap ou Electro Wizard do adversário reseta o dano — combine com Tornado para evitar.',
        'Excelente no Log Bait para defender pushes pesadas enquanto Goblin Barrel contra-ataca.',
      ],
      synergies: ['Log Bait', 'Goblin Barrel', 'Princess', 'Tornado'],
      counters: ['Zap', 'Electro Wizard', 'Electro Spirit', 'Lightning'],
      bestDecks: ['Log Bait', 'Control', 'Graveyard Control'],
    ),

    'tombstone': CardGuideData(
      name: 'Tombstone',
      role: CardRole.building,
      description:
          'Building que invoca esqueletos periodicamente e ao morrer spawna mais — kiter perfeito.',
      tips: [
        'Posicione ao centro para kitar Hog Rider, Prince e tropas rápidas.',
        'Os esqueletos gerados distraem tropas inimiges e servem como mini-defesa.',
        'Combine com Lava Hound/LavaLoon: Tombstone kita terrestres enquanto o push aéreo avança.',
        'Ao morrer, cria uma última leva de esqueletos — boa para atrasar mais.',
      ],
      synergies: ['Lava Hound', 'Balloon', 'Miner', 'Knight'],
      counters: ['Fireball', 'Zap', 'Log'],
      bestDecks: ['LavaLoon', 'Miner Control', 'Graveyard'],
    ),

    'bomb tower': CardGuideData(
      name: 'Bomb Tower',
      role: CardRole.building,
      description:
          'Lança bombas de área — excelente contra enxames e difícil de ignorar pelo splash.',
      tips: [
        'Counter para grupos de tropas: Goblin Gang, Skeleton Army, Rascals.',
        'Combine com Wall Breakers: Bomb Tower defende a base enquanto os Wall Breakers atacam.',
        'O splash em área faz de longe — posicione no lado para máxima cobertura.',
        'Use em decks de controle que precisam de defesa de área sustentada.',
      ],
      synergies: ['Wall Breakers', 'Miner', 'Knight', 'Spear Goblins'],
      counters: ['Giant', 'Rocket', 'Earthquake'],
      bestDecks: ['Wall Breakers Cycle', 'Miner Control'],
    ),

    'goblin hut': CardGuideData(
      name: 'Goblin Hut',
      role: CardRole.building,
      description:
          'Spawna Spear Goblins continuamente — pressão constante de baixo custo.',
      tips: [
        'Coloque logo no início para começar a acumular Spear Goblins cedo.',
        'Combine com outros spawners (Furnace, Barbarian Hut) para pressão de múltiplas lanes.',
        'Os Spear Goblins gerados são bons para atacar aéreos — cobertura passiva.',
        'Use deck de spawners: Goblin Hut + Barbarian Hut + Furnace + win condition.',
      ],
      synergies: ['Furnace', 'Barbarian Hut', 'Hog Rider', 'Three Musketeers'],
      counters: ['Rocket', 'Fireball', 'Lightning'],
      bestDecks: ['Spawner Cycle', 'Goblin Hut Control'],
    ),

    'furnace': CardGuideData(
      name: 'Furnace',
      role: CardRole.building,
      description:
          'Spawna Fire Spirits periodicamente — pressão constante que o adversário precisa responder.',
      tips: [
        'Combine com Royal Giant: Royal Giant tanqueia, Fire Spirits protegem os flancos.',
        'Os Fire Spirits causam dano em área — bons contra grupos de tropas baratas.',
        'Coloque cedo para acumular a maioria possível de Fire Spirits durante a partida.',
        'Use em decks de spawner para pressão contínua sem gastar elixir.',
      ],
      synergies: ['Royal Giant', 'Goblin Hut', 'Hog Rider'],
      counters: ['Rocket', 'Fireball', 'Lightning'],
      bestDecks: ['Royal Giant Furnace', 'Spawner'],
    ),

    'elixir collector': CardGuideData(
      name: 'Elixir Collector',
      role: CardRole.building,
      description:
          'Gera elixir extra ao longo do tempo — fundamental em decks pesados como Three Musketeers.',
      tips: [
        'OBRIGATÓRIO no Three Musketeers: use primeiro para atrair o feitiço pesado inimigo.',
        'Coloque ao início da partida para começar a ganhar vantagem de elixir.',
        'Adversário que joga Rocket no Elixir Collector faz troca neutra — ok no início.',
        'Em Golem Beatdown, ajuda a construir o push de alto custo mais rapidamente.',
      ],
      synergies: ['Three Musketeers', 'Golem', 'Giant', 'Balloon'],
      counters: ['Rocket', 'Fireball', 'Lightning'],
      bestDecks: ['Three Musketeers', 'Golem Beatdown'],
    ),

    'barbarian hut': CardGuideData(
      name: 'Barbarian Hut',
      role: CardRole.building,
      description:
          'Spawna pares de Bárbaros continuamente — pressão terrestre sustentada.',
      tips: [
        'Coloque cedo para maximizar o número de Bárbaros gerados.',
        'Os Bárbaros são terrestres — combine com unidades aéreas para defesa completa.',
        'Decks de spawner com Goblin Hut + Barbarian Hut criam pressão de múltiplas frentes.',
        'Custo alto (7 elixir) — garanta que vai ficar em campo o suficiente para compensar.',
      ],
      synergies: ['Goblin Hut', 'Furnace', 'Hog Rider'],
      counters: ['Rocket', 'Fireball', 'Lightning'],
      bestDecks: ['Spawner', 'Barbarian Hut Cycle'],
    ),

    'goblin cage': CardGuideData(
      name: 'Goblin Cage',
      role: CardRole.building,
      description:
          'Cage que ao ser destruída solta o Goblin Brawler que vai para a torre adversária.',
      tips: [
        'O Brawler que sai é forte — posicione onde ele terá caminho livre para a torre.',
        'Use como building defensiva que gera contra-ataque automático.',
        'Combine com Miner: o Brawler vai para a torre enquanto o Miner também vai.',
        'No Graveyard Control, serve como building para kitar tropas terrestres.',
      ],
      synergies: ['Miner', 'Ice Wizard', 'Graveyard', 'Hog Rider'],
      counters: ['Fireball', 'Rocket', 'Giant'],
      bestDecks: ['Miner Control', 'Graveyard Control'],
    ),

    // ── Other Support ─────────────────────────────────────────────────────────

    'lumberjack': CardGuideData(
      name: 'Lumberjack',
      role: CardRole.support,
      description:
          'Tropa rápida que ao morrer libera um Rage (velocidade) para tropas aliadas.',
      tips: [
        'O Rage liberado após a morte potencializa qualquer push — timing certo é crucial.',
        'Posicione atrás do Golem/Giant: quando morrer, o Rage acelera o tanque.',
        'Use na frente do Graveyard: os esqueletos ficam na Rage e atacam muito mais rápido.',
        'Alta velocidade de movimento — use sozinho no bridge para pressão rápida.',
      ],
      synergies: ['Golem', 'Giant', 'Graveyard', 'Balloon'],
      counters: ['Fireball', 'Lightning', 'Mega Knight'],
      bestDecks: ['Golem Beatdown', 'Lumberjack Balloon'],
    ),

    'executioner': CardGuideData(
      name: 'Executioner',
      role: CardRole.support,
      description:
          'Lança seu machado que vai e volta causando splash em área — counter para enxames.',
      tips: [
        'O machado vai E volta — cada tropa no caminho leva dois golpes.',
        'Combine com Tornado: Tornado agrupa, Executioner causa splash em todos.',
        'Counter para Skeleton Army, Goblin Gang e qualquer enxame densamente agrupado.',
        'Use no Hog Exnado (Hog + Executioner + Tornado) — o trio mais defensivo do jogo.',
      ],
      synergies: ['Tornado', 'Hog Rider', 'Valkyrie', 'Cannon'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Hog Exnado', 'Control'],
    ),

    'guards': CardGuideData(
      name: 'Guards',
      role: CardRole.swarm,
      description:
          'Trio de esqueletos com escudos — absorvem mais dano que esqueletos normais.',
      tips: [
        'Os escudos absorvem um golpe extra — melhor que Skeletons contra algumas tropas.',
        'Use para kitar Hog Rider, Prince e outras tropas de alto dano.',
        'Counter para Miner: os Guards distraem e eliminam o Miner rapidamente.',
        'Combine com Graveyard: Guards servem como tanks para o Graveyard se estabelecer.',
      ],
      synergies: ['Graveyard', 'X-Bow', 'Miner', 'Skeleton King'],
      counters: ['Log', 'Zap', 'Fireball'],
      bestDecks: ['Graveyard Control', 'X-Bow Siege'],
    ),

    'hunter': CardGuideData(
      name: 'Hunter',
      role: CardRole.support,
      description:
          'Dispara múltiplos projéteis por golpe — dano altíssimo de curto alcance.',
      tips: [
        'Counter absoluto para tanques no range curto — Golem e Giant morrem rapidamente.',
        'Posicione atrás de um mini-tank para maximizar o tempo em range.',
        'Em Three Musketeers, o Hunter serve como suporte de DPS de curto alcance.',
        'Contra Balloon: posicione no centro para todos os projéteis acertarem.',
      ],
      synergies: ['Three Musketeers', 'Ice Golem', 'Giant', 'Knight'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Three Musketeers', 'Hunter Control'],
    ),

    'dart goblin': CardGuideData(
      name: 'Dart Goblin',
      role: CardRole.support,
      description:
          'Tropa de ataque rápido e longo alcance por apenas 3 elixir — ciclo e suporte.',
      tips: [
        'Longo alcance: pode atacar tropas aéreas sem entrar no range de muitas defesas.',
        'Extremamente rápido — envia muitos projéteis por segundo.',
        'Use no Log Bait para forçar o feitiço adversário (Log ou Arrows o eliminam).',
        'Posicione atrás de um tanque para máxima longevidade no push.',
      ],
      synergies: ['Goblin Barrel', 'Goblin Gang', 'Princess', 'Giant'],
      counters: ['Log', 'Zap', 'Arrows'],
      bestDecks: ['Log Bait', 'Mortar Bait'],
    ),

    'princess': CardGuideData(
      name: 'Princess',
      role: CardRole.support,
      description:
          'Atira flechas de área de altíssimo alcance — a isca mais poderosa do Log Bait.',
      tips: [
        'O alcance dela cobre quase metade do mapa — coloque na torre e ela já atinge a lado inimigo.',
        'No Log Bait, ela é a isca principal — adversário PRECISA usar Log ou Arrows.',
        'Use para eliminar grupos de tropas atrás de um tanque antes de formarem push.',
        'Combine com Goblin Barrel: force o adversário a escolher qual ameaça responder.',
      ],
      synergies: ['Goblin Barrel', 'Goblin Gang', 'Dart Goblin', 'Inferno Tower'],
      counters: ['Log', 'Arrows', 'Zap'],
      bestDecks: ['Log Bait'],
    ),

    'firecracker': CardGuideData(
      name: 'Firecracker',
      role: CardRole.support,
      description:
          'Tropa que atira em linha reta através de várias tropas — alto DPS contra grupos lineares.',
      tips: [
        'Posicione centralmente para que o projétil atravesse o máximo de tropas.',
        'Ao morrer, explode causando dano em área — similar ao Goblin Barrel de morte.',
        'Use no X-Bow: Firecracker atrás do X-Bow causa dano de área nas tropas defensivas.',
        'Combine com Tornado para agrupar tropas no caminho do projétil.',
      ],
      synergies: ['X-Bow', 'Tornado', 'Giant', 'Hog Rider'],
      counters: ['Fireball', 'Log', 'Zap'],
      bestDecks: ['X-Bow Siege', 'Control'],
    ),

    'magic archer': CardGuideData(
      name: 'Magic Archer',
      role: CardRole.support,
      description:
          'Flechas mágicas que atravessam tropas e causam dano em linha — alto alcance e penetração.',
      tips: [
        'Posicione para que a flecha passe por várias tropas — máximo valor quando alinhado.',
        'Pode atacar a Torre do Rei de longe enquanto atinge tropas no caminho.',
        'Combine com Mortar: Mortar força o adversário a avançar, Magic Archer os atinge na linha.',
        'Counter para Graveyard: a flecha atravessa múltiplos esqueletos de uma vez.',
      ],
      synergies: ['Mortar', 'X-Bow', 'Tornado', 'Giant'],
      counters: ['Fireball', 'Lightning'],
      bestDecks: ['Mortar Cycle', 'X-Bow', 'Control'],
    ),

    'archers': CardGuideData(
      name: 'Archers',
      role: CardRole.support,
      description:
          'Duas arqueiras de longo alcance — custo-benefício excelente para defesa aérea.',
      tips: [
          'Duas unidades que se separam — mais difícil de eliminar com um único Zap.',
          'Use como alternativa à Musketeer quando precisar de custo mais baixo.',
          'Excelente no X-Bow para defesa aérea de 3 elixir.',
          'Split na arena para pressão simultânea nas duas lanes.',
      ],
      synergies: ['X-Bow', 'Mortar', 'Giant', 'Hog Rider'],
      counters: ['Arrows', 'Fireball', 'Zap'],
      bestDecks: ['X-Bow Siege', 'Mortar Cycle'],
    ),

    'bandit': CardGuideData(
      name: 'Bandit',
      role: CardRole.support,
      description:
          'Tropa com traço invisível que carrega e causa dano extra — difícil de kitar.',
      tips: [
        'A imunidade ao dano durante o traço torna ela quase impossível de parar em movimento.',
        'Use no bridge no PEKKA Bridge Spam: PEKKA defende, Bandit pressiona.',
        'Combine com Royal Ghost para push dual que o adversário tem dificuldade de separar.',
        'O dash também reseta Inferno Tower se calculado corretamente.',
      ],
      synergies: ['Pekka', 'Dark Prince', 'Royal Ghost', 'Golden Knight'],
      counters: ['Skeleton Army', 'Tornado', 'Arrows'],
      bestDecks: ['PEKKA Bridge Spam'],
    ),

    'royal ghost': CardGuideData(
      name: 'Royal Ghost',
      role: CardRole.support,
      description:
          'Fica invisível até atacar — spawna oculto e surpreende o adversário.',
      tips: [
        'Spawn invisível: o adversário não sabe onde está até o primeiro ataque.',
        'Use no bridge junto ao Battle Ram ou PEKKA no Bridge Spam.',
        'A invisibilidade dura vários segundos — posicione estrategicamente.',
        'Quando descoberto, tem bom dano — aproveite o elemento surpresa no início.',
      ],
      synergies: ['Pekka', 'Battle Ram', 'Bandit', 'Electro Wizard'],
      counters: ['Arrows', 'Fireball', 'Tornado'],
      bestDecks: ['PEKKA Bridge Spam'],
    ),

    'cannon cart': CardGuideData(
      name: 'Cannon Cart',
      role: CardRole.support,
      description:
          'Carrega para a bridge e depois transforma em Cannon defensivo — híbrido único.',
      tips: [
        'Quando entra em modo Cannon, serve como building defensiva — dupla funcionalidade.',
        'Use no bridge para pressão e quando defender transforma em Cannon no local.',
        'Combine com PEKKA: Cannon Cart age como win condition secundário no Bridge Spam.',
        'O modo Cannon tem mais HP que um Cannon normal — mais durável na defesa.',
      ],
      synergies: ['Pekka', 'Electro Wizard', 'Battle Ram'],
      counters: ['Mini Pekka', 'Inferno Dragon', 'Earthquake'],
      bestDecks: ['PEKKA Bridge Spam'],
    ),

    'sparky': CardGuideData(
      name: 'Sparky',
      role: CardRole.support,
      description:
          'Acumula carga e libera raio elétrico de área massivo — devastadora quando não resetada.',
      tips: [
        'O maior perigo: Sparky PRECISA ser resetada — Zap, Electro Spirit ou Electro Wizard.',
        'Combine com Goblin Giant: os Spear Goblins do Giant protegem a Sparky.',
        'Posicione atrás do tanque para maximizar o tempo antes de sofrer dano.',
        'Uma Sparky carregada que atinge um grupo de tropas é uma eliminação garantida.',
      ],
      synergies: ['Goblin Giant', 'Giant', 'Ice Golem', 'Electro Wizard'],
      counters: ['Zap', 'Electro Spirit', 'Electro Wizard', 'Log'],
      bestDecks: ['Goblin Giant Sparky', 'Sparky Beatdown'],
    ),

    'electro dragon': CardGuideData(
      name: 'Electro Dragon',
      role: CardRole.airUnit,
      description:
          'Dragão elétrico que encadeia raio em múltiplas tropas — bom em área elétrica.',
      tips: [
        'O raio encadeado atinge até 3 alvos em sequência — excelente contra grupos.',
        'Use no Elixir Golem: atordoa as tropas que vêm matar os blobs de elixir.',
        'Combine com Baby Dragon para cobertura aérea dupla e splash.',
        'Counter para Minions e outros grupos aéreos com o encadeamento do raio.',
      ],
      synergies: ['Elixir Golem', 'Battle Healer', 'Baby Dragon', 'Giant'],
      counters: ['Minion Horde', 'Arrows', 'Fireball'],
      bestDecks: ['Elixir Golem Beatdown'],
    ),

    // ── Champions ─────────────────────────────────────────────────────────────

    'archer queen': CardGuideData(
      name: 'Archer Queen',
      role: CardRole.champion,
      description:
          'Campeã de ataque à distância que fica invisível e invoca arqueiras com sua habilidade.',
      tips: [
        'Habilidade: Cloaking Strike — ativa quando sob ataque para ficar invisível e invocar arqueiras.',
        'Ideal no Log Bait: a habilidade força o adversário a gastar mais um feitiço.',
        'Posicione atrás do Goblin Barrel push para criar pressão dupla.',
        'Combine com Hog Rider: Archer Queen suporta o push e ativa quando defensores chegam.',
      ],
      synergies: ['Goblin Barrel', 'Hog Rider', 'Princess', 'Fireball'],
      counters: ['Arrows', 'Fireball', 'Rocket'],
      bestDecks: ['Log Bait', 'Hog Cycle'],
    ),

    'golden knight': CardGuideData(
      name: 'Golden Knight',
      role: CardRole.champion,
      description:
          'Cavaleiro campeão que atravessa toda a arena atordoando inimigos com seu Dashing Dash.',
      tips: [
        'Habilidade: Dashing Dash — atravessa o mapa atordoando cada tropa no caminho.',
        'Use o Dash junto ao Battle Ram: dois win conditions chegando simultaneamente.',
        'No Bridge Spam, o Dash ativa após uma defesa para surpreender o adversário.',
        'O atordoamento do Dash reseta Inferno Tower e Sparky automaticamente.',
      ],
      synergies: ['Battle Ram', 'Skeleton Army', 'Bandit', 'Pekka'],
      counters: ['Fireball', 'Arrows', 'Skeleton Army'],
      bestDecks: ['PEKKA Bridge Spam', 'Battle Ram Golden Knight'],
    ),

    'skeleton king': CardGuideData(
      name: 'Skeleton King',
      role: CardRole.champion,
      description:
          'Rei dos esqueletos que coleta almas de tropas mortas para invocar um exército de esqueletos.',
      tips: [
        'Habilidade: Soul Summoning — ativa quando em combate para invocar um enxame de esqueletos.',
        'Mais eficaz em decks com muitas tropas baratas que morrem rapidamente (muitas almas).',
        'Combine com Graveyard: os esqueletos do Graveyard fornecem almas para o Skeleton King.',
        'O exército invocado tem bom DPS coletivo — use para limpezas defensivas.',
      ],
      synergies: ['Graveyard', 'Skeleton Army', 'Night Witch', 'Giant'],
      counters: ['Arrows', 'Fireball', 'Valkyrie'],
      bestDecks: ['Graveyard Control', 'Skeleton King Beatdown'],
    ),

    'mighty miner': CardGuideData(
      name: 'Mighty Miner',
      role: CardRole.champion,
      description:
          'Minerador campeão que perfura a terra diretamente para a torre com sua habilidade.',
      tips: [
        'Habilidade: Drill Charge — cava para a torre adversária causando dano bônus.',
        'Sinergia direta com Miner: dois win conditions que entram pelo chão.',
        'Use no Wall Breakers deck: Mighty Miner + Wall Breakers = pressão de múltiplos lados.',
        'A habilidade é mais eficaz no final do jogo para garantir o dano à torre.',
      ],
      synergies: ['Miner', 'Wall Breakers', 'Poison', 'Goblin Gang'],
      counters: ['Inferno Tower', 'Skeleton Army', 'Guards'],
      bestDecks: ['Miner Control', 'Wall Breakers Cycle'],
    ),

    'monk': CardGuideData(
      name: 'Monk',
      role: CardRole.champion,
      description:
          'Monge de alto HP que reflete projéteis com sua habilidade de proteção.',
      tips: [
        'Habilidade: Pensive Protection — deflecte todos os projéteis por alguns segundos.',
        'Use quando o adversário está jogando Lightning, Fireball ou Rocket no push.',
        'Posicione à frente do Golem/Giant: o Monk absorve feitiços que iam destruir o push.',
        'Contra decks de spell pesada, o Monk pode anular completamente o counter do adversário.',
      ],
      synergies: ['Golem', 'Giant', 'Graveyard', 'Night Witch'],
      counters: ['Pekka', 'Mini Pekka', 'Mega Knight'],
      bestDecks: ['Golem Beatdown', 'Graveyard Control'],
    ),

    'little prince': CardGuideData(
      name: 'Little Prince',
      role: CardRole.champion,
      description:
          'Príncipe pequeno que invoca uma Shield Maiden para proteção com sua habilidade real.',
      tips: [
        'Habilidade: Royal Rescue — invoca Shield Maiden que serve como mini-tank de proteção.',
        'Shield Maiden criada tem HP considerável — essentially ganha uma tropa extra.',
        'Use em decks de controle para manter pressão constante e baixo custo.',
        'A Shield Maiden também ataca — duas ameaças pelo preço de uma habilidade.',
      ],
      synergies: ['Giant', 'Miner', 'Hog Rider', 'Graveyard'],
      counters: ['Fireball', 'Lightning', 'Arrows'],
      bestDecks: ['Control', 'Miner Control', 'Giant'],
    ),

    'magician': CardGuideData(
      name: 'Magician',
      role: CardRole.champion,
      description:
          'Mago campeão que cria um clone temporário com sua Grand Illusion — suporte de splash.',
      tips: [
        'Habilidade: Grand Illusion — cria um clone que ataca e divide o foco inimigo.',
        'O clone tem o mesmo ataque de splash — dobra o dano de área temporariamente.',
        'Use em decks de ciclo para suporte barato de área com habilidade impactante.',
        'Combine com Mortar: Magician cobre os flancos enquanto Mortar faz dano à distância.',
      ],
      synergies: ['Mortar', 'Hog Rider', 'Giant', 'Miner'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Mortar Cycle', 'Control'],
    ),

    // ── Evolutions ────────────────────────────────────────────────────────────

    'evo hog rider': CardGuideData(
      name: 'Evo Hog Rider',
      role: CardRole.evolution,
      description:
          'Hog Rider evoluído que carrega até a torre sem parar ao ser colocado na bridge.',
      tips: [
        'Na evolução, vai DIRETO à torre — não para para atacar tropas no caminho.',
        'Counter para posicionamentos defensivos que dependem de parar o Hog no meio do campo.',
        'O maior upgrade de win condition disponível — prioridade em qualquer Hog Cycle.',
        'Combine com Musketeer ou Ice Golem atrás para suporte enquanto ele alcança a torre.',
      ],
      synergies: ['Musketeer', 'Ice Golem', 'Cannon', 'Fireball'],
      counters: ['Inferno Tower', 'Tesla', 'Skeleton Army'],
      bestDecks: ['Hog Cycle', 'Hog Exnado'],
    ),

    'evo goblin barrel': CardGuideData(
      name: 'Evo Goblin Barrel',
      role: CardRole.evolution,
      description:
          'Goblin Barrel evoluído com 4 goblins (em vez de 3) e entrega mais rápida.',
      tips: [
        'Quatro goblins causam mais dano por segundo — a torre morre mais rápido.',
        'Entrega mais rápida: menos tempo de reação para o adversário jogar o Log.',
        'O 4º goblin extra garante dano mesmo se o Log pegar 3 deles.',
        'No Log Bait, é o upgrade mais importante disponível — inclua sempre.',
      ],
      synergies: ['Princess', 'Dart Goblin', 'Goblin Gang', 'Archer Queen'],
      counters: ['Arrows', 'Log', 'Zap'],
      bestDecks: ['Log Bait'],
    ),

    'evo skeletons': CardGuideData(
      name: 'Evo Skeletons',
      role: CardRole.evolution,
      description:
          'Esqueletos evoluídos que saltam sobre inimigos causando dano de queda.',
      tips: [
        'O salto causa dano extra — posicione para maximizar os esqueletos em alcance.',
        'Excelente como ciclador: 1 elixir com dano bônus do salto.',
        'Use para kitar tropas como sempre, mas agora com dano de entrada adicional.',
        'No Hog Cycle, substitui os Skeletons normais para mais dano na defesa.',
      ],
      synergies: ['Hog Rider', 'X-Bow', 'Tornado'],
      counters: ['Zap', 'Log', 'Arrows'],
      bestDecks: ['Hog Cycle', 'X-Bow Siege'],
    ),

    'evo knight': CardGuideData(
      name: 'Evo Knight',
      role: CardRole.evolution,
      description:
          'Knight evoluído que ganha escudo ao entrar no campo — mais durável na defesa.',
      tips: [
        'O escudo inicial absorbe mais dano — sobrevive mais tempo no push.',
        'Use no Hog Cycle em vez do Knight normal para mais durabilidade.',
        'O escudo da evolução ativa ao spawnar — mais HP efetivo desde o início.',
        'Combine com Musketeer: Evo Knight tanqueia ainda mais enquanto Musketeer causa dano.',
      ],
      synergies: ['Hog Rider', 'Musketeer', 'Miner', 'Poison'],
      counters: ['Fireball', 'Pekka', 'Mini Pekka'],
      bestDecks: ['Hog Cycle', 'Miner Control'],
    ),

    'evo archers': CardGuideData(
      name: 'Evo Archers',
      role: CardRole.evolution,
      description:
          'Arqueiras evoluídas que se dividem em duas arqueiras individuais cobrindo ambas as lanes.',
      tips: [
        'Ao evoluir, as duas arqueiras se separam e vão para lanes diferentes — pressão dupla.',
        'Cobertura de ambas as lanes simultaneamente por apenas 3 elixir na evolução.',
        'Use em substituição à Musketeer para pressão mais ampla.',
        'Combine com Giant ou Hog Rider: as arqueiras atiram nas torres enquanto o tanque avança.',
      ],
      synergies: ['Giant', 'Hog Rider', 'X-Bow', 'Golem'],
      counters: ['Arrows', 'Fireball', 'Zap'],
      bestDecks: ['Giant Beatdown', 'X-Bow'],
    ),

    'evo barbarians': CardGuideData(
      name: 'Evo Barbarians',
      role: CardRole.evolution,
      description:
          'Bárbaros evoluídos que já chegam enraivecidos (Rage) — burst de dano imediato.',
      tips: [
        'Já vêm com velocidade máxima — chegam mais rápido aos alvos.',
        'Use na defesa para reagir mais rápido a Hog Rider e pushes terrestres.',
        'No Hog Cycle, servem como defesa de emergência que também pode contra-atacar.',
        'Cinco bárbaros enraivecidos eliminam quase qualquer tropa em segundos.',
      ],
      synergies: ['Hog Rider', 'Goblin Barrel', 'Log', 'Cannon'],
      counters: ['Fireball', 'Arrows', 'Wizard'],
      bestDecks: ['Hog Cycle', 'Log Bait'],
    ),

    'evo ice spirit': CardGuideData(
      name: 'Evo Ice Spirit',
      role: CardRole.evolution,
      description:
          'Ice Spirit evoluído com raio de congelamento muito maior — defesa de área aprimorada.',
      tips: [
        'O raio de congelamento cobre uma área muito maior — congela grupos inteiros.',
        'Por 1 elixir, é o melhor reset de área disponível no jogo.',
        'Combine com Tornado: Evo Ice Spirit congela o grupo que o Tornado agrupou.',
        'No Hog Cycle, substitui o Ice Spirit normal para defesa de área muito superior.',
      ],
      synergies: ['Hog Rider', 'Tornado', 'X-Bow', 'Musketeer'],
      counters: ['Zap', 'Arrows'],
      bestDecks: ['Hog Cycle', 'X-Bow Siege'],
    ),

    'evo valkyrie': CardGuideData(
      name: 'Evo Valkyrie',
      role: CardRole.evolution,
      description:
          'Valkyrie evoluída que gira durante todo o movimento — splash contínuo enquanto anda.',
      tips: [
        'Gira em área enquanto se move — qualquer tropa que cruzar o caminho leva dano.',
        'O splash durante o movimento é devastador contra grupos de tropas.',
        'Upgrade direto da Valkyrie no Hog Exnado — muito mais eficaz contra swarms.',
        'Posicione no centro para maximizar as tropas atingidas durante o movimento.',
      ],
      synergies: ['Hog Rider', 'Executioner', 'Tornado', 'Musketeer'],
      counters: ['Fireball', 'Rocket', 'Pekka'],
      bestDecks: ['Hog Exnado', 'Hog Cycle'],
    ),

    'evo firecracker': CardGuideData(
      name: 'Evo Firecracker',
      role: CardRole.evolution,
      description:
          'Firecracker evoluída que dispara em três direções ao morrer — dano de área triplo.',
      tips: [
        'Ao morrer, dispara em 3 direções — posicione para maximizar o dano de morte.',
        'No X-Bow, serve como defesa de área que ainda causa dano ao ser eliminada.',
        'Combine com X-Bow: enquanto o X-Bow ataca, a Evo Firecracker defende os flancos.',
        'Contra decks de cycle, os três disparos de morte causam chip dano significativo.',
      ],
      synergies: ['X-Bow', 'Tornado', 'Giant', 'Hog Rider'],
      counters: ['Fireball', 'Log', 'Zap'],
      bestDecks: ['X-Bow Siege', 'Control'],
    ),

    'evo tesla': CardGuideData(
      name: 'Evo Tesla',
      role: CardRole.evolution,
      description:
          'Tesla evoluída que fica permanentemente ativa (sem ir underground) — DPS constante.',
      tips: [
        'Sempre ativa: não há delay de ativação — começa a defender imediatamente.',
        'DPS mais alto que a Tesla normal — mata win conditions mais rápido.',
        'No X-Bow, é o maior upgrade de defesa disponível.',
        'Use no Hog Cycle em vez da Cannon para defesa de alto DPS.',
      ],
      synergies: ['X-Bow', 'Ice Spirit', 'Skeletons', 'Log'],
      counters: ['Earthquake', 'Rocket', 'Giant'],
      bestDecks: ['X-Bow Siege', 'Hog Cycle'],
    ),

    'evo musketeer': CardGuideData(
      name: 'Evo Musketeer',
      role: CardRole.evolution,
      description:
          'Musketeer evoluída que dispara três projéteis por vez que penetram tropas — DPS triplo.',
      tips: [
        'Três projéteis por disparo que penetram: atinge múltiplas tropas em linha.',
        'Usado no Golem Beatdown como upgrade de DPS massivo no push.',
        'Contra grupos de tropas alinhadas, os três projéteis causam dano triplicado.',
        'Combine com Golem: Evo Musketeer cobre flancos E causa dano de penetração.',
      ],
      synergies: ['Golem', 'Giant', 'Hog Rider', 'Ice Golem'],
      counters: ['Fireball', 'Lightning', 'Rocket'],
      bestDecks: ['Golem Beatdown', 'Giant Beatdown'],
    ),

    'evo bats': CardGuideData(
      name: 'Evo Bats',
      role: CardRole.evolution,
      description:
          'Bats evoluídos que spawnam mais rápido e em maior quantidade — enxame aéreo aprimorado.',
      tips: [
        'Mais morcegos e mais rápidos: harder to respond to with spells.',
        'Use no Wall Breakers para ciclo ultra-rápido ainda mais eficiente.',
        'Counter aprimorado para terrestres que não atingem aéreos.',
        'Combine com Miner: Evo Bats cobrem o ar enquanto Miner faz dano à torre.',
      ],
      synergies: ['Wall Breakers', 'Miner', 'Ram Rider'],
      counters: ['Zap', 'Arrows', 'Wizard'],
      bestDecks: ['Wall Breakers Cycle', 'Miner Control'],
    ),

    'evo mortar': CardGuideData(
      name: 'Evo Mortar',
      role: CardRole.evolution,
      description:
          'Mortar evoluído que dispara dois projéteis simultaneamente — dano de área dobrado.',
      tips: [
        'Dois morteiros em vez de um: dano e pressão muito maiores.',
        'No Mortar Cycle, é um upgrade que torna o deck muito mais agressivo.',
        'Posicione no centro para maximizar o alcance de ambos os projéteis.',
        'Com Rocket, o Evo Mortar cria pressão de dano à torre quase impossível de defender.',
      ],
      synergies: ['Rocket', 'Knight', 'Ice Spirit', 'Miner'],
      counters: ['Earthquake', 'Rocket', 'Giant'],
      bestDecks: ['Mortar Cycle'],
    ),

    'evo royal giant': CardGuideData(
      name: 'Evo Royal Giant',
      role: CardRole.evolution,
      description:
          'Royal Giant evoluído que ganha escudo renovável a cada push — mais durável.',
      tips: [
        'O escudo regenera a cada novo push — praticamente impossível de eliminar rapidamente.',
        'Use no Royal Giant Cycle como upgrade direto e poderoso.',
        'Combine com Electro Wizard para reset de Inferno enquanto o escudo absorve dano.',
        'O escudo torna o Evo Royal Giant ainda mais difícil de counter com Inferno.',
      ],
      synergies: ['Electro Wizard', 'Furnace', 'Mega Minion', 'Fireball'],
      counters: ['Lightning', 'Pekka', 'Rocket'],
      bestDecks: ['Royal Giant Cycle'],
    ),

    'evo dark prince': CardGuideData(
      name: 'Evo Dark Prince',
      role: CardRole.evolution,
      description:
          'Dark Prince evoluído que carrega a distâncias muito maiores — carga devastadora.',
      tips: [
        'Carga de distância muito maior: pode iniciar do seu próprio lado da arena.',
        'Use no PEKKA Bridge Spam para carga surpresa de longa distância.',
        'Combine com PEKKA: Dark Prince carrega longo, PEKKA defende e contra-ataca.',
        'O splash da carga atinge mais tropas pelo maior alcance do dash.',
      ],
      synergies: ['Pekka', 'Bandit', 'Battle Ram', 'Royal Ghost'],
      counters: ['Inferno Dragon', 'Tornado', 'Mega Knight'],
      bestDecks: ['PEKKA Bridge Spam'],
    ),

    'evo mega knight': CardGuideData(
      name: 'Evo Mega Knight',
      role: CardRole.evolution,
      description:
          'Mega Knight evoluído com área de salto e queda muito maior — AoE devastador.',
      tips: [
        'A área de salto inicial é muito maior — posicione onde há mais tropas agrupadas.',
        'Use na defesa para eliminar grupos inteiros de tropas de uma vez.',
        'Combine com Balloon para push aéreo + terrestre: Evo Mega Knight limpa, Balloon chega à torre.',
        'Impacto de entrada muito maior — wait for the enemy to group up before dropping.',
      ],
      synergies: ['Balloon', 'Night Witch', 'Skeleton Army', 'Sparky'],
      counters: ['Inferno Dragon', 'Pekka', 'Tornado + Tower'],
      bestDecks: ['Mega Knight Balloon', 'Mega Knight Beatdown'],
    ),

    'evo giant skeleton': CardGuideData(
      name: 'Evo Giant Skeleton',
      role: CardRole.evolution,
      description:
          'Giant Skeleton evoluído com bomba de morte de maior HP e alcance — explosão devastadora.',
      tips: [
        'A bomba de morte tem mais HP — mais difícil para o adversário destruí-la antes de explodir.',
        'O raio de explosão é maior — cobre mais área ao detonar.',
        'Combine com Tornado para arrastar tropas para perto da bomba antes de explodir.',
        'Use como win condition de alto impacto: o adversário precisa gastar muito para defendê-lo.',
      ],
      synergies: ['Dark Prince', 'Night Witch', 'Mirror', 'Tornado'],
      counters: ['Pekka', 'Inferno Tower', 'Lightning'],
      bestDecks: ['Giant Skeleton Push'],
    ),

    'evo cannon': CardGuideData(
      name: 'Evo Cannon',
      role: CardRole.evolution,
      description:
          'Cannon evoluído com targeting mais rápido e cadência de disparo maior — DPS aprimorado.',
      tips: [
        'Targeting mais rápido: mira no Hog Rider ou outros win conditions mais rapidamente.',
        'DPS superior ao Cannon normal — defende com mais eficácia.',
        'Use no Hog Cycle em vez do Cannon regular para melhor defesa.',
        'Combine com Musketeer para defesa terrestre + aérea de alta eficiência.',
      ],
      synergies: ['Hog Rider', 'Musketeer', 'Ice Spirit', 'Fireball'],
      counters: ['Earthquake', 'Rocket', 'Giant'],
      bestDecks: ['Hog Cycle'],
    ),

    'evo electro dragon': CardGuideData(
      name: 'Evo Electro Dragon',
      role: CardRole.evolution,
      description:
          'Electro Dragon evoluído cujo raio encadeia em mais alvos — AoE elétrico aumentado.',
      tips: [
        'O raio encadeado atinge mais alvos — melhor limpeza de grupos.',
        'Use no Elixir Golem para neutralizar mais tropas que vêm matar os blobs.',
        'Combine com Baby Dragon para cobertura aérea dupla com mais encadeamento.',
        'Counter superior para grupos de Minions e Bats graças ao encadeamento expandido.',
      ],
      synergies: ['Elixir Golem', 'Battle Healer', 'Baby Dragon'],
      counters: ['Minion Horde', 'Fireball', 'Arrows'],
      bestDecks: ['Elixir Golem Beatdown'],
    ),

    'evo three musketeers': CardGuideData(
      name: 'Evo Three Musketeers',
      role: CardRole.evolution,
      description:
          'Three Musketeers evoluídas que se dividem e carregam imediatamente ao spawnar.',
      tips: [
        'A divisão com carga imediata é devastadora — chegam nas lanes mais rápido.',
        'Use no centro como sempre — a evolução amplifica o timing da divisão.',
        'Combine com Elixir Collector: acumule elixir e jogue Evo 3M no momento certo.',
        'A carga inicial ao dividir pode eliminar tropas defensivas antes de chegarem.',
      ],
      synergies: ['Elixir Collector', 'Battle Ram', 'Ice Golem'],
      counters: ['Lightning', 'Fireball', 'Rocket'],
      bestDecks: ['Three Musketeers Split'],
    ),

    'evo bomber': CardGuideData(
      name: 'Evo Bomber',
      role: CardRole.evolution,
      description:
          'Bomber evoluído cujas bombas ricocheteiam em múltiplos alvos — splash em cascata.',
      tips: [
        'As bombas ricocheteiam: posicione onde haverá mais tropas para pegar múltiplos alvos.',
        'Use no Golem Beatdown para suporte de área que atinge vários pontos.',
        'Combine com Baby Dragon: cobertura dupla de splash terrestre e aéreo.',
        'O ricochete é imprevisível para o adversário — difícil de posicionar para evitar.',
      ],
      synergies: ['Golem', 'Giant', 'Night Witch', 'Baby Dragon'],
      counters: ['Fireball', 'Lightning', 'Arrows'],
      bestDecks: ['Golem Beatdown', 'Giant Beatdown'],
    ),
  };

  /// Returns guide data for a card by name (case-insensitive).
  static CardGuideData? forCard(String cardName) {
    return _data[cardName.toLowerCase().trim()];
  }

  /// Returns all card names that have guide data.
  static List<String> get allCardNames =>
      _data.values.map((g) => g.name).toList()..sort();

  /// Returns cards that belong to a given role.
  static List<CardGuideData> byRole(CardRole role) =>
      _data.values.where((g) => g.role == role).toList();

  /// Returns cards that list [cardName] as a synergy.
  static List<CardGuideData> synergyPartners(String cardName) {
    final lower = cardName.toLowerCase().trim();
    return _data.values
        .where((g) =>
            g.synergies.any((s) => s.toLowerCase() == lower) &&
            g.name.toLowerCase() != lower)
        .toList();
  }
}

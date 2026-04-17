# Royale Coach — Implementation Plan

Deep analysis of the codebase revealed strong architecture foundations but significant untapped potential. This plan organizes improvements from highest-impact to most ambitious.

---

## FASE 1 — Supabase Backend Integration

**Por quê**: O `.env` já tem `SUPABASE_URL` e `SUPABASE_ANON_KEY` configurados, mas nenhuma linha de código usa isso. Toda análise de IA é perdida quando o usuário troca de dispositivo. Com Supabase podemos ter sync cross-device, comunidade de decks e histórico persistente.

### 1.1 — Configuração e Autenticação
- Adicionar `supabase_flutter` ao `pubspec.yaml`
- Inicializar `Supabase.initialize()` em `main.dart` antes de `setupDependencies()`
- Registrar `SupabaseClient` no `injection_container.dart`
- Implementar **Anonymous Auth** (sem login obrigatório) — cada install gera um `user_id` único
- Criar fluxo opcional de "Criar Conta" (Google Sign-In) para sincronizar entre dispositivos
- Tela de perfil de usuário (`UserProfileScreen`) com opção de vincular conta Google

**Tabelas Supabase a criar:**
```sql
-- Análises salvas por usuário
create table player_analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users,
  player_tag text not null,
  player_name text,
  analysis jsonb not null,
  archetype text,
  confidence_score float,
  created_at timestamptz default now()
);

-- Decks da comunidade (votados)
create table community_decks (
  id uuid primary key default gen_random_uuid(),
  arena_id int,
  archetype text,
  card_ids text[] not null,
  upvotes int default 0,
  created_by uuid references auth.users,
  created_at timestamptz default now()
);
```

### 1.2 — Cloud Sync de Análises
- Novo datasource: `AiRemoteDatasource` (salva análises no Supabase)
- `AiRepositoryImpl` salva **tanto** no SharedPreferences (local) **quanto** no Supabase (cloud)
- No load: tenta SharedPreferences primeiro (mais rápido), depois Supabase como fallback
- Exibir badge "Sincronizado" na aba IA quando análise vier do Supabase

---

## FASE 2 — Dashboard de Analytics de Batalha

**Por quê**: `CrBattle` contém troféus, decks completos, coroas, horário — mas a aba Batalhas só mostra uma lista. Esse dado vale ouro para o jogador entender sua performance real.

### 2.1 — Reestruturar Aba de Batalhas
- Substituir lista simples por dashboard com abas internas: `Visão Geral | Histórico`
- **Visão Geral** mostra:
  - Win rate dos últimos 20 / 50 / 100 battles (selecionável)
  - Sequência atual (streak) de vitórias/derrotas
  - Ganho/perda de troféus no período
  - Hora do dia com mais vitórias (heatmap por hora)
  - Distribuição de vitórias por tipo (Ladder, Grand Challenge, Clan War)

### 2.2 — Análise de Decks Adversários
- Detectar os arquétipos mais comuns nos decks adversários (usando `ArenaGuide.cardsForDeck()`)
- Mostrar ranking "Você perdeu mais para:" com percentual
- Gráfico de pizza: distribuição de arquétipos adversários
- Widget "Ponto fraco detectado": se perder 70%+ para Beatdown → link para guia de como counterar

### 2.3 — Evolução de Troféus
- Gráfico de linha (`fl_chart` já é dependência) com histórico de troféus
- Marcadores visuais para promoções de arena
- Tendência: "Você está em alta 📈" vs "Você está em queda 📉"

---

## FASE 3 — Deck Builder Interativo

**Por quê**: A análise de IA só analisa o deck atual. O usuário não tem como experimentar combinações antes de testar no jogo. Um deck builder muda isso.

### 3.1 — Tela de Deck Builder
- Nova tela `DeckBuilderScreen` acessível via FAB na aba DECK
- Grade interativa: 8 slots vazios + galeria de cartas da coleção do jogador
- **Drag & drop** de cartas nos slots (usando `LongPressDraggable` + `DragTarget`)
- Cálculo em tempo real:
  - Elixir médio
  - Detecção de arquétipo (baseado nas cartas selecionadas vs padrões do `ArenaGuide`)
  - Alerta de regras violadas (ex: "Sem condição de vitória!", "Sem carta aérea!")
  - Badge de raridade com count de cada raridade

### 3.2 — Análise de Deck Customizado
- Botão "Analisar este Deck" no topo do DeckBuilder
- Chama `AiDatasource._buildDeckAnalysisPrompt` com o deck customizado
- Resultado na mesma tela, em um painel deslizante de baixo para cima
- Botão "Abrir no Clash Royale" com deep link

### 3.3 — Favoritos e Histórico de Decks
- Salvar decks criados no Supabase (`community_decks` table)
- Seção "Meus Decks Salvos" na aba DECK
- Compartilhar deck como imagem (screenshot com `RepaintBoundary`)

---

## FASE 4 — Meta Report Diário

**Por quê**: O jogo muda com patches. Um relatório diário do meta mantém o usuário voltando ao app todos os dias.

### 4.1 — Meta Snapshot por Arena
- Novo datasource `MetaDatasource` que consulta Supabase para buscar dados agregados
- Um Cloud Function (ou cron job no Supabase Edge Functions) agrega:
  - Decks mais usados por arena (coletados anonimamente das análises dos usuários)
  - Win rates por arquétipo por arena
- Tela `MetaReportScreen` com:
  - Ranking "Top 5 Decks da Sua Arena" com botão de importar direto para o Clash Royale
  - Tendências: "Beatdown em alta esta semana" / "Ciclo perdendo espaço"
  - Badge "NOVO" por 24h quando o meta mudar

### 4.2 — Notificações Push
- Integrar `firebase_messaging` para push notifications
- Notificar quando: meta da arena mudar, novo patch Clash Royale detectado, análise semanal pronta
- Configurável pelo usuário (opt-in, não opt-out)

---

## FASE 5 — Roadmap de Evolução de Cartas

**Por quê**: A coleção do jogador já tem `level`, `maxLevel`, `rarity`. Com isso dá para criar um guia de "o que upar primeiro" que é extremamente útil para jogadores mid-game.

### 5.1 — Tela de Roadmap (`CardRoadmapScreen`)
- Novo tab ou seção dentro da aba CARTAS
- **Prioridade de Upgrade** calculada por:
  1. Está em algum deck meta da arena atual? (+3 pontos)
  2. Está no deck sugerido pela IA? (+5 pontos)
  3. Está no deck atual do jogador? (+2 pontos)
  4. Raridade (Común = mais fácil, Lendária = mais difícil) — peso no custo
- Lista ordenada por prioridade com:
  - Card image + nome
  - Nível atual → nível máximo (barra de progresso)
  - Custo estimado em Gold/Wild Cards (fórmula fixa de CR)
  - Badge "META" se estiver em deck meta

### 5.2 — Gráficos da Coleção
- Donut chart: distribuição por raridade (Comum / Raro / Épico / Lendário)
- Barra de progresso: "Coleção completa: X%" (cartas no nível máximo / total)
- Filtro "Cartas meta que você ainda não tem" — compara coleção do jogador com meta decks do `ArenaGuide`

---

## FASE 6 — Compartilhamento Social e Virality

**Por quê**: O app não tem mecanismo viral. Sharing de análises pode trazer novos usuários.

### 6.1 — Compartilhar Análise como Imagem
- Botão "Compartilhar Análise" na aba IA
- `RepaintBoundary` em volta do card de análise
- Captura screenshot com `RenderRepaintBoundary.toImage()`
- Share via `share_plus` (já é dependência!) com imagem + texto "Minha análise no Royale Coach"
- Design do card de share otimizado para Instagram Stories (9:16)

### 6.2 — Compartilhar Deck
- Botão "Compartilhar Deck" na aba DECK
- Gera imagem com as 8 cartas em grid + nome do arquétipo + elixir médio
- Deep link que abre o app diretamente na análise do deck (`royalecoach://deck/{cardIds}`)

### 6.3 — Ranking de Melhores Jogadores
- Tabela no Supabase com top jogadores que usaram o app (opt-in)
- Tela `LeaderboardScreen` com filtro por arena
- "Você está no Top X% da sua arena"

---

## FASE 7 — AI Coach Conversacional

**Por quê**: O Gemini já está integrado. Um chat com o coach é a evolução natural da análise one-shot.

### 7.1 — Chat com o Coach
- Nova aba "COACH" (ou tela separada acessada pelo FAB)
- Interface de chat com histórico de mensagens
- Contexto inicial pré-carregado: perfil do jogador + análise atual + últimas batalhas
- O modelo já tem todo esse contexto, apenas adiciona conversação multi-turn
- Limite de mensagens (ex: 10/dia gratuito, ilimitado premium)
- Sugestões de perguntas frequentes como chips clicáveis:
  - "Como eu vencer Golem Beatdown?"
  - "Qual carta devo upar primeiro?"
  - "Meu deck funciona em Grand Challenge?"

### 7.2 — Análise Pós-Batalha
- Após o jogador buscar suas batalhas, detectar a derrota mais recente
- Oferecer: "Quer que eu analise o porquê você perdeu essa batalha?"
- Envia o deck adversário + deck próprio + resultado para o Gemini
- Retorna análise contextualizada da batalha específica

---

## FASE 8 — Performance e Arquitetura

**Por quê**: Com crescimento de features, a base técnica precisa evoluir.

### 8.1 — Navegação com go_router
- Substituir `Navigator.push` manual por `go_router`
- Deep links para: `/player/{tag}`, `/deck/{cardIds}`, `/meta/{arenaId}`
- Histórico de navegação correto no Android (back button)
- URL compartilháveis no web

### 8.2 — Testes Automatizados
- Unit tests para todos os use cases (já seguem Clean Architecture, fácil de testar)
- Unit tests para `AiStrategyReportModel.fromLlmResponse()` (3-tier parsing)
- Widget tests para `ProfileScreen` (snapshot testing dos tabs)
- Integration test do fluxo completo: busca → perfil → análise

### 8.3 — Skeleton Loading Screens
- Substituir `CircularProgressIndicator` por shimmer loading (`shimmer` package)
- Skeleton do ProfileScreen enquanto player carrega
- Skeleton do card de análise enquanto IA processa
- Transições suaves com `AnimatedSwitcher`

### 8.4 — Lazy Loading e Paginação
- Battle log: carregar 20 batalhas, lazy load ao chegar no fim da lista
- Card grid: usar `SliverGrid` com lazy rendering
- Arena guide: carregar sob demanda, não todos os 27 no startup

---

## FASE 9 — Monetização Evoluída

### 9.1 — Modelo Freemium
- **Grátis**: 3 análises completas por dia, sem histórico cloud
- **Premium (R$ 9,90/mês)**: análises ilimitadas, sync cloud, chat com AI coach, sem ads
- Implementar via `in_app_purchase` (Flutter plugin oficial)
- Paywall suave: após 3 análises, oferecer trial de 7 dias gratuito

### 9.2 — Banner Ads (não-intrusivos)
- Adicionar banner ads na parte inferior do `SearchScreen` e `ApiKeyScreen`
- Remover banner quando usuário for premium
- Usar `google_mobile_ads` `BannerAd` (já é dependência)

### 9.3 — Rewarded Ad para Funcionalidades Premium
- Manter rewarded ad para análise completa (atual)
- Adicionar rewarded ad para: ver análise pós-batalha, desbloquear 1 chat message extra

---

## FASE 10 — Home Screen Widget

**Por quê**: Widget na home screen mantém o app top of mind mesmo sem abrir.

### 10.1 — Android Widget
- Usar `home_widget` package
- Widget 2x2 mostrando: deck atual do jogador (8 ícones de carta), troféus, win rate do dia
- Tap no widget abre diretamente o app no perfil do jogador
- Atualiza a cada hora em background via `WorkManager`

---

## Prioridade de Execução Sugerida

| Fase | Feature | Semanas | Impacto |
|------|---------|---------|---------|
| 1 | Supabase Backend | 2 | 🔥 Transformador |
| 2 | Battle Analytics | 1.5 | 🔥 Transformador |
| 3 | Deck Builder | 2 | ⭐ Alto |
| 5 | Card Roadmap | 1 | ⭐ Alto |
| 6 | Social Sharing | 0.5 | ⭐ Alto |
| 4 | Meta Report | 2 | ⭐ Alto |
| 7 | AI Coach Chat | 1.5 | 💎 Diferencial |
| 8 | Performance | 1 | 🔧 Técnico |
| 9 | Monetização | 1 | 💰 Revenue |
| 10 | Widget | 1 | 🎯 Retenção |

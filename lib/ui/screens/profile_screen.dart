import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../models/cr_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PlayerViewModel>();
    final profile = viewModel.playerProfile;
    final battleLog = viewModel.battleLog;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('Nenhum dado encontrado')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.name),
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildProfileHeader(context, profile),
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Deck', icon: Icon(Icons.style)),
                    Tab(text: 'Coleção', icon: Icon(Icons.grid_view)),
                    Tab(text: 'Histórico', icon: Icon(Icons.history)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildCardGrid(context, profile.currentDeck, emptyMessage: 'Deck não encontrado'),
                      _buildCardGrid(context, profile.cards, emptyMessage: 'Coleção não encontrada'),
                      _buildHistoryTab(context, battleLog),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, PlayerProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.tag,
                style: const TextStyle(color: Colors.grey, letterSpacing: 1.2),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Troféus', profile.trophies.toString(), Icons.emoji_events, Colors.amber),
                  Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
                  _buildStatItem('Arena', profile.arenaName, Icons.account_balance, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCardGrid(BuildContext context, List<CrCard> cards, {required String emptyMessage}) {
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: card.iconUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Lvl ${card.level ?? '?'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallDeckGrid(List<CrCard> cards) {
    if (cards.isEmpty) return const Text('Sem cartas obtidas', style: TextStyle(color: Colors.grey, fontSize: 12));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: cards.map((card) {
        return SizedBox(
          width: 32,
          height: 38,
          child: CachedNetworkImage(
            imageUrl: card.iconUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: Icon(Icons.downloading, size: 16, color: Colors.grey)),
            errorWidget: (context, url, error) => const Icon(Icons.error, size: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<CrBattle>? battleLog) {
    if (battleLog == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (battleLog.isEmpty) {
      return const Center(child: Text('Nenhuma partida encontrada', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: battleLog.length,
      itemBuilder: (context, index) {
        final battle = battleLog[index];
        
        final teamParticipant = battle.team.isNotEmpty ? battle.team.first : null;
        final oppParticipant = battle.opponent.isNotEmpty ? battle.opponent.first : null;

        final teamCrowns = teamParticipant?.crowns ?? 0;
        final oppCrowns = oppParticipant?.crowns ?? 0;
        final isWin = teamCrowns > oppCrowns;
        final isDraw = teamCrowns == oppCrowns;
        
        final resultColor = isWin ? Colors.green : (isDraw ? Colors.grey : Colors.red);
        final resultText = isWin ? 'VITÓRIA' : (isDraw ? 'EMPATE' : 'DERROTA');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Row(
              children: [
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    color: resultColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo: ${battle.type}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        oppParticipant != null ? 'vs ${oppParticipant.name}' : 'Adversário desconhecido',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      resultText,
                      style: TextStyle(
                        color: resultColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$teamCrowns - $oppCrowns',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Seu Deck', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildSmallDeckGrid(teamParticipant?.cards ?? []),
                    const SizedBox(height: 16),
                    Text('Deck do ${oppParticipant?.name ?? 'Adversário'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    _buildSmallDeckGrid(oppParticipant?.cards ?? []),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


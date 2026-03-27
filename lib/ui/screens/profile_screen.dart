import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
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
        appBar: AppBar(title: const Text('PROFILE')),
        body: const Center(child: Text('No data found')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D47A1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(profile.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => viewModel.fetchPlayerProfile(profile.tag),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(context, profile),
                    
                    // AI Analysis Action Card
                    _buildAiAnalysisCard(context, viewModel),

                    const SizedBox(height: 8),
                    const TabBar(
                      labelColor: Colors.amber,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.amber,
                      indicatorWeight: 3,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      tabs: [
                        Tab(text: 'DECK', icon: Icon(Icons.style)),
                        Tab(text: 'CARDS', icon: Icon(Icons.grid_view)),
                        Tab(text: 'HISTORY', icon: Icon(Icons.history)),
                      ],
                    ),
                    SizedBox(
                      height: 500, // Fixed height for nested TabBarView in ScrollView
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                        child: TabBarView(
                          children: [
                            _buildCardGrid(context, profile.currentDeck, emptyMessage: 'Deck not found'),
                            _buildCardGrid(context, profile.cards, emptyMessage: 'Cards not found'),
                            _buildHistoryTab(context, battleLog),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Disclaimer Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.black.withValues(alpha: 0.3),
              child: const Text(
                'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard(BuildContext context, PlayerViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4527A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'AI STRATEGY INSIGHTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (viewModel.aiAnalysis != null)
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  ],
                ),
              ),
              if (viewModel.isAnalyzing)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      SpinKitWave(color: Colors.amber, size: 40),
                      SizedBox(height: 16),
                      Text('Analyzing with Gemini AI...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              else if (viewModel.aiAnalysis != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.aiAnalysis!,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      if (viewModel.suggestedDeckLink != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(viewModel.suggestedDeckLink!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('IMPORT DECK TO CLASH ROYALE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => viewModel.getAiInsight(),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.amber),
                        label: const Text('RE-ANALYZE', style: TextStyle(color: Colors.amber, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Choose your battle strategy:',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildArchetypeChip(context, viewModel, 'Aggressive (Beatdown)', Icons.bolt),
                          _buildArchetypeChip(context, viewModel, 'Defensive (Control)', Icons.shield),
                          _buildArchetypeChip(context, viewModel, 'Cycle (Fast)', Icons.loop),
                          _buildArchetypeChip(context, viewModel, 'Siege (Ranged)', Icons.castle),
                          _buildArchetypeChip(context, viewModel, 'Splash (Area)', Icons.waves),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Unlock expert analysis of your collection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => viewModel.getAiInsight(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('WATCH AD TO UNLOCK', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchetypeChip(BuildContext context, PlayerViewModel viewModel, String label, IconData icon) {
    final isSelected = viewModel.selectedArchetype == label;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.amber),
      label: Text(label.split(' ').first, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) viewModel.setArchetype(label);
      },
      selectedColor: Colors.amber,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildProfileHeader(BuildContext context, PlayerProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        profile.tag,
                        style: const TextStyle(color: Colors.amber, letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ARENA ${profile.arenaName.split(' ').last}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('TROPHIES', profile.trophies.toString(), Icons.emoji_events, Colors.amber),
                _buildStatDivider(),
                _buildStatItem('ARENA', profile.arenaName, Icons.account_balance, Colors.blueAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1));
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildCardGrid(BuildContext context, List<CrCard> cards, {required String emptyMessage}) {
    if (cards.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.white54)),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CachedNetworkImage(
                    imageUrl: card.iconUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: SpinKitPulse(color: Colors.white24, size: 20),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Text(
                   'LVL ${card.level ?? '?'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<CrBattle>? battleLog) {
    if (battleLog == null) {
      return const Center(child: SpinKitRing(color: Colors.amber, size: 40));
    }
    if (battleLog.isEmpty) {
      return const Center(child: Text('No battles found', style: TextStyle(color: Colors.white54)));
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
        
        final resultColor = isWin ? Colors.greenAccent : (isDraw ? Colors.white54 : Colors.redAccent);
        final resultText = isWin ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT');

        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        battle.type.toUpperCase(),
                        style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        oppParticipant?.name ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$teamCrowns - $oppCrowns',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      resultText,
                      style: TextStyle(color: resultColor, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('YOUR DECK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 8),
                    _buildSmallDeckGrid(teamParticipant?.cards ?? []),
                    const SizedBox(height: 16),
                    const Text('OPPONENT DECK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
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

  Widget _buildSmallDeckGrid(List<CrCard> cards) {
    if (cards.isEmpty) return const Text('No cards', style: TextStyle(color: Colors.white30, fontSize: 10));
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: cards.map((card) {
        return Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: CachedNetworkImage(
            imageUrl: card.iconUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SpinKitPulse(color: Colors.white10, size: 10),
          ),
        );
      }).toList(),
    );
  }
}

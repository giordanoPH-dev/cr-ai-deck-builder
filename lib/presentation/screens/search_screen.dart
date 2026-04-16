import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../widgets/error_display_widget.dart';
import '../widgets/goblin_trophy_animation.dart';
import '../widgets/banner_ad_widget.dart';
import 'profile_screen.dart';

/// Search screen — entry point of the application.
///
/// Uses [BlocBuilder] for reactive state rendering and
/// [BlocListener] for navigation side-effects.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedTag();
  }

  Future<void> _loadSavedTag() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTag = prefs.getString(AppConstants.savedPlayerTagKey);
    if (savedTag != null && savedTag.isNotEmpty && mounted) {
      setState(() {
        _tagController.text = savedTag;
      });
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchPlayer() async {
    final tag = _tagController.text.trim().toUpperCase();
    if (tag.isEmpty) return;

    FocusScope.of(context).unfocus();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.savedPlayerTagKey, tag);

    if (mounted) {
      context.read<PlayerCubit>().fetchPlayer(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<PlayerCubit, PlayerState>(
        listener: (context, state) {
          if (state is PlayerLoaded && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Goblin Trophy
                  const GoblinTrophyAnimation(size: 150),
                  const SizedBox(height: 32),
                  const Text(
                    'CR AI DECK BUILDER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'UNOFFICIAL FAN APP',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI-POWERED STRATEGY & INSIGHTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Search Card
                  Card(
                    color: Colors.white.withValues(alpha: 0.15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _tagController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'PLAYER TAG',
                              labelStyle: const TextStyle(color: Colors.amber),
                              hintText: 'ex: L8P22UR2',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                              prefixIcon: const Icon(Icons.tag, color: Colors.amber),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.amber),
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                            ),
                            onSubmitted: (_) => _searchPlayer(),
                          ),
                          const SizedBox(height: 24),
                          BlocBuilder<PlayerCubit, PlayerState>(
                            builder: (context, state) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (state is PlayerError)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: InlineErrorWidget(
                                        failure: state.failure,
                                        onRetry: _searchPlayer,
                                      ),
                                    ),

                                  ElevatedButton(
                                    onPressed: state is PlayerLoading ? null : _searchPlayer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: state is PlayerLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                            ),
                                          )
                                        : const Text(
                                            'ANALYZE PROFILE',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Help Section
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.help_outline, color: Colors.amber, size: 20),
                      title: const Text(
                        'Where is my Tag?',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              _buildStep(1, 'Open Clash Royale'),
                              _buildStep(2, 'Tap your Name (Top Left)'),
                              _buildStep(3, 'Copy the Tag under your Name'),
                              const SizedBox(height: 8),
                              const Text(
                                'Example: #L8P22UR2',
                                style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse('clashroyale://');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    final storeUri = Uri.parse('https://play.google.com/store/apps/details?id=com.supercell.clashroyale');
                                    await launchUrl(storeUri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text(
                                  'OPEN CLASH ROYALE',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Disclaimer Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'This material is unofficial and is not endorsed by Supercell. For more information see Supercell\'s Fan Content Policy: www.supercell.com/fan-content-policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Powered by Gemini AI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(adUnitId: 'ca-app-pub-8273819403150038/5940370812'),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: Colors.amber,
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

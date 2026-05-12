import 'package:cr_ai_deck_builder/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../blocs/player/player_cubit.dart';
import '../blocs/player/player_state.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/error_display_widget.dart';
import '../widgets/goblin_trophy_animation.dart';
import 'profile_screen.dart';

/// Search screen — entry point of the application.
///
/// Accepts an optional [initialTag] to pre-fill the search field, used when
/// navigating from a battle history entry to look up an opponent.
class SearchScreen extends StatefulWidget {
  final String? initialTag;

  const SearchScreen({super.key, this.initialTag});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialTag != null) {
      _tagController.text = widget.initialTag!;
    } else {
      _loadSavedTag();
    }
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
    HapticFeedback.mediumImpact();
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
    final l10n = AppLocalizations.of(context)!;
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
          child: Stack(
            children: [
              // Developer logo — top right corner
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                  child: Image.asset(
                    'assets/images/ui_icons/bitmagedev_logo.png',
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Goblin Trophy
                      const GoblinTrophyAnimation(size: 150),
                      const SizedBox(height: 32),
                      Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.unofficialApp,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.aiPoweredTagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Search Card
                      Card(
                        color: Colors.white.withValues(alpha: 0.12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _tagController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n.playerTagLabel,
                                  labelStyle: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                  hintText: l10n.playerTagHint,
                                  hintStyle: const TextStyle(
                                    color: AppColors.textDisabled,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.tag,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.overlay,
                                ),
                                onSubmitted: (_) => _searchPlayer(),
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<PlayerCubit, PlayerState>(
                                builder: (context, state) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (state is PlayerError)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child: InlineErrorWidget(
                                            failure: state.failure,
                                            onRetry: _searchPlayer,
                                          ),
                                        ),

                                      ElevatedButton(
                                        onPressed: state is PlayerLoading
                                            ? null
                                            : _searchPlayer,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: state is PlayerLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.black),
                                                ),
                                              )
                                            : Text(
                                                l10n.analyzeButton,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
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
                                  'ABRIR CLASH ROYALE',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Help Section
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.help_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          title: Text(
                            l10n.whereIsMyTag,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  _buildStep(1, l10n.step1),
                                  _buildStep(2, l10n.step2),
                                  _buildStep(3, l10n.step3),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.tagExample,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
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
                          l10n.disclaimerText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 9,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.poweredByGemini,
                        style: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            backgroundColor: AppColors.primary,
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

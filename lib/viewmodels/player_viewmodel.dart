import 'package:flutter/material.dart';
import '../models/cr_models.dart';
import '../services/clash_api_service.dart';
import '../services/ai_service.dart';
import '../services/ad_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final ClashApiService _apiService;
  final AiService _aiService;
  final AdService _adService;

  PlayerViewModel(this._apiService, this._aiService, this._adService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PlayerProfile? _playerProfile;
  PlayerProfile? get playerProfile => _playerProfile;

  List<CrBattle>? _battleLog;
  List<CrBattle>? get battleLog => _battleLog;

  String? _aiAnalysis;
  String? get aiAnalysis => _aiAnalysis;

  Future<void> fetchPlayerProfile(String tag) async {
    if (tag.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _aiAnalysis = null; // Reset AI analysis on new player search
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getPlayerProfile(tag),
        _apiService.getPlayerBattleLog(tag),
      ]);
      
      _playerProfile = results[0] as PlayerProfile;
      _battleLog = results[1] as List<CrBattle>;
    } catch (e) {
      _errorMessage = 'Erro: $e';
      _playerProfile = null;
      _battleLog = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _selectedArchetype = 'Aggressive (Beatdown)';
  String get selectedArchetype => _selectedArchetype;

  void setArchetype(String archetype) {
    _selectedArchetype = archetype;
    notifyListeners();
  }

  String? _suggestedDeckLink;
  String? get suggestedDeckLink => _suggestedDeckLink;

  Future<void> getAiInsight() async {
    if (_playerProfile == null || _battleLog == null) return;
    
    _isAnalyzing = true;
    _errorMessage = null;
    _suggestedDeckLink = null;
    notifyListeners();

    try {
      // Step 1: Show Rewarded Ad
      await _adService.showRewardedAd(
        onUserEarnedReward: () async {
          // Step 2: Call AI Service after user earned reward
          if (!_aiService.isAvailable) {
            _errorMessage = 'AI service is currently not configured.';
            _isAnalyzing = false;
            notifyListeners();
            return;
          }

          final analysis = await _aiService.analyzePlayerData(
            profile: _playerProfile!,
            battles: _battleLog!,
            preferredStyle: _selectedArchetype,
          );
          
          _aiAnalysis = analysis;
          
          // Extract Deck IDs for deep-linking
          // Format: DECK_IDS: id1;id2;id3;id4;id5;id6;id7;id8
          final deckIdMatch = RegExp(r'DECK_IDS:\s*([\d;]+)').firstMatch(analysis);
          if (deckIdMatch != null) {
            final ids = deckIdMatch.group(1);
            if (ids != null) {
              _suggestedDeckLink = 'https://link.clashroyale.com/deck/en?deck=$ids';
            }
          }
          
          _isAnalyzing = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Error during analysis: $e';
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clear() {
    _playerProfile = null;
    _battleLog = null;
    _errorMessage = null;
    _aiAnalysis = null;
    notifyListeners();
  }
}

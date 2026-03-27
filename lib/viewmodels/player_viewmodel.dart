import 'package:flutter/material.dart';
import '../models/cr_models.dart';
import '../services/clash_api_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final ClashApiService _apiService;

  PlayerViewModel(this._apiService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PlayerProfile? _playerProfile;
  PlayerProfile? get playerProfile => _playerProfile;

  List<CrBattle>? _battleLog;
  List<CrBattle>? get battleLog => _battleLog;

  Future<void> fetchPlayerProfile(String tag) async {
    if (tag.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
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

  void clear() {
    _playerProfile = null;
    _battleLog = null;
    _errorMessage = null;
    notifyListeners();
  }
}

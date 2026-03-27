import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cr_models.dart';

class ClashApiService {
  // In a real application, the API key should be injected or loaded from env.
  // We'll use a placeholder for now to be configured.
  final String _apiKey;
  static const String _baseUrl = 'https://api.clashroyale.com/v1';

  ClashApiService({String apiKey = 'YOUR_API_KEY_HERE'}) : _apiKey = apiKey;

  Future<PlayerProfile> getPlayerProfile(String tag) async {
    // Tags in the URL require the # to be URL-encoded as %23
    final formattedTag = tag.startsWith('#') ? '%23${tag.substring(1)}' : '%23$tag';
    
    final uri = Uri.parse('$_baseUrl/players/$formattedTag');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return PlayerProfile.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load player profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<CrBattle>> getPlayerBattleLog(String tag) async {
    final formattedTag = tag.startsWith('#') ? '%23${tag.substring(1)}' : '%23$tag';
    
    final uri = Uri.parse('$_baseUrl/players/$formattedTag/battlelog');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as List;
      return jsonResponse.map((e) => CrBattle.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load battle log: ${response.statusCode} - ${response.body}');
    }
  }

  // Placeholder for fetching all cards if needed by the LLM later
  Future<List<CrCard>> getAllCards() async {
    final uri = Uri.parse('$_baseUrl/cards');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> items = jsonResponse['items'] ?? [];
      return items.map((e) => CrCard.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cards: ${response.statusCode}');
    }
  }
}

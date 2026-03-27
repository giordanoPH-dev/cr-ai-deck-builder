import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/cr_models.dart';

class AiService {
  final String? _apiKey;
  GenerativeModel? _model;

  AiService({String? apiKey}) : _apiKey = apiKey {
    if (_apiKey != null && _apiKey!.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
      );
    }
  }

  bool get isAvailable => _model != null;

  Future<String> analyzePlayerData({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    String? preferredStyle,
  }) async {
    if (_model == null) {
      return 'AI Analysis is currently unavailable. Please provide a valid Gemini API Key in your configuration.';
    }

    final deckNames = profile.currentDeck.map((c) => c.name).join(', ');
    
    // Prepare card summaries (Name + Level + ID)
    final collectionInfo = profile.cards
        .map((c) => "${c.name} (LVL ${c.level}, ID: ${c.id})")
        .join(", ");

    // Summarize recent battles (up to 15)
    int wins = 0;
    int losses = 0;
    for (var battle in battles.take(15)) {
      final teamCrowns = battle.team.isNotEmpty ? battle.team.first.crowns : 0;
      final oppCrowns = battle.opponent.isNotEmpty ? battle.opponent.first.crowns : 0;
      if (teamCrowns > oppCrowns) wins++;
      else if (teamCrowns < oppCrowns) losses++;
    }

    final style = preferredStyle ?? "Aggressive (Beatdown)";

    final prompt = """
You are a Clash Royale Grand Master and Strategy Expert.
Analyze the following player data and provide an ELITE STRATEGY REPORT.

IMPORTANT: This analysis is part of an unofficial fan content application. It is not endorsed by Supercell.

USER PREFERENCE: Focus on a ${style.toUpperCase()} playstyle.
PLAYER: ${profile.name}
TROPHIES: ${profile.trophies}
CURRENT DECK: $deckNames
COLLECTION (Highest Priority): $collectionInfo
RECENT PERFORMANCE (Last 15 matches): $wins Wins, $losses Losses

TASKS:
1. **PLAYSTYLE ANALYSIS**: Based on their recent matches and current deck, evaluate if they are currently playing to their chosen style ($style).
2. **TARGETED COACHING**: (Trophy Level ${profile.trophies}) Explain the common meta at this trophy range and how the user's collection can counter it.
3. **THE PERFECT DECK**: Suggest the BEST 8-card deck using ONLY cards from the User's COLLECTION. 
   - CRITICAL: Prioritize the highest-level cards. Do not suggest a card if its level is significantly lower than their average unless it is absolutely essential.
   - If the user's collection is too weak to support a $style deck, explain WHY and suggest the closest viable alternative.
4. **BATTLE GUIDE**: Provide a 'how to play' for the suggested deck (Opening, Defense, Win Condition).
5. **DECK LINK DATA**: At the very end of your response, provide the 8 card IDs of the suggested deck in this EXACT format for deep-linking: 
   DECK_IDS: id1;id2;id3;id4;id5;id6;id7;id8

Keep the tone professional, encouraging, and strategic. Use Markdown formatting.
""";

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "Sorry, I couldn't generate an analysis at this time.";
    } catch (e) {
      return 'Error generating AI analysis: $e';
    }
  }
}

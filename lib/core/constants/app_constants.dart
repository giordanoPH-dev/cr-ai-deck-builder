/// Centralized application constants for timeouts, retries, and feature flags.
///
/// These values are tuned for quick interactions
/// that should complete within 2 minutes max.
class AppConstants {
  AppConstants._();

  // ── Network ──────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration llmTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(seconds: 1);

  // ── Clash Royale API ─────────────────────────────────────
  static const String clashApiBaseUrl = 'https://api.clashroyale.com/v1';
  static const String deckLinkBaseUrl = 'https://link.clashroyale.com/deck/en?deck=';

  // ── LLM ──────────────────────────────────────────────────
  static const String geminiModel = 'gemini-2.0-flash';
  static const int maxBattlesForAnalysis = 15;

  // ── Cache ────────────────────────────────────────────────
  static const String cachedProfileKey = 'cached_player_profile';
  static const String cachedBattleLogKey = 'cached_battle_log';
  static const String savedPlayerTagKey = 'saved_player_tag';

  // ── Observability ────────────────────────────────────────
  static const String appIdentifier = 'cr-ai-deck-builder';
  static const String deviceId = 'device-001'; // Would be dynamic in production
}

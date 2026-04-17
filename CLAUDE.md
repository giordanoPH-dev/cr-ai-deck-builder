# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Static analysis / linting
flutter test             # Run all tests
flutter test test/path/to/test_file.dart  # Run a single test file
flutter run              # Run in debug mode
flutter build apk --release   # Build Android APK
flutter build web --release   # Build web version
flutter gen-l10n         # Regenerate localization files after editing .arb files
```

No Makefile — use the `flutter` CLI directly.

## Architecture

Clean Architecture with strict layer separation: Presentation → Domain ← Data, Core as cross-cutting infrastructure.

### Layers

**`lib/domain/`** — Pure Dart, zero Flutter/external dependencies
- Entities: `PlayerProfile`, `CrCard`, `CrBattle`, `AiStrategyReport`, `DeckAnalysisReport`, `FullAnalysisReport`
- Repository contracts (abstract classes)
- Use cases: `GetPlayerProfile` (parallel `Future.wait` for profile + battles), `GetAiStrategy` (validates ≥ 8 cards), `GetFullAnalysis`

**`lib/data/`** — Implements domain contracts, handles serialization and errors
- Models extend entities with `fromJson`/`toJson` and `fromParsedJson`
- Datasources: `ClashApiDatasource` (RoyaleAPI proxy), `AiDatasource` (Gemini), `PlayerLocalDatasource` (SharedPreferences), `SupabaseDatasourceImpl` (cloud sync)
- Repository implementations wrap all errors into `Either<Failure, T>` via `dartz`

**`lib/presentation/`** — Flutter UI only, no business logic
- State management: `flutter_bloc` Cubits with `sealed class` states (Initial, Loading variants, Loaded variants, Error)
- Cubits registered as **factory** in `get_it` (new instance per widget, not singleton)
- Navigation: direct `MaterialPageRoute` push/pop — no routing library

**`lib/core/`** — Cross-cutting concerns
- `di/injection_container.dart`: `get_it` service locator; call `setupDependencies()` at startup. Registration order: External → Core → DataSources → Repositories → UseCases → Cubits
- `error/failures.dart`: sealed `Failure` hierarchy (ServerFailure, NetworkFailure, LlmFailure, PlayerNotFoundFailure, CacheFailure, UnknownFailure)
- `network/http_client.dart`: `ResilientHttpClient` with 3-retry exponential backoff (1s→2s→4s); distinguishes retryable 5xx from non-retryable 4xx
- `observability/`: `LoggerService` (structured JSON, Cloud Logging compatible) + `AlertDispatcher` (stub for Telegram/Sentry/GCP)
- `data/arena_guide.dart`: local knowledge base with per-arena meta; `ArenaGuide.cardsForDeck(name)` resolves deck name → 8 card name list

**`lib/services/`** — AdMob Rewarded Ads (`ad_service.dart`); skipped entirely on web via `kIsWeb` check

### Error Handling Pipeline

```
DataSource throws Exception
  → Repository catches → converts to Failure (Either<Failure, T>)
  → UseCase validates → propagates Either
  → Cubit folds Either → emits sealed State
  → UI pattern-matches State → renders
```

No exceptions cross layer boundaries. `LlmFailure` carries `rawResponse` for debugging parse failures.

### AI Integration (Gemini)

Models defined in `AppConstants.geminiModelFallbacks` — primary `gemini-2.5-flash-lite` with 2 fallbacks tried in order.

`AiDatasource` has three prompt builders:
- `_buildStructuredPrompt` → strategy-only (used by `generateStrategy`)
- `_buildDeckAnalysisPrompt` → current-deck analysis (used by `analyzeDeck`)
- `_buildCombinedPrompt` → both in one call (used by `getFullAnalysis`) — **this is the primary UI path**
- Shared meta-deck knowledge base in `_deckKnowledgeBase()` — injected into both strategy prompts

`AiStrategyReportModel.fromLlmResponse()` uses a 3-tier parsing strategy:
1. Direct JSON parse
2. Extract from markdown code block
3. Throw `LlmException` with raw response

`confidenceScore` defaults to `0.7` if missing. `deckLinkUrl` is rebuilt from the player's card collection (AI-provided IDs are unreliable; resolved by name lookup against `profile.cards`).

### Cache & Offline Support

`PlayerRepositoryImpl` checks `NetworkInfo` first:
1. Online → fetch remote → cache on success via `PlayerLocalDatasource`
2. Network failure → try cache
3. Immediately offline → skip to cache

`AiRepositoryImpl` persists full analysis to SharedPreferences via `saveAnalysis`/`loadSavedAnalysis`. Cache keys: `saved_analysis_{tag}` and `saved_analysis_date_{tag}`. **Critical**: `saveAnalysis` requires the concrete `FullAnalysisReportModel` subtype — `toJson()` casts fields to `AiStrategyReportModel` and `DeckAnalysisReportModel`; passing base entity types silently fails. `DeckAnalysisReportModel.copyWith()` is overridden to return the model subtype (not the base entity).

### Configuration

Runtime config via `flutter_dotenv` (`.env` file, not committed). Required keys:
- `CLASH_ROYALE_API_KEY` — Clash Royale RoyaleAPI proxy
- `GEMINI_API_KEY` — Google Gemini (overridable per-user in SharedPreferences via `ApiKeyScreen`)
- `ADMOB_REWARDED_AD_UNIT_ID` — AdMob rewarded unit ID
- `SUPABASE_URL` / `SUPABASE_ANON_KEY` — Supabase backend (anonymous auth + strategy cloud sync)

AdMob App ID is a **build-time** secret: set `admob.app.id` in `android/local.properties` (gitignored); Gradle reads it via `manifestPlaceholders` and injects into `AndroidManifest.xml`. Cannot use `.env` for this.

Timeouts: 10s for API calls, 30s for LLM calls (see `lib/core/constants/app_constants.dart`).

### Localization

ARB files in `lib/l10n/` (en, pt, es). After editing `.arb` files run `flutter gen-l10n` to regenerate `lib/l10n/generated/`. Access via `AppLocalizations.of(context)!.key`. Portuguese is the primary language — some error messages are hardcoded in Portuguese in repository implementations.

### Tests

Test coverage is minimal — only `test/widget_test.dart` exists. No unit tests for domain or data layers yet.

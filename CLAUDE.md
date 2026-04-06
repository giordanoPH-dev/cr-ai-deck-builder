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
```

No Makefile — use the `flutter` CLI directly.

## Architecture

This is a Flutter app following **Clean Architecture** with strict layer separation. Each layer has one direction of dependency: Presentation → Domain ← Data, with Core as cross-cutting infrastructure.

### Layers

**`lib/domain/`** — Pure Dart, zero Flutter/external dependencies
- Entities: `PlayerProfile`, `CrCard`, `CrBattle`, `AiStrategyReport`
- Repository contracts (abstract classes)
- Use cases: `GetPlayerProfile` (parallel fetch: profile + battles), `GetAiStrategy`

**`lib/data/`** — Implements domain contracts, handles serialization and errors
- Models extend entities with `fromJson`/`toJson`
- Datasources: `ClashApiDatasource` (Clash Royale API), `AiDatasource` (Gemini), `PlayerLocalDatasource` (SharedPreferences)
- Repository implementations wrap all errors into `Either<Failure, T>` via `dartz`

**`lib/presentation/`** — Flutter UI only, no business logic
- State management: `flutter_bloc` Cubits with `sealed class` states (Initial, Loading, Loaded, Error)
- Navigation: direct `MaterialPageRoute` push/pop — no routing library
- `SearchScreen → ProfileScreen` transition triggered via `BlocListener` on `PlayerLoaded`

**`lib/core/`** — Cross-cutting concerns
- `di/injection_container.dart`: `get_it` service locator; call `setupDependencies()` at startup
- `error/failures.dart`: sealed `Failure` hierarchy (ServerFailure, NetworkFailure, LlmFailure, PlayerNotFoundFailure, CacheFailure, UnknownFailure)
- `network/http_client.dart`: `ResilientHttpClient` with 3-retry exponential backoff (1s→2s→4s)
- `observability/`: `LoggerService` (structured JSON, Cloud Logging compatible) + `AlertDispatcher`

**`lib/services/`** — AdMob Rewarded Ads (`ad_service.dart`); skipped on web platform

### Error Handling

All data layer errors convert to `Either<Failure, T>`. No raw exceptions cross layer boundaries. The `LlmFailure` carries `rawResponse` for debugging parse failures.

### AI Integration (Gemini)

Model: `gemini-2.0-flash`. The LLM response parser in `AiStrategyReportModel.fromLlmResponse()` uses a 3-tier strategy:
1. Direct JSON parse
2. Extract from markdown code block
3. Throw `LlmException` with raw response

`confidenceScore` defaults to `0.7` if missing. `deckLinkUrl` is a `clashroyale.com/deck/` deep link built from `suggestedDeckIds`.

### Configuration

Runtime config via `flutter_dotenv` (`.env` file). Required keys:
- `CLASH_ROYALE_API_KEY` — Clash Royale API
- `GEMINI_API_KEY` — Google Gemini API

Timeouts: 10s for API calls, 30s for LLM calls (see `lib/core/constants/app_constants.dart`).

### Offline Support

`PlayerRepositoryImpl` falls back to `SharedPreferences` cache when `NetworkInfo` (via `connectivity_plus`) detects no internet.

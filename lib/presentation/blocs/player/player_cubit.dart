import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_player_profile.dart';
import '../../../core/observability/logger_service.dart';
import 'player_state.dart';

/// Cubit for managing player data state.
///
/// Contains zero business logic — delegates everything to the [GetPlayerProfile]
/// use case. Only responsibility: emit typed states.
class PlayerCubit extends Cubit<PlayerState> {
  final GetPlayerProfile _getPlayerProfile;
  final LoggerService _logger;

  PlayerCubit({
    required GetPlayerProfile getPlayerProfile,
    required LoggerService logger,
  })  : _getPlayerProfile = getPlayerProfile,
        _logger = logger,
        super(const PlayerInitial());

  /// Fetches player profile and battle log by tag.
  Future<void> fetchPlayer(String tag) async {
    if (tag.isEmpty) return;

    emit(const PlayerLoading());
    _logger.info('PlayerCubit: Fetching player', metadata: {'tag': tag});

    final result = await _getPlayerProfile(tag);

    result.fold(
      (failure) {
        _logger.warn('PlayerCubit: Fetch failed', metadata: {'failure': failure.message});
        emit(PlayerError(failure: failure));
      },
      (data) {
        _logger.info('PlayerCubit: Player loaded', metadata: {
          'name': data.profile.name,
          'battles': data.battles.length,
        });
        emit(PlayerLoaded(
          profile: data.profile,
          battles: data.battles,
        ));
      },
    );
  }

  /// Resets state to initial.
  void reset() {
    emit(const PlayerInitial());
  }
}

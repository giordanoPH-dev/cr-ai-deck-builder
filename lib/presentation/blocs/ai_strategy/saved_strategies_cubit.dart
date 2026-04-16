import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/observability/logger_service.dart';
import '../../../domain/usecases/get_saved_strategies.dart';
import 'saved_strategies_state.dart';

class SavedStrategiesCubit extends Cubit<SavedStrategiesState> {
  final GetSavedStrategies _getSavedStrategies;
  final LoggerService _logger;

  SavedStrategiesCubit({
    required GetSavedStrategies getSavedStrategies,
    required LoggerService logger,
  })  : _getSavedStrategies = getSavedStrategies,
        _logger = logger,
        super(const SavedStrategiesInitial());

  Future<void> fetchSavedStrategies(String playerTag) async {
    emit(const SavedStrategiesLoading());
    _logger.info('SavedStrategiesCubit: Fetching saved strategies', metadata: {'tag': playerTag});

    final result = await _getSavedStrategies(playerTag);

    result.fold(
      (failure) {
        _logger.warn('SavedStrategiesCubit: Fetch failed', metadata: {'error': failure.message});
        emit(SavedStrategiesError(failure: failure));
      },
      (reports) {
        _logger.info('SavedStrategiesCubit: Fetch successful', metadata: {'count': reports.length});
        emit(SavedStrategiesLoaded(reports: reports));
      },
    );
  }
}

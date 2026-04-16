import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/ai_strategy_report.dart';

sealed class SavedStrategiesState extends Equatable {
  const SavedStrategiesState();

  @override
  List<Object?> get props => [];
}

class SavedStrategiesInitial extends SavedStrategiesState {
  const SavedStrategiesInitial();
}

class SavedStrategiesLoading extends SavedStrategiesState {
  const SavedStrategiesLoading();
}

class SavedStrategiesLoaded extends SavedStrategiesState {
  final List<AiStrategyReport> reports;

  const SavedStrategiesLoaded({required this.reports});

  @override
  List<Object?> get props => [reports];
}

class SavedStrategiesError extends SavedStrategiesState {
  final Failure failure;

  const SavedStrategiesError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

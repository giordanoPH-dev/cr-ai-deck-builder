import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/repositories/ai_repository.dart';

class GetSavedStrategies {
  final AiRepository repository;

  GetSavedStrategies({required this.repository});

  Future<Either<Failure, List<AiStrategyReport>>> call(String playerTag) async {
    return await repository.getSavedStrategies(playerTag);
  }
}

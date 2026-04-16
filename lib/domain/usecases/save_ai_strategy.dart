import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/ai_strategy_report.dart';
import '../../domain/repositories/ai_repository.dart';

class SaveAiStrategy {
  final AiRepository repository;

  SaveAiStrategy({required this.repository});

  Future<Either<Failure, void>> call({
    required AiStrategyReport report,
    required String playerTag,
  }) async {
    return await repository.saveStrategy(
      report: report,
      playerTag: playerTag,
    );
  }
}

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/battle.dart';
import '../entities/full_analysis_report.dart';
import '../entities/player.dart';
import '../repositories/ai_repository.dart';

class GetFullAnalysis {
  final AiRepository _repository;

  const GetFullAnalysis({required AiRepository repository}) : _repository = repository;

  Future<Either<Failure, FullAnalysisReport>> call({
    required PlayerProfile profile,
    required List<CrBattle> battles,
    required String preferredArchetype,
    required String languageName,
  }) => _repository.getFullAnalysis(
        profile: profile,
        battles: battles,
        preferredArchetype: preferredArchetype,
        languageName: languageName,
      );
}

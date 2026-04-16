import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/observability/logger_service.dart';
import '../models/ai_strategy_report_model.dart';
import '../../domain/entities/ai_strategy_report.dart';

abstract class SupabaseDatasource {
  Future<void> signInAnonymously();
  Future<void> saveAiStrategy(AiStrategyReport report, String playerTag);
  Future<List<AiStrategyReport>> getSavedAiStrategies(String playerTag);
}

class SupabaseDatasourceImpl implements SupabaseDatasource {
  final SupabaseClient supabase;
  final LoggerService logger;

  SupabaseDatasourceImpl({
    required this.supabase,
    required this.logger,
  });

  @override
  Future<void> signInAnonymously() async {
    try {
      final response = await supabase.auth.signInAnonymously();
      logger.info('Signed in anonymously to Supabase', metadata: {
        'userId': response.user?.id,
      });
    } catch (e) {
      logger.warn('Supabase anonymous sign-in failed', metadata: {'error': e.toString()});
    }
  }

  @override
  Future<void> saveAiStrategy(AiStrategyReport report, String playerTag) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      logger.warn('Cannot save strategy: No user logged in');
      return;
    }

    // Ensure we are working with the model that has toJson
    final model = report is AiStrategyReportModel 
        ? report 
        : AiStrategyReportModel(
            playstyleAnalysis: report.playstyleAnalysis,
            metaCoaching: report.metaCoaching,
            suggestedDeckIds: report.suggestedDeckIds,
            suggestedDeckNames: report.suggestedDeckNames,
            battleGuide: report.battleGuide,
            deckLinkUrl: report.deckLinkUrl,
            confidenceScore: report.confidenceScore,
          );

    final data = model.toJson();
    data['player_tag'] = playerTag;
    data['user_id'] = user.id;

    try {
      await supabase.from('saved_strategies').insert(data);
      logger.info('Strategy saved to Supabase', metadata: {'playerTag': playerTag});
    } catch (e) {
      logger.warn('Failed to save strategy to Supabase', metadata: {'error': e.toString()});
    }
  }

  @override
  Future<List<AiStrategyReport>> getSavedAiStrategies(String playerTag) async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('saved_strategies')
          .select()
          .eq('player_tag', playerTag)
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((e) => AiStrategyReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.warn('Failed to fetch strategies from Supabase', metadata: {'error': e.toString()});
      return [];
    }
  }
}

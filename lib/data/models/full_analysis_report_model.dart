import 'dart:convert';
import '../../core/error/exceptions.dart';
import '../../domain/entities/full_analysis_report.dart';
import 'ai_strategy_report_model.dart';
import 'deck_analysis_report_model.dart';

class FullAnalysisReportModel extends FullAnalysisReport {
  const FullAnalysisReportModel({
    required super.strategy,
    required super.deckAnalysis,
    super.analyzedDeckIds = const [],
  });

  factory FullAnalysisReportModel.fromLlmResponse(String rawResponse) {
    Map<String, dynamic>? json;

    try {
      json = jsonDecode(rawResponse) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```').firstMatch(rawResponse);
      if (match != null) {
        try {
          json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    if (json == null) {
      throw LlmException(
        message: 'Failed to parse combined analysis response',
        rawResponse: rawResponse,
      );
    }

    final deckJson = json['deck_analysis'] as Map<String, dynamic>?;
    final strategyJson = json['strategy'] as Map<String, dynamic>?;

    if (deckJson == null || strategyJson == null) {
      throw LlmException(
        message: 'Combined response missing deck_analysis or strategy section',
        rawResponse: rawResponse,
      );
    }

    return FullAnalysisReportModel(
      strategy: AiStrategyReportModel.fromParsedJson(strategyJson),
      deckAnalysis: DeckAnalysisReportModel.fromParsedJson(deckJson),
    );
  }

  factory FullAnalysisReportModel.fromJson(Map<String, dynamic> json) {
    return FullAnalysisReportModel(
      strategy: AiStrategyReportModel.fromParsedJson(
          json['strategy'] as Map<String, dynamic>),
      deckAnalysis: DeckAnalysisReportModel.fromParsedJson(
          json['deck_analysis'] as Map<String, dynamic>),
      analyzedDeckIds: (json['analyzed_deck_ids'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'strategy': (strategy as AiStrategyReportModel).toJson(),
        'deck_analysis': (deckAnalysis as DeckAnalysisReportModel).toJson(),
        'analyzed_deck_ids': analyzedDeckIds,
      };

  FullAnalysisReportModel withDeckIds(List<int> deckIds) {
    return FullAnalysisReportModel(
      strategy: strategy,
      deckAnalysis: deckAnalysis,
      analyzedDeckIds: deckIds,
    );
  }
}

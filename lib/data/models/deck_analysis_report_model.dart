import 'dart:convert';
import '../../core/error/exceptions.dart';
import '../../domain/entities/deck_analysis_report.dart';

class DeckAnalysisReportModel extends DeckAnalysisReport {
  const DeckAnalysisReportModel({
    required super.grade,
    required super.gradeExplanation,
    required super.archetype,
    required super.avgElixir,
    required super.howToPlay,
    required super.strengths,
    required super.weaknesses,
    required super.suggestedSwaps,
    required super.overallFeedback,
  });

  factory DeckAnalysisReportModel.fromLlmResponse(String rawResponse) {
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
        message: 'Failed to parse deck analysis response',
        rawResponse: rawResponse,
      );
    }

    return DeckAnalysisReportModel.fromParsedJson(json);
  }

  factory DeckAnalysisReportModel.fromParsedJson(Map<String, dynamic> json) {
    double avgElixir = 0.0;
    final rawElixir = json['avg_elixir'];
    if (rawElixir is double) {
      avgElixir = rawElixir;
    } else if (rawElixir is int) {
      avgElixir = rawElixir.toDouble();
    } else if (rawElixir is String) {
      avgElixir = double.tryParse(rawElixir) ?? 0.0;
    }

    List<DeckSwapSuggestion> swaps = [];
    final swapsJson = json['suggested_swaps'] as List?;
    if (swapsJson != null) {
      swaps = swapsJson
          .whereType<Map<String, dynamic>>()
          .map((s) => DeckSwapSuggestion(
                remove: _safeString(s['remove'] ?? s['card_to_swap']),
                add: _safeString(s['add'] ?? s['suggested_card']),
                reason: _safeString(s['reason']),
              ))
          .toList();
    }

    return DeckAnalysisReportModel(
      grade: _safeString(json['grade'], 'C'),
      gradeExplanation: _safeString(json['grade_explanation']),
      archetype: _safeString(json['archetype'], 'Unknown'),
      avgElixir: avgElixir,
      howToPlay: _parseStringList(json['how_to_play']),
      strengths: _parseStringList(json['strengths']),
      weaknesses: _parseStringList(json['weaknesses']),
      suggestedSwaps: swaps,
      overallFeedback: _safeString(json['overall_feedback']),
    );
  }

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'grade_explanation': gradeExplanation,
        'archetype': archetype,
        'avg_elixir': avgElixir,
        'how_to_play': howToPlay,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'suggested_swaps': suggestedSwaps.map((s) => {'remove': s.remove, 'add': s.add, 'reason': s.reason}).toList(),
        'overall_feedback': overallFeedback,
      };

  @override
  DeckAnalysisReportModel copyWith({double? avgElixir}) => DeckAnalysisReportModel(
        grade: grade,
        gradeExplanation: gradeExplanation,
        archetype: archetype,
        avgElixir: avgElixir ?? this.avgElixir,
        howToPlay: howToPlay,
        strengths: strengths,
        weaknesses: weaknesses,
        suggestedSwaps: suggestedSwaps,
        overallFeedback: overallFeedback,
      );

  static String _safeString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value;
    if (value is List) return value.join('\n');
    return value.toString();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return [];
  }
}

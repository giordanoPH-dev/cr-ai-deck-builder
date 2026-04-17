import 'package:equatable/equatable.dart';

class DeckAnalysisReport extends Equatable {
  final String grade;
  final String gradeExplanation;
  final String archetype;
  final double avgElixir;
  final List<String> howToPlay;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<DeckSwapSuggestion> suggestedSwaps;
  final String overallFeedback;

  const DeckAnalysisReport({
    required this.grade,
    required this.gradeExplanation,
    required this.archetype,
    required this.avgElixir,
    required this.howToPlay,
    required this.strengths,
    required this.weaknesses,
    required this.suggestedSwaps,
    required this.overallFeedback,
  });

  DeckAnalysisReport copyWith({double? avgElixir}) => DeckAnalysisReport(
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

  @override
  List<Object?> get props => [grade, archetype, avgElixir, howToPlay, overallFeedback];
}

class DeckSwapSuggestion extends Equatable {
  final String remove;
  final String add;
  final String reason;

  const DeckSwapSuggestion({
    required this.remove,
    required this.add,
    required this.reason,
  });

  @override
  List<Object?> get props => [remove, add, reason];
}

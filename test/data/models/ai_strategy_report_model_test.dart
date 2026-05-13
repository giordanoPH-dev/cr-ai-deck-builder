import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cr_ai_deck_builder/core/error/exceptions.dart';
import 'package:cr_ai_deck_builder/data/models/ai_strategy_report_model.dart';

void main() {
  group('AiStrategyReportModel.fromLlmResponse', () {
    test('parses pure JSON with 8 cards', () {
      final json = _validStrategyJson();
      final model = AiStrategyReportModel.fromLlmResponse(jsonEncode(json));

      expect(model.suggestedDeckIds, hasLength(8));
      expect(model.suggestedDeckNames, hasLength(8));
      expect(model.suggestedDeckIds.first, 26000000);
      expect(model.suggestedDeckNames.first, 'Hog Rider');
      expect(model.confidenceScore, closeTo(0.9, 0.001));
      expect(model.playstyleAnalysis, 'Test playstyle');
    });

    test('parses JSON wrapped in markdown code block', () {
      final inner = jsonEncode(_validStrategyJson());
      final markdown = '```json\n$inner\n```';
      final model = AiStrategyReportModel.fromLlmResponse(markdown);

      expect(model.suggestedDeckIds, hasLength(8));
      expect(model.confidenceScore, closeTo(0.9, 0.001));
    });

    test('parses JSON wrapped in markdown block without json tag', () {
      final inner = jsonEncode(_validStrategyJson());
      final markdown = '```\n$inner\n```';
      final model = AiStrategyReportModel.fromLlmResponse(markdown);

      expect(model.suggestedDeckIds, hasLength(8));
    });

    test('throws LlmException for completely invalid response', () {
      expect(
        () => AiStrategyReportModel.fromLlmResponse('This is not JSON at all.'),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws LlmException for invalid JSON inside code block', () {
      const bad = '```json\n{ invalid json here }\n```';
      expect(
        () => AiStrategyReportModel.fromLlmResponse(bad),
        throwsA(isA<LlmException>()),
      );
    });
  });

  group('AiStrategyReportModel.fromParsedJson', () {
    test('parses confidence_score as double', () {
      final json = _validStrategyJson()..['confidence_score'] = 0.85;
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.confidenceScore, closeTo(0.85, 0.001));
    });

    test('parses confidence_score as int', () {
      final json = _validStrategyJson()..['confidence_score'] = 1;
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.confidenceScore, closeTo(1.0, 0.001));
    });

    test('parses confidence_score as string', () {
      final json = _validStrategyJson()..['confidence_score'] = '0.75';
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.confidenceScore, closeTo(0.75, 0.001));
    });

    test('defaults confidence_score to 0.7 when missing', () {
      final json = _validStrategyJson()..remove('confidence_score');
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.confidenceScore, closeTo(0.7, 0.001));
    });

    test('clamps confidence_score above 1.0 to 1.0', () {
      final json = _validStrategyJson()..['confidence_score'] = 1.5;
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.confidenceScore, closeTo(1.0, 0.001));
    });

    test('returns empty deck lists when suggested_deck is missing', () {
      final json = _validStrategyJson()..remove('suggested_deck');
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.suggestedDeckIds, isEmpty);
      expect(model.suggestedDeckNames, isEmpty);
    });

    test('handles card id as string', () {
      final json = _validStrategyJson();
      (json['suggested_deck'] as List).first['id'] = '26000000';
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.suggestedDeckIds.first, 26000000);
    });

    test('builds deckLinkUrl from resolved card IDs', () {
      final model = AiStrategyReportModel.fromParsedJson(_validStrategyJson());
      expect(model.deckLinkUrl, contains('26000000'));
      expect(model.deckLinkUrl, startsWith('https://link.clashroyale.com/deck/en?deck='));
    });

    test('deckLinkUrl is empty when no cards', () {
      final json = _validStrategyJson()..['suggested_deck'] = [];
      final model = AiStrategyReportModel.fromParsedJson(json);
      expect(model.deckLinkUrl, isEmpty);
    });

    test('parses battle_guide fields with new field names', () {
      final model = AiStrategyReportModel.fromParsedJson(_validStrategyJson());
      expect(model.battleGuide.openingMove, isNotNull);
      expect(model.battleGuide.elixirManagement, isNotNull);
      expect(model.battleGuide.winConditionExecution, isNotNull);
      expect(model.battleGuide.doubleElixirStrategy, isNotNull);
      expect(model.battleGuide.commonMistakes, isNotNull);
    });

    test('parses matchup_tips list', () {
      final model = AiStrategyReportModel.fromParsedJson(_validStrategyJson());
      expect(model.matchupTips, isNotNull);
      expect(model.matchupTips!.length, 2);
      expect(model.matchupTips!.first.enemyArchetype, 'Beatdown');
    });

    test('parses deck_breakdown with all sections', () {
      final model = AiStrategyReportModel.fromParsedJson(_validStrategyJson());
      expect(model.deckBreakdown, isNotNull);
      expect(model.deckBreakdown!.winCondition, contains('Hog Rider'));
      expect(model.deckBreakdown!.spells, contains('Fireball'));
    });
  });
}

Map<String, dynamic> _validStrategyJson() => {
      'playstyle_analysis': 'Test playstyle',
      'archetype_explanation': 'Test archetype explanation',
      'meta_coaching': 'Test meta coaching',
      'suggested_deck': [
        {'id': 26000000, 'name': 'Hog Rider'},
        {'id': 26000001, 'name': 'Fireball'},
        {'id': 26000002, 'name': 'Log'},
        {'id': 26000003, 'name': 'Musketeer'},
        {'id': 26000004, 'name': 'Ice Golem'},
        {'id': 26000005, 'name': 'Skeletons'},
        {'id': 26000006, 'name': 'Cannon'},
        {'id': 26000007, 'name': 'Ice Spirit'},
      ],
      'deck_breakdown': {
        'win_condition': ['Hog Rider'],
        'spells': ['Fireball', 'Log'],
        'air_defense': ['Musketeer'],
        'support': ['Ice Golem', 'Skeletons', 'Ice Spirit'],
        'buildings': ['Cannon'],
      },
      'battle_guide': {
        'opening_move': 'Play Ice Golem in the back.',
        'elixir_management': 'Save 6 elixir before pushing.',
        'defense': 'Use Cannon to kite ground troops.',
        'win_condition_execution': 'Step 1: Ice Golem. Step 2: Hog Rider.',
        'champion_usage': 'No champion in this deck.',
        'evolution_usage': 'No evolutions in this deck.',
        'double_elixir_strategy': 'Double push with Hog Rider.',
        'common_mistakes': 'Do not place Hog without elixir advantage.',
      },
      'matchup_tips': [
        {'enemy_archetype': 'Beatdown', 'tip': 'Cycle quickly.'},
        {'enemy_archetype': 'X-Bow', 'tip': 'Pressure with Hog.'},
      ],
      'confidence_score': 0.9,
    };

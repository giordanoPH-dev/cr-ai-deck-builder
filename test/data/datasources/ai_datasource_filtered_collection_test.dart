import 'package:flutter_test/flutter_test.dart';

import 'package:cr_ai_deck_builder/core/observability/logger_service.dart';
import 'package:cr_ai_deck_builder/data/datasources/ai_datasource.dart';
import 'package:cr_ai_deck_builder/domain/entities/card.dart';
import 'package:cr_ai_deck_builder/domain/entities/player.dart';

class _FakeLogger implements LoggerService {
  @override
  void debug(String message, {Map<String, dynamic>? metadata}) {}
  @override
  void info(String message, {Map<String, dynamic>? metadata}) {}
  @override
  void warn(String message, {Map<String, dynamic>? metadata}) {}
  @override
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {}
  @override
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {}
}

CrCard _card({
  required int id,
  required String name,
  required int level,
  required int maxLevel,
  int elixirCost = 4,
  String? rarity,
  int? evolutionLevel,
  int? maxEvolutionLevel,
}) =>
    CrCard(
      id: id,
      name: name,
      level: level,
      maxLevel: maxLevel,
      iconUrl: '',
      elixirCost: elixirCost,
      rarity: rarity,
      evolutionLevel: evolutionLevel,
      maxEvolutionLevel: maxEvolutionLevel,
    );

void main() {
  late AiDatasourceImpl datasource;

  setUp(() {
    datasource = AiDatasourceImpl(logger: _FakeLogger());
  });

  group('deltaFromMax', () {
    test('maxed Legendary (10/10) returns 0', () {
      final card = _card(id: 1, name: 'Mega Knight', level: 10, maxLevel: 10);
      expect(datasource.deltaFromMax(card), 0);
    });

    test('maxed Common (14/14) returns 0', () {
      final card = _card(id: 2, name: 'Skeletons', level: 14, maxLevel: 14);
      expect(datasource.deltaFromMax(card), 0);
    });

    test('Common at level 12 (maxLevel 14) returns -2', () {
      final card = _card(id: 3, name: 'Skeletons', level: 12, maxLevel: 14);
      expect(datasource.deltaFromMax(card), -2);
    });

    test('Legendary at level 8 (maxLevel 10) returns -2', () {
      final card = _card(id: 4, name: 'Inferno Dragon', level: 8, maxLevel: 10);
      expect(datasource.deltaFromMax(card), -2);
    });

    test('maxed Legendary and maxed Common have equal delta (rarity-fair comparison)', () {
      final legendary = _card(id: 5, name: 'Mega Knight', level: 10, maxLevel: 10);
      final common = _card(id: 6, name: 'Skeletons', level: 14, maxLevel: 14);
      expect(datasource.deltaFromMax(legendary), datasource.deltaFromMax(common));
    });
  });

  group('cardTypeLabelForCard', () {
    test('known Champion name returns [CHAMPION]', () {
      final card = _card(id: 1, name: 'Archer Queen', level: 11, maxLevel: 11);
      expect(datasource.cardTypeLabelForCard(card), '[CHAMPION]');
    });

    test('Champion name is case-insensitive', () {
      final card = _card(id: 1, name: 'golden knight', level: 11, maxLevel: 11);
      expect(datasource.cardTypeLabelForCard(card), '[CHAMPION]');
    });

    test('card with evolutionLevel > 0 returns [EVOLUTION]', () {
      final card = _card(id: 2, name: 'Goblin Barrel', level: 11, maxLevel: 11, evolutionLevel: 1);
      expect(datasource.cardTypeLabelForCard(card), '[EVOLUTION]');
    });

    test('card with maxEvolutionLevel set returns [EVOLUTION]', () {
      final card = _card(id: 3, name: 'Hog Rider', level: 11, maxLevel: 11, maxEvolutionLevel: 1);
      expect(datasource.cardTypeLabelForCard(card), '[EVOLUTION]');
    });

    test('card with evolutionLevel = 0 and no maxEvolutionLevel returns empty string', () {
      final card = _card(id: 4, name: 'Hog Rider', level: 11, maxLevel: 11, evolutionLevel: 0);
      expect(datasource.cardTypeLabelForCard(card), '');
    });

    test('regular card returns empty string', () {
      final card = _card(id: 5, name: 'Fireball', level: 11, maxLevel: 11);
      expect(datasource.cardTypeLabelForCard(card), '');
    });

    test('card with "Evolved " prefix returns [EVOLUTION]', () {
      final card = _card(id: 6, name: 'Evolved Skeletons', level: 11, maxLevel: 11);
      expect(datasource.cardTypeLabelForCard(card), '[EVOLUTION]');
    });
  });

  group('buildFilteredCollection', () {
    test('sorts Champions before Evolutions before regular cards', () {
      final champion = _card(id: 1, name: 'Archer Queen', level: 11, maxLevel: 11);
      final evolution = _card(id: 2, name: 'Hog Rider', level: 11, maxLevel: 11, maxEvolutionLevel: 1);
      final regular = _card(id: 3, name: 'Fireball', level: 11, maxLevel: 11);
      final profile = PlayerProfile(
        tag: '#TEST',
        name: 'Tester',
        trophies: 5000,
        arenaName: 'Master I',
        cards: [regular, evolution, champion],
      );

      final result = datasource.buildFilteredCollection(profile);
      // Champion should appear first in the primary output
      expect(result.primary.indexOf('"Archer Queen"') < result.primary.indexOf('"Fireball"'), isTrue);
      expect(result.primary.indexOf('"Hog Rider"') < result.primary.indexOf('"Fireball"'), isTrue);
    });

    test('cards within 4 levels of best delta go to primary', () {
      // bestDelta = 0 (level 14/14). Card at level 10/14 = delta -4 is on boundary.
      final maxedCard = _card(id: 1, name: 'Skeletons', level: 14, maxLevel: 14);
      final borderCard = _card(id: 2, name: 'Fireball', level: 10, maxLevel: 14);
      final tooLowCard = _card(id: 3, name: 'Arrows', level: 9, maxLevel: 14);
      final profile = PlayerProfile(
        tag: '#TEST',
        name: 'Tester',
        trophies: 5000,
        arenaName: 'Master I',
        cards: [maxedCard, borderCard, tooLowCard],
      );

      final result = datasource.buildFilteredCollection(profile);
      expect(result.primary, contains('"Skeletons"'));
      expect(result.primary, contains('"Fireball"'));
      expect(result.primary, isNot(contains('"Arrows"')));
      expect(result.upgradeable, contains('Arrows'));
    });

    test('Champion always goes to primary regardless of level', () {
      final maxedRegular = _card(id: 1, name: 'Hog Rider', level: 14, maxLevel: 14);
      final lowChampion = _card(id: 2, name: 'Archer Queen', level: 8, maxLevel: 11);
      final profile = PlayerProfile(
        tag: '#TEST',
        name: 'Tester',
        trophies: 5000,
        arenaName: 'Master I',
        cards: [maxedRegular, lowChampion],
      );

      final result = datasource.buildFilteredCollection(profile);
      // Champion must be in primary even though it is far below the best card's level
      expect(result.primary, contains('"Archer Queen"'));
    });

    test('empty collection returns empty primary and "none" upgradeable', () {
      final profile = PlayerProfile(
        tag: '#TEST',
        name: 'Tester',
        trophies: 3000,
        arenaName: 'Hog Mountain',
        cards: const [],
      );

      final result = datasource.buildFilteredCollection(profile);
      expect(result.primary, '');
      expect(result.upgradeable, 'none');
    });
  });
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ROYALE COACH';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get restartApp => 'Reinicia la aplicación.';

  @override
  String get unofficialApp => 'APP FAN NO OFICIAL';

  @override
  String get aiPoweredTagline => 'ESTRATEGIA E INSIGHTS CON IA';

  @override
  String get playerTagLabel => 'ETIQUETA DEL JUGADOR';

  @override
  String get playerTagHint => 'ej: L8P22UR2';

  @override
  String get analyzeButton => 'ANALIZAR PERFIL';

  @override
  String get whereIsMyTag => '¿Dónde está mi Tag?';

  @override
  String get step1 => 'Abre Clash Royale';

  @override
  String get step2 => 'Toca tu Nombre (Arriba a la izquierda)';

  @override
  String get step3 => 'Copia la Tag debajo de tu Nombre';

  @override
  String get tagExample => 'Ejemplo: #L8P22UR2';

  @override
  String get disclaimerText =>
      'Este material no es oficial y no está respaldado por Supercell. Para más información consulta la Política de Contenido de Fan de Supercell: www.supercell.com/fan-content-policy.';

  @override
  String get poweredByGemini => 'Desarrollado con Gemini AI';

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get cacheTooltip => 'Datos en caché (sin conexión)';

  @override
  String get offlineBadge => 'SIN CONEXIÓN';

  @override
  String get aiInsightsTitle => 'ANÁLISIS ESTRATÉGICO IA';

  @override
  String get analyzingText => 'Analizando con Gemini AI...';

  @override
  String get chooseStrategy => 'Elige tu estrategia de batalla:';

  @override
  String get unlockAnalysis =>
      'Desbloquea el análisis experto de tu colección.';

  @override
  String get watchAdButton => 'VER ANUNCIO';

  @override
  String get tabDeck => 'DECK';

  @override
  String get tabCards => 'CARTAS';

  @override
  String get tabBattles => 'BATALLAS';

  @override
  String get tabStats => 'ESTADÍSTICAS';

  @override
  String get trophiesLabel => 'TROFEOS';

  @override
  String get bestRecordLabel => 'RÉCORD';

  @override
  String get levelLabel => 'NIVEL';

  @override
  String get yourDeck => 'TU DECK';

  @override
  String get opponentDeck => 'DECK DEL OPONENTE';

  @override
  String get importButton => 'IMPORTAR EN CLASH ROYALE';

  @override
  String get victory => 'VICTORIA';

  @override
  String get defeat => 'DERROTA';

  @override
  String get draw => 'EMPATE';

  @override
  String get noBattlesFound => 'No se encontraron batallas';

  @override
  String get cardsNotFound => 'Cartas no encontradas';

  @override
  String get deckNotFound => 'Deck no encontrado';

  @override
  String get noCards => 'Sin cartas';

  @override
  String get commonDecks => 'DECKS MÁS COMUNES';

  @override
  String get arenaStrategies => 'ESTRATEGIAS DE ESTA ARENA';

  @override
  String get winTips => 'CONSEJOS PARA GANAR';

  @override
  String arenaGuideNotFound(String arena) {
    return 'Guía no encontrada para $arena';
  }

  @override
  String get playstyleAnalysisTitle => 'ANÁLISIS DE ESTILO';

  @override
  String get metaCoachingTitle => 'COACHING DE META';

  @override
  String get suggestedDeckTitle => 'DECK SUGERIDO';

  @override
  String get battleGuideTitle => 'GUÍA DE BATALLA';

  @override
  String get opening => '⚔️ Apertura';

  @override
  String get defense => '🛡️ Defensa';

  @override
  String get winConditionLabel => '🏆 Victoria';

  @override
  String get importDeckButton => 'IMPORTAR DECK EN CLASH ROYALE';

  @override
  String get reAnalyze => 'RE-ANALIZAR';

  @override
  String confidence(int pct) {
    return 'Confianza: $pct%';
  }

  @override
  String cardLevelInfo(String level, String maxLevel) {
    return 'Nivel $level / $maxLevel';
  }

  @override
  String get archetypeExplanationTitle => 'GUÍA DE ARQUETIPO';

  @override
  String get deckBreakdownTitle => 'COMPOSICIÓN DEL DECK';

  @override
  String get roleWinCondition => 'Win Condition';

  @override
  String get roleSpells => 'Hechizos';

  @override
  String get roleAirDefense => 'Defensa Aérea';

  @override
  String get roleSupport => 'Soporte';

  @override
  String get roleBuildings => 'Edificios';

  @override
  String get elixirManagementTitle => '⚡ Elixir';

  @override
  String get doubleElixirTitle => '⚡⚡ Doble Elixir';

  @override
  String get commonMistakesTitle => '⚠️ Errores Comunes';

  @override
  String get matchupTipsTitle => 'GUÍA DE MATCHUPS';

  @override
  String get vsLabel => 'vs';

  @override
  String get archetypeBeatdown => 'Fuerza Bruta';

  @override
  String get archetypeControl => 'Control';

  @override
  String get archetypeCycle => 'Ciclo';

  @override
  String get archetypeSiege => 'Asedio';

  @override
  String get archetypeBait => 'Cebo';

  @override
  String get chooseArchetypeLabel => 'Elige tu estrategia:';

  @override
  String get currentArenaLabel => 'Arena actual';
}

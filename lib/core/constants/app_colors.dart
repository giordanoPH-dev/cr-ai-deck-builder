import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF0D0D1A);
  static const Color card = Color(0xFF1A1F2E);
  static const Color cardElevated = Color(0xFF222840);
  static const Color overlay = Color(0x33000000);
  static const Color overlayMedium = Color(0x4D000000);
  static const Color overlayStrong = Color(0x80000000);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFB627);
  static const Color primaryDim = Color(0x4DFFB627);
  static const Color primaryBorder = Color(0x33FFB627);
  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentDim = Color(0x334FC3F7);
  static const Color accentBorder = Color(0x334FC3F7);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // white70
  static const Color textMuted = Color(0x8AFFFFFF); // white54
  static const Color textDisabled = Color(0x61FFFFFF); // white38

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successAccent = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFB627);
  static const Color error = Color(0xFFF44336);
  static const Color errorAccent = Color(0xFFFF5252);
  static const Color info = Color(0xFF4FC3F7);

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border = Color(0x14FFFFFF); // white8
  static const Color borderMedium = Color(0x1FFFFFFF); // white12
  static const Color borderStrong = Color(0x33FFFFFF); // white20

  // ── Raridades CR ─────────────────────────────────────────────────────────
  static const Color rarityCommon = Color(0xFFA4D5FF);
  static const Color rarityRare = Color(0xFFF8CA65);
  static const Color rarityEpic = Color(0xFFFD9BFD);
  static const Color rarityLegendary = Color(0xFFAAFF76);
  static const Color rarityChampion = Color(0xFFFDE305);
  static const Color rarityUnknown = Color(0xFF546E7A);

  // ── Grades ────────────────────────────────────────────────────────────────
  static const Color gradeS = Color(0xFFFFD700);
  static const Color gradeA = Color(0xFFFFB627);
  static const Color gradeB = Color(0xFF78909C);
  static const Color gradeC = Color(0xFF8D6E63);
  static const Color gradeD = Color(0xFF546E7A);
  static const Color gradeF = Color(0xFFB71C1C);

  // ── Roles de Carta ────────────────────────────────────────────────────────
  static const Color roleWinCondition = Color(0xFFFFB627);
  static const Color roleTank = Color(0xFFFF7043);
  static const Color roleSupport = Color(0xFFCE93D8);
  static const Color roleSpell = Color(0xFF42A5F5);
  static const Color roleBuilding = Color(0xFF8D6E63);
  static const Color roleSwarm = Color(0xFF66BB6A);
  static const Color roleAirDefense = Color(0xFF29B6F6);
  static const Color roleTrap = Color(0xFFFF7043);
  static const Color roleDefault = Color(0xFF78909C);

  // ── Arquétipos ────────────────────────────────────────────────────────────
  static const Color archetypeBeatdown = Color(0xFFFF7043);
  static const Color archetypeControl = Color(0xFF42A5F5);
  static const Color archetypeCycle = Color(0xFF66BB6A);
  static const Color archetypeSiege = Color(0xFF8D6E63);
  static const Color archetypeBait = Color(0xFFFFB627);

  // ── Resultados de batalha ─────────────────────────────────────────────────
  static const Color battleVictory = Color(0xFF4CAF50);
  static const Color battleDefeat = Color(0xFFF44336);
  static const Color battleDraw = Color(0xFF78909C);

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color rarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return rarityCommon;
      case 'rare':
        return rarityRare;
      case 'epic':
        return rarityEpic;
      case 'legendary':
        return rarityLegendary;
      case 'champion':
        return rarityChampion;
      default:
        return rarityUnknown;
    }
  }

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'S':
        return gradeS;
      case 'A+':
      case 'A':
        return gradeA;
      case 'B':
        return gradeB;
      case 'C':
        return gradeC;
      case 'D':
        return gradeD;
      default:
        return gradeF;
    }
  }

  static Color roleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'wincondition':
      case 'win condition':
        return roleWinCondition;
      case 'tank':
        return roleTank;
      case 'support':
        return roleSupport;
      case 'spell':
        return roleSpell;
      case 'building':
        return roleBuilding;
      case 'swarm':
        return roleSwarm;
      case 'airdefense':
      case 'air defense':
        return roleAirDefense;
      case 'trap':
        return roleTrap;
      default:
        return roleDefault;
    }
  }

  static Color archetypeColor(String archetype) {
    final lower = archetype.toLowerCase();
    if (lower.contains('beatdown') || lower.contains('aggressive')) {
      return archetypeBeatdown;
    }
    if (lower.contains('control')) return archetypeControl;
    if (lower.contains('cycle')) return archetypeCycle;
    if (lower.contains('siege')) return archetypeSiege;
    if (lower.contains('bait')) return archetypeBait;
    return primary;
  }

  static Color battleResultColor(String? result) {
    if (result == null) return battleDraw;
    final lower = result.toLowerCase();
    if (lower.contains('victory') || lower.contains('win')) return battleVictory;
    if (lower.contains('defeat') || lower.contains('loss')) return battleDefeat;
    return battleDraw;
  }
}

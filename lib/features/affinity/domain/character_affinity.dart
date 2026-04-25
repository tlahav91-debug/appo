import 'character.dart';

class CharacterAffinity {
  final Character character;
  final int affinityPoints;

  const CharacterAffinity({
    required this.character,
    required this.affinityPoints,
  });

  /// 1 = Fan, 2 = Supporter, 3 = Close
  int get level {
    if (affinityPoints >= character.affinityThreshold2) return 3;
    if (affinityPoints >= character.affinityThreshold1) return 2;
    return 1;
  }

  String get levelLabel {
    switch (level) {
      case 3: return 'Close';
      case 2: return 'Supporter';
      default: return 'Fan';
    }
  }

  String get levelEmoji {
    switch (level) {
      case 3: return '❤️';
      case 2: return '💜';
      default: return '💙';
    }
  }

  /// Progress fraction within the current level (0.0–1.0)
  double get levelFraction {
    if (level == 3) return 1.0;
    if (level == 2) {
      final range = character.affinityThreshold2 - character.affinityThreshold1;
      return range > 0
          ? (affinityPoints - character.affinityThreshold1) / range
          : 1.0;
    }
    return character.affinityThreshold1 > 0
        ? affinityPoints / character.affinityThreshold1.toDouble()
        : 1.0;
  }

  int get pointsToNextLevel {
    if (level >= 3) return 0;
    if (level == 2) return character.affinityThreshold2 - affinityPoints;
    return character.affinityThreshold1 - affinityPoints;
  }
}

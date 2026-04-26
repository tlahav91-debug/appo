class FanLevelThreshold {
  final int level;
  final int xpRequired;
  final String label;

  const FanLevelThreshold({
    required this.level,
    required this.xpRequired,
    required this.label,
  });

  factory FanLevelThreshold.fromJson(Map<String, dynamic> json) => FanLevelThreshold(
        level: (json['level'] as num).toInt(),
        xpRequired: (json['xp_required'] as num).toInt(),
        label: json['label'] as String,
      );
}

class FanLevel {
  final int level;
  final String label;
  final int xpCurrent;
  final int xpForThisLevel;
  final int xpForNextLevel; // 0 = max level

  const FanLevel({
    required this.level,
    required this.label,
    required this.xpCurrent,
    required this.xpForThisLevel,
    required this.xpForNextLevel,
  });

  bool get isMaxLevel => xpForNextLevel == 0;

  double get progressFraction {
    if (isMaxLevel) return 1.0;
    final span = xpForNextLevel - xpForThisLevel;
    if (span <= 0) return 1.0;
    return ((xpCurrent - xpForThisLevel) / span).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => isMaxLevel ? 0 : xpForNextLevel - xpCurrent;

  static FanLevel fromProfile(
    int xp,
    int level,
    List<FanLevelThreshold> thresholds,
  ) {
    if (thresholds.isEmpty) {
      return FanLevel(
        level: level,
        label: 'Lv.$level',
        xpCurrent: xp,
        xpForThisLevel: 0,
        xpForNextLevel: 100,
      );
    }
    final matches = thresholds.where((t) => t.level == level);
    final current = matches.isNotEmpty ? matches.first : thresholds.first;
    final nextMatches = thresholds.where((t) => t.level == level + 1);
    final next = nextMatches.isNotEmpty ? nextMatches.first : null;

    return FanLevel(
      level: level,
      label: current.label,
      xpCurrent: xp,
      xpForThisLevel: current.xpRequired,
      xpForNextLevel: next?.xpRequired ?? 0,
    );
  }
}

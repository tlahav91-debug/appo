class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final int fanLevel;
  final int xp;
  final int coins;
  final int gems;
  final bool dramaPassActive;
  final int currentEnergy;
  final DateTime lastRefillAt;
  final DateTime? lastPassBonusAt;
  final DateTime? starterPackPurchasedAt;
  final String? referralCode;
  final List<String> genrePreferences;

  const Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.fanLevel,
    required this.xp,
    required this.coins,
    required this.gems,
    required this.dramaPassActive,
    required this.currentEnergy,
    required this.lastRefillAt,
    this.lastPassBonusAt,
    this.starterPackPurchasedAt,
    this.referralCode,
    this.genrePreferences = const [],
  });

  String get displayName => username ?? 'Player';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        username: json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        fanLevel: (json['fan_level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        dramaPassActive: json['drama_pass_active'] as bool? ?? false,
        currentEnergy: (json['current_energy'] as num?)?.toInt() ?? 5,
        lastRefillAt: json['last_refill_at'] != null
            ? DateTime.parse(json['last_refill_at'] as String).toUtc()
            : DateTime.now().toUtc(),
        lastPassBonusAt: json['last_pass_bonus_at'] != null
            ? DateTime.parse(json['last_pass_bonus_at'] as String).toUtc()
            : null,
        starterPackPurchasedAt: json['starter_pack_purchased_at'] != null
            ? DateTime.parse(json['starter_pack_purchased_at'] as String).toUtc()
            : null,
        referralCode: json['referral_code'] as String?,
        genrePreferences: List<String>.from(
            json['genre_preferences'] as List? ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'fan_level': fanLevel,
        'xp': xp,
        'coins': coins,
        'gems': gems,
        'drama_pass_active': dramaPassActive,
        'current_energy': currentEnergy,
        'last_refill_at': lastRefillAt.toIso8601String(),
        'last_pass_bonus_at': lastPassBonusAt?.toIso8601String(),
        'starter_pack_purchased_at': starterPackPurchasedAt?.toIso8601String(),
        'referral_code': referralCode,
        'genre_preferences': genrePreferences,
      };

  Profile copyWith({
    String? username,
    String? avatarUrl,
    int? fanLevel,
    int? xp,
    int? coins,
    int? gems,
    bool? dramaPassActive,
    int? currentEnergy,
    DateTime? lastRefillAt,
    DateTime? lastPassBonusAt,
    DateTime? starterPackPurchasedAt,
    String? referralCode,
  }) =>
      Profile(
        id: id,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        fanLevel: fanLevel ?? this.fanLevel,
        xp: xp ?? this.xp,
        coins: coins ?? this.coins,
        gems: gems ?? this.gems,
        dramaPassActive: dramaPassActive ?? this.dramaPassActive,
        currentEnergy: currentEnergy ?? this.currentEnergy,
        lastRefillAt: lastRefillAt ?? this.lastRefillAt,
        lastPassBonusAt: lastPassBonusAt ?? this.lastPassBonusAt,
        starterPackPurchasedAt: starterPackPurchasedAt ?? this.starterPackPurchasedAt,
        referralCode: referralCode ?? this.referralCode,
      );

  bool get passBonusClaimableToday {
    if (!dramaPassActive) return false;
    if (lastPassBonusAt == null) return true;
    final today = DateTime.now().toUtc();
    return lastPassBonusAt!.year != today.year ||
        lastPassBonusAt!.month != today.month ||
        lastPassBonusAt!.day != today.day;
  }
}

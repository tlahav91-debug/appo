enum MetaItemType { room, outfit, mood }

class MetaItem {
  final String id;
  final String label;
  final String emoji;
  final int gemCost; // 0 = free
  final MetaItemType type;

  const MetaItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.gemCost,
    required this.type,
  });
}

class MetaCatalog {
  static const rooms = [
    MetaItem(id: 'apartment', label: 'Apartment', emoji: '🏠', gemCost: 0,   type: MetaItemType.room),
    MetaItem(id: 'penthouse', label: 'Penthouse', emoji: '🌆', gemCost: 50,  type: MetaItemType.room),
    MetaItem(id: 'mansion',   label: 'Mansion',   emoji: '🏰', gemCost: 120, type: MetaItemType.room),
    MetaItem(id: 'yacht',     label: 'Yacht',     emoji: '⛵', gemCost: 200, type: MetaItemType.room),
    MetaItem(id: 'chalet',    label: 'Chalet',    emoji: '🏔️', gemCost: 150, type: MetaItemType.room),
    MetaItem(id: 'island',    label: 'Island',    emoji: '🏝️', gemCost: 350, type: MetaItemType.room),
  ];
  static const outfits = [
    MetaItem(id: 'casual',     label: 'Casual',     emoji: '👕', gemCost: 0,   type: MetaItemType.outfit),
    MetaItem(id: 'glam',       label: 'Glam',       emoji: '✨', gemCost: 30,  type: MetaItemType.outfit),
    MetaItem(id: 'streetwear', label: 'Streetwear', emoji: '🧢', gemCost: 45,  type: MetaItemType.outfit),
    MetaItem(id: 'formal',     label: 'Formal',     emoji: '🎩', gemCost: 80,  type: MetaItemType.outfit),
    MetaItem(id: 'fantasy',    label: 'Fantasy',    emoji: '🧙', gemCost: 120, type: MetaItemType.outfit),
  ];
  static const moods = [
    MetaItem(id: 'chill',      label: 'Chill',      emoji: '😎', gemCost: 0,  type: MetaItemType.mood),
    MetaItem(id: 'excited',    label: 'Excited',    emoji: '🤩', gemCost: 20, type: MetaItemType.mood),
    MetaItem(id: 'dramatic',   label: 'Dramatic',   emoji: '😤', gemCost: 20, type: MetaItemType.mood),
    MetaItem(id: 'mysterious', label: 'Mysterious', emoji: '🌙', gemCost: 35, type: MetaItemType.mood),
    MetaItem(id: 'boss',       label: 'Boss',       emoji: '👑', gemCost: 50, type: MetaItemType.mood),
  ];
}

class MetaLoadout {
  final String roomId;
  final String outfitId;
  final String moodId;

  const MetaLoadout({
    this.roomId = 'apartment',
    this.outfitId = 'casual',
    this.moodId = 'chill',
  });

  factory MetaLoadout.fromJson(Map<String, dynamic> j) => MetaLoadout(
    roomId: j['room_id'] as String? ?? 'apartment',
    outfitId: j['outfit_id'] as String? ?? 'casual',
    moodId: j['mood_id'] as String? ?? 'chill',
  );
}

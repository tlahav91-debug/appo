import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/application/profile_provider.dart';
import '../application/meta_provider.dart';
import '../domain/meta_item.dart';

class MetaWorldScreen extends ConsumerStatefulWidget {
  const MetaWorldScreen({super.key});

  @override
  ConsumerState<MetaWorldScreen> createState() => _MetaWorldScreenState();
}

class _MetaWorldScreenState extends ConsumerState<MetaWorldScreen> {
  String _selectedRoom = 'apartment';
  String _selectedOutfit = 'casual';
  String _selectedMood = 'chill';
  bool _saving = false;
  bool _loadoutInitialised = false;

  @override
  Widget build(BuildContext context) {
    final loadout = ref.watch(metaLoadoutProvider);
    final unlockedAsync = ref.watch(metaUnlockedIdsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    // Initialise selected values from remote loadout once
    loadout.whenData((data) {
      if (!_loadoutInitialised) {
        _loadoutInitialised = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedRoom = data.roomId;
              _selectedOutfit = data.outfitId;
              _selectedMood = data.moodId;
            });
          }
        });
      }
    });

    final unlockedIds = unlockedAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    '🌟 Meta World',
                    style: GoogleFonts.nunito(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '💎${profile?.gems ?? 0}',
                    style: GoogleFonts.nunito(
                      color: cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Room section
              _SectionLabel(label: 'Your Room'),
              const SizedBox(height: 8),
              _ItemPicker(
                items: MetaCatalog.rooms,
                selected: _selectedRoom,
                unlockedIds: unlockedIds,
                onSelect: (item) => _onSelect(item),
              ),
              const SizedBox(height: 16),

              // Outfit section
              _SectionLabel(label: 'Your Outfit'),
              const SizedBox(height: 8),
              _ItemPicker(
                items: MetaCatalog.outfits,
                selected: _selectedOutfit,
                unlockedIds: unlockedIds,
                onSelect: (item) => _onSelect(item),
              ),
              const SizedBox(height: 16),

              // Mood section
              _SectionLabel(label: 'Your Mood'),
              const SizedBox(height: 8),
              _ItemPicker(
                items: MetaCatalog.moods,
                selected: _selectedMood,
                unlockedIds: unlockedIds,
                onSelect: (item) => _onSelect(item),
              ),

              const Spacer(),

              // Save button
              _SaveButton(saving: _saving, onPressed: _save),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelect(MetaItem item) {
    setState(() {
      switch (item.type) {
        case MetaItemType.room:
          _selectedRoom = item.id;
        case MetaItemType.outfit:
          _selectedOutfit = item.id;
        case MetaItemType.mood:
          _selectedMood = item.id;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(metaServiceProvider).equip(
      roomId: _selectedRoom,
      outfitId: _selectedOutfit,
      moodId: _selectedMood,
    );
    setState(() => _saving = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'World saved! ✨',
            style: GoogleFonts.nunito(color: textCol),
          ),
          backgroundColor: card,
        ),
      );
    }
  }
}

// ─── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        color: textSec,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Save button ─────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;
  const _SaveButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: saving ? null : pinkFull,
          color: saving ? pinkDim : null,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textCol),
                ),
              )
            : Text(
                'Save My World',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ─── Item picker ─────────────────────────────────────────────────────────────

class _ItemPicker extends ConsumerWidget {
  final List<MetaItem> items;
  final String selected;
  final Set<String> unlockedIds;
  final void Function(MetaItem item) onSelect;

  const _ItemPicker({
    required this.items,
    required this.selected,
    required this.unlockedIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.id == selected;
          final isUnlocked = item.gemCost == 0 || unlockedIds.contains(item.id);
          return Padding(
            padding: EdgeInsets.only(right: index < items.length - 1 ? 10 : 0),
            child: _ItemCard(
              item: item,
              isSelected: isSelected,
              isUnlocked: isUnlocked,
              onTap: () => _handleTap(context, ref, item, isUnlocked),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
      BuildContext context, WidgetRef ref, MetaItem item, bool isUnlocked) {
    if (isUnlocked) {
      onSelect(item);
      return;
    }
    // Locked — show purchase confirmation dialog
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unlock ${item.label}?',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(
          'This will cost 💎${item.gemCost} gems.',
          style: GoogleFonts.sora(color: textSec, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: textDim, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref
                  .read(metaServiceProvider)
                  .unlock(item.type.name, item.id);
              if (result.unlocked) {
                ref.invalidate(metaUnlockedIdsProvider);
                ref.invalidate(profileProvider);
                onSelect(item);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.error ?? 'Unlock failed',
                      style: GoogleFonts.nunito(color: textCol),
                    ),
                    backgroundColor: card,
                  ),
                );
              }
            },
            child: Text(
              'Unlock 💎${item.gemCost}',
              style: GoogleFonts.nunito(
                  color: gold, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item card ───────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final MetaItem item;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Container(
          width: 100,
          height: 110,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? pink : border,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: GoogleFonts.sora(
                        color: textCol,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _CostBadge(item: item, isUnlocked: isUnlocked),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  final MetaItem item;
  final bool isUnlocked;

  const _CostBadge({required this.item, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    if (isUnlocked && item.gemCost == 0) {
      // Free badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: greenDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'FREE',
          style: GoogleFonts.nunito(
            color: green,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (isUnlocked) {
      // Owned checkmark
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cyanDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '✓ Owned',
          style: GoogleFonts.nunito(
            color: cyan,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    // Locked — gem cost in gold
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: goldDim,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '💎${item.gemCost}',
        style: GoogleFonts.nunito(
          color: gold,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

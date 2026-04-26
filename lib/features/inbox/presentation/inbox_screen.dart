import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/profile/application/profile_provider.dart';
import '../application/inbox_provider.dart';
import '../data/inbox_service.dart';
import '../domain/inbox_item.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProviderScope(child: InboxScreen()),
    );
  }

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final Set<String> _claiming = {};

  Future<void> _claim(InboxItem item) async {
    if (_claiming.contains(item.id)) return;
    setState(() => _claiming.add(item.id));

    final result = await ref.read(inboxServiceProvider).claimItem(item.id);

    setState(() => _claiming.remove(item.id));

    if (!mounted) return;
    if (result.claimed) {
      ref.invalidate(inboxItemsProvider);
      ref.invalidate(profileProvider);
      final parts = <String>[];
      if (result.coinsEarned > 0) parts.add('🪙 ${result.coinsEarned}');
      if (result.gemsEarned > 0) parts.add('💎 ${result.gemsEarned}');
      if (parts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('+${parts.join('  ')} claimed!', style: GoogleFonts.nunito(color: textCol)),
          backgroundColor: card, duration: const Duration(seconds: 2),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Claim failed', style: GoogleFonts.nunito(color: textCol)),
        backgroundColor: lava,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inboxItemsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                const Text('📬', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text('Inbox', style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: textDim, size: 22),
                ),
              ]),
            ),
            const Divider(color: border, height: 1),
            // List
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: pink, strokeWidth: 2)),
                error: (_, __) => Center(child: Text('Failed to load', style: GoogleFonts.sora(color: textDim))),
                data: (items) => items.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.mail_outline, color: textDim, size: 48),
                      const SizedBox(height: 12),
                      Text('All caught up!', style: GoogleFonts.nunito(color: textDim, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Check back soon', style: GoogleFonts.sora(color: textDim, fontSize: 13)),
                    ]))
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _InboxItemCard(
                        item: items[i],
                        isClaiming: _claiming.contains(items[i].id),
                        onClaim: () => _claim(items[i]),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxItemCard extends StatelessWidget {
  final InboxItem item;
  final bool isClaiming;
  final VoidCallback onClaim;

  const _InboxItemCard({required this.item, required this.isClaiming, required this.onClaim});

  String get _typeEmoji => switch (item.type) {
    'reward' => '🎁',
    'event'  => '⚡',
    _        => '📢',
  };

  @override
  Widget build(BuildContext context) {
    final dimmed = item.claimed || item.isExpired;
    return AnimatedOpacity(
      opacity: dimmed ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: !item.claimed && !item.isExpired ? borderHi : border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_typeEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 14)),
            if (item.body != null) ...[
              const SizedBox(height: 4),
              Text(item.body!, style: GoogleFonts.sora(color: textSec, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (item.hasReward) ...[
              const SizedBox(height: 8),
              Row(children: [
                if (item.rewardCoins > 0) _RewardChip('🪙 ${item.rewardCoins}', gold),
                if (item.rewardCoins > 0 && item.rewardGems > 0) const SizedBox(width: 8),
                if (item.rewardGems > 0) _RewardChip('💎 ${item.rewardGems}', cyan),
              ]),
            ],
          ])),
          const SizedBox(width: 8),
          if (item.isExpired)
            Text('Expired', style: GoogleFonts.sora(color: textDim, fontSize: 11))
          else if (item.claimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
              child: Text('Claimed ✓', style: GoogleFonts.nunito(color: textDim, fontSize: 12, fontWeight: FontWeight.w700)),
            )
          else if (item.hasReward)
            GestureDetector(
              onTap: isClaiming ? null : onClaim,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(gradient: pinkFull, borderRadius: BorderRadius.circular(10)),
                child: isClaiming
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Claim', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RewardChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
  );
}

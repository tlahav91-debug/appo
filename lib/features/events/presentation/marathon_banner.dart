import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/application/profile_provider.dart';
import '../application/marathon_provider.dart';
import '../domain/marathon_event.dart';

/// Home-screen banner: shown when any live marathon exists.
class MarathonHomeBanner extends ConsumerWidget {
  const MarathonHomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marathons = ref.watch(activeMarathonsProvider).valueOrNull ?? [];
    final live = marathons.where((m) => m.isLive && !m.rewardClaimed).toList();
    if (live.isEmpty) return const SizedBox.shrink();
    return Column(
      children: live
          .map((m) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _MarathonCard(marathon: m),
              ))
          .toList(),
    );
  }
}

/// Series-screen banner: shown when there's a live marathon for this series.
class MarathonSeriesBanner extends ConsumerWidget {
  final String seriesId;
  const MarathonSeriesBanner({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marathon = ref.watch(seriesMarathonProvider(seriesId)).valueOrNull;
    if (marathon == null || !marathon.isLive) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _MarathonCard(marathon: marathon, compact: true),
    );
  }
}

class _MarathonCard extends StatefulWidget {
  final MarathonEvent marathon;
  final bool compact;
  const _MarathonCard({required this.marathon, this.compact = false});

  @override
  State<_MarathonCard> createState() => _MarathonCardState();
}

class _MarathonCardState extends State<_MarathonCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.marathon.timeRemaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = widget.marathon.timeRemaining);
      if (_remaining == Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    if (_remaining == Duration.zero) return 'Ended';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m left';
    if (m > 0) return '${m}m ${s}s left';
    return '${s}s left';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/series/${widget.marathon.seriesId}'),
      child: Container(
        padding: EdgeInsets.all(widget.compact ? 12 : 16),
        decoration: BoxDecoration(
          gradient: lavaGrad,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🏃', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.compact ? 'Marathon Active!' : widget.marathon.title,
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.compact ? 13 : 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '🪙 +${widget.marathon.rewardCoins} coins · $_countdownText',
                    style: GoogleFonts.sora(
                      color: textCol.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.marathon.rewardClaimed)
              _ClaimButton(marathon: widget.marathon)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('✓ Claimed',
                    style: GoogleFonts.sora(color: textCol, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends ConsumerStatefulWidget {
  final MarathonEvent marathon;
  const _ClaimButton({required this.marathon});

  @override
  ConsumerState<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends ConsumerState<_ClaimButton> {
  bool _loading = false;

  Future<void> _claim() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) { setState(() => _loading = false); return; }
      final res = await Supabase.instance.client.functions.invoke(
        'claim-marathon-reward',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'marathon_id': widget.marathon.id},
      );
      final data = res.data as Map<String, dynamic>;
      if (!mounted) return;
      if (data['granted'] == true) {
        ref.invalidate(activeMarathonsProvider);
        ref.invalidate(profileProvider);
        messenger.showSnackBar(SnackBar(
          content: Text(
            '🏆 Marathon complete! +${widget.marathon.rewardCoins} 🪙',
          ),
        ));
      } else if (data['error'] == 'Series not fully completed yet') {
        messenger.showSnackBar(
          const SnackBar(content: Text('Finish all episodes first!')),
        );
      } else if (data['already_claimed'] == true) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Already claimed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _claim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: textCol),
              )
            : Text(
                'Claim',
                style: GoogleFonts.nunito(
                  color: textCol,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

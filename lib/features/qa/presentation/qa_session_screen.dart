import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/qa_provider.dart';
import '../domain/qa_session.dart';

class QASessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const QASessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<QASessionScreen> createState() => _QASessionScreenState();
}

class _QASessionScreenState extends ConsumerState<QASessionScreen> {
  final List<Map<String, dynamic>> _messages = [];
  bool _sessionEnded = false;
  int _presenceCount = 1;
  final Map<String, int> _reactions = {
    '❤️': 0,
    '😂': 0,
    '😱': 0,
    '🔥': 0,
  };
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _initChannel();
  }

  void _initChannel() {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    _channel = Supabase.instance.client.channel('qa:${widget.sessionId}');
    _channel
      ..onBroadcast(
        event: 'message',
        callback: (payload) {
          if (mounted) {
            setState(() => _messages
                .add(Map<String, dynamic>.from(payload)));
          }
        },
      )
      ..onBroadcast(
        event: 'session_ended',
        callback: (_) {
          if (mounted) setState(() => _sessionEnded = true);
        },
      )
      ..onPresenceJoin((_) {
        if (mounted) setState(() => _presenceCount++);
      })
      ..onPresenceLeave((_) {
        if (mounted) {
          setState(
              () => _presenceCount = (_presenceCount - 1).clamp(1, 9999));
        }
      });
    _channel.subscribe((status, [_]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _channel.track({'user_id': userId});
      }
    });
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(qaSessionDetailProvider(widget.sessionId));
    final title = sessionAsync.valueOrNull?.title ?? 'Live Q&A';
    final isEnded = _sessionEnded ||
        sessionAsync.valueOrNull?.status == QAStatus.ended;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(title,
            style: GoogleFonts.nunito(
                color: textCol,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$_presenceCount',
                    style: GoogleFonts.sora(
                        color: textSec, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isEnded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: surface,
              child: Text(
                'Session ended 🎬',
                style: GoogleFonts.nunito(
                    color: textDim,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎤',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          isEnded
                              ? 'This session has ended.'
                              : 'Waiting for messages…',
                          style: GoogleFonts.sora(
                              color: textDim, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageCard(
                      body: _messages[i]['body'] as String? ?? '',
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _reactions.entries.map((e) {
                return GestureDetector(
                  onTap: () => setState(
                      () => _reactions[e.key] = e.value + 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.key,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 2),
                      Text('${e.value}',
                          style: GoogleFonts.nunito(
                              color: textSec,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String body;
  const _MessageCard({required this.body});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderHi),
        ),
        child: Text(body,
            style: GoogleFonts.sora(color: textCol, fontSize: 14)),
      ),
    );
  }
}

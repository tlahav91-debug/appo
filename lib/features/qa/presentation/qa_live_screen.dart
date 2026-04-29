import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/qa_provider.dart';
import '../domain/qa_session.dart';

class QALiveScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const QALiveScreen({super.key, required this.sessionId});

  @override
  ConsumerState<QALiveScreen> createState() => _QALiveScreenState();
}

class _QALiveScreenState extends ConsumerState<QALiveScreen> {
  bool _starting = false;
  bool _ending = false;
  bool _started = false;
  DateTime? _startedAt;
  List<QAMessage> _messages = [];
  final Set<int> _broadcastPositions = {};
  final List<Timer> _msgTimers = [];
  Timer? _countdownTimer;
  RealtimeChannel? _channel;
  String? _error;

  @override
  void dispose() {
    for (final t in _msgTimers) {
      t.cancel();
    }
    _countdownTimer?.cancel();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not signed in');
      final res = await Supabase.instance.client.functions.invoke(
        'start-qa-session',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'session_id': widget.sessionId},
      );
      final data = res.data as Map<String, dynamic>;
      final msgs = (data['messages'] as List)
          .map((m) => QAMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      final startedAt = DateTime.parse(data['started_at'] as String);

      _channel = Supabase.instance.client.channel('qa:${widget.sessionId}');
      _channel!.subscribe();

      setState(() {
        _started = true;
        _startedAt = startedAt;
        _messages = msgs;
        _starting = false;
      });

      _scheduleMessages(startedAt);
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _scheduleMessages(DateTime startedAt) {
    for (final msg in _messages) {
      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      final remaining = msg.delaySeconds - elapsed;
      final delay =
          Duration(seconds: remaining > 0 ? remaining : 0);
      final timer = Timer(delay, () {
        if (!mounted) return;
        _broadcastPositions.add(msg.position);
        _channel?.sendBroadcastMessage(
          event: 'message',
          payload: {
            'id': msg.id,
            'body': msg.body,
            'position': msg.position
          },
        );
        if (mounted) setState(() {});
      });
      _msgTimers.add(timer);
    }
  }

  Future<void> _endSession() async {
    if (_ending) return;
    setState(() => _ending = true);
    try {
      await _channel?.sendBroadcastMessage(
          event: 'session_ended', payload: {});
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not signed in');
      await Supabase.instance.client.functions.invoke(
        'end-qa-session',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'session_id': widget.sessionId},
      );
      if (mounted) context.go('/creator/status');
    } catch (e) {
      if (mounted) {
        setState(() {
          _ending = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(qaSessionDetailProvider(widget.sessionId));
    final title = sessionAsync.valueOrNull?.title ?? 'Q&A Live';

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
          if (_started)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _ending ? null : _endSession,
                child: _ending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: lava, strokeWidth: 2))
                    : Text('End Session',
                        style: GoogleFonts.nunito(
                            color: lava,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_started) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: purpleGrad,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🎤', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Ready to go live?',
                      style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w900,
                          fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your followers will be notified when you start.',
                      style: GoogleFonts.sora(
                          color: textCol.withAlpha(200), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _starting ? null : _startSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _starting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: textCol, strokeWidth: 2))
                            : Text('Start Session',
                                style: GoogleFonts.nunito(
                                    color: textCol,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: lava, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE',
                      style: GoogleFonts.nunito(
                          color: lava,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const Spacer(),
                  Text(
                    '${_broadcastPositions.length}/${_messages.length} sent',
                    style: GoogleFonts.sora(color: textDim, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final sent =
                        _broadcastPositions.contains(msg.position);
                    final elapsed = _startedAt != null
                        ? DateTime.now()
                            .difference(_startedAt!)
                            .inSeconds
                        : 0;
                    final remaining =
                        (msg.delaySeconds - elapsed).clamp(0, 99999);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sent ? card : surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: sent ? cyan : borderHi),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            sent
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            color: sent ? cyan : textDim,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(msg.body,
                                    style: GoogleFonts.sora(
                                        color: textCol, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  sent
                                      ? 'Sent ✓'
                                      : (remaining > 0
                                          ? 'In ${remaining}s'
                                          : 'Sending…'),
                                  style: GoogleFonts.sora(
                                      color: sent ? cyan : textDim,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.sora(color: lava, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

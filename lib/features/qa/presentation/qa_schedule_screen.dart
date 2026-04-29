import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/qa_provider.dart';
import '../domain/qa_session.dart';

class QAScheduleScreen extends ConsumerStatefulWidget {
  const QAScheduleScreen({super.key});

  @override
  ConsumerState<QAScheduleScreen> createState() => _QAScheduleScreenState();
}

class _QAScheduleScreenState extends ConsumerState<QAScheduleScreen> {
  final _titleCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  final List<_MsgEntry> _msgs = [_MsgEntry()];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final m in _msgs) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (_saving) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: purple, surface: surface),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: purple, surface: surface),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    final validMsgs = _msgs.where((m) => m.bodyCtrl.text.trim().isNotEmpty).toList();
    if (validMsgs.isEmpty) {
      setState(() => _error = 'Add at least one message');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final messages = validMsgs.asMap().entries.map((e) => QAMessage(
            id: '',
            sessionId: '',
            body: e.value.bodyCtrl.text.trim(),
            delaySeconds: int.tryParse(e.value.delayCtrl.text) ?? 0,
            position: e.key,
          )).toList();
      final sessionId = await ref
          .read(qaRepositoryProvider)
          .createSession(title, _scheduledAt, messages);
      ref.invalidate(myQASessionsProvider);
      if (mounted) context.go('/qa/live/$sessionId');
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Failed to save. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Schedule Q&A 🎤',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: purple, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: GoogleFonts.nunito(
                      color: purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Title',
              style: GoogleFonts.nunito(color: textSec, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.nunito(
                color: textCol, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'e.g. Behind the scenes Q&A',
              hintStyle: GoogleFonts.sora(color: textDim),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: purple, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text('Scheduled Time',
              style: GoogleFonts.nunito(color: textSec, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderHi),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: purple, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_scheduledAt.year}-'
                    '${_scheduledAt.month.toString().padLeft(2, '0')}-'
                    '${_scheduledAt.day.toString().padLeft(2, '0')} '
                    '${_scheduledAt.hour.toString().padLeft(2, '0')}:'
                    '${_scheduledAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.nunito(
                        color: textCol, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_outlined,
                      color: textDim, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Messages',
                  style: GoogleFonts.nunito(color: textSec, fontSize: 13)),
              const Spacer(),
              Text('${_msgs.length}/20',
                  style: GoogleFonts.sora(color: textDim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ..._msgs.asMap().entries.map((e) => _MessageRow(
                index: e.key,
                entry: e.value,
                onRemove: _msgs.length > 1
                    ? () => setState(() => _msgs.removeAt(e.key))
                    : null,
              )),
          const SizedBox(height: 12),
          if (_msgs.length < 20)
            GestureDetector(
              onTap: () => setState(() => _msgs.add(_MsgEntry())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderHi),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: purple, size: 18),
                    const SizedBox(width: 6),
                    Text('Add Message',
                        style: GoogleFonts.nunito(
                            color: purple, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: GoogleFonts.sora(color: lava, fontSize: 13)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MsgEntry {
  final bodyCtrl = TextEditingController();
  final delayCtrl = TextEditingController(text: '0');

  void dispose() {
    bodyCtrl.dispose();
    delayCtrl.dispose();
  }
}

class _MessageRow extends StatelessWidget {
  final int index;
  final _MsgEntry entry;
  final VoidCallback? onRemove;

  const _MessageRow(
      {required this.index, required this.entry, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderHi),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${index + 1}',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11)),
              const Spacer(),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, color: textDim, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: entry.bodyCtrl,
            style: GoogleFonts.sora(color: textCol, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Message text...',
              hintStyle: GoogleFonts.sora(color: textDim, fontSize: 13),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: textDim, size: 14),
              const SizedBox(width: 6),
              Text('Delay (seconds):',
                  style: GoogleFonts.sora(color: textDim, fontSize: 12)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: entry.delayCtrl,
                  style: GoogleFonts.sora(color: textCol, fontSize: 13),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

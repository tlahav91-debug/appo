import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/admin_provider.dart';

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(adminSubmissionsProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: const BackButton(color: textCol),
        title: Text(
          'Content Moderation',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pink)),
        error: (_, __) => Center(
          child: Text('Failed to load', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (submissions) => submissions.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Queue is clear',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'No pending submissions',
                      style: GoogleFonts.sora(color: textDim, fontSize: 13),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: pink,
                onRefresh: () async => ref.invalidate(adminSubmissionsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: submissions.length,
                  itemBuilder: (context, index) => _SubmissionCard(
                    sub: submissions[index],
                    ref: ref,
                  ),
                ),
              ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final WidgetRef ref;

  const _SubmissionCard({required this.sub, required this.ref});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = sub['thumbnail_url'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 80,
              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                  ? Image.network(thumbnailUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: card,
                        child: const Icon(Icons.movie_outlined, color: textDim),
                      ))
                  : Container(
                      color: card,
                      child: const Icon(Icons.movie_outlined, color: textDim),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub['title'] as String? ?? '',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub['creator_name'] as String? ?? '',
                  style: GoogleFonts.sora(color: textSec, fontSize: 12),
                ),
                Text(
                  sub['genre'] as String? ?? 'No genre',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                ),
                Text(
                  'Ep ${sub['episode_number']} · ${_fmtDate(sub['submitted_at'] as String? ?? '')}',
                  style: GoogleFonts.sora(color: textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showApproveSheet(context, sub, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: greenGrad,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.sora(
                      color: textCol,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showRejectSheet(context, sub, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: pinkGrad,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.sora(
                      color: textCol,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApproveSheet(BuildContext context, Map<String, dynamic> sub, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApproveSheet(sub: sub, ref: ref),
    );
  }

  void _showRejectSheet(BuildContext context, Map<String, dynamic> sub, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectSheet(sub: sub, ref: ref),
    );
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }
}

class _ApproveSheet extends StatefulWidget {
  final Map<String, dynamic> sub;
  final WidgetRef ref;

  const _ApproveSheet({required this.sub, required this.ref});

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  bool _newSeries = true;
  final _newTitleController = TextEditingController();
  final _seriesIdController = TextEditingController();
  int _episodeOrder = 1;
  bool _isFree = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _episodeOrder = (widget.sub['episode_number'] as num?)?.toInt() ?? 1;
  }

  @override
  void dispose() {
    _newTitleController.dispose();
    _seriesIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderHi,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Approve Episode',
              style: GoogleFonts.nunito(
                color: textCol,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.sub['title'] as String? ?? '',
              style: GoogleFonts.sora(color: textSec, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text('Series', style: GoogleFonts.sora(color: textSec, fontSize: 12)),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              value: true,
              groupValue: _newSeries,
              onChanged: (v) => setState(() => _newSeries = v!),
              title: Text('New series', style: GoogleFonts.sora(color: textCol, fontSize: 13)),
              activeColor: pink,
              contentPadding: EdgeInsets.zero,
            ),
            if (_newSeries)
              TextField(
                controller: _newTitleController,
                style: GoogleFonts.sora(color: textCol, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Series title...',
                  hintStyle: GoogleFonts.sora(color: textDim, fontSize: 13),
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            RadioListTile<bool>(
              value: false,
              groupValue: _newSeries,
              onChanged: (v) => setState(() => _newSeries = v!),
              title: Text('Existing series ID', style: GoogleFonts.sora(color: textCol, fontSize: 13)),
              activeColor: pink,
              contentPadding: EdgeInsets.zero,
            ),
            if (!_newSeries)
              TextField(
                controller: _seriesIdController,
                style: GoogleFonts.sora(color: textCol, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Series UUID...',
                  hintStyle: GoogleFonts.sora(color: textDim, fontSize: 13),
                  filled: true,
                  fillColor: card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Episode Order', style: GoogleFonts.sora(color: textSec, fontSize: 12)),
                const Spacer(),
                Row(
                  children: [
                    _CounterBtn(
                      icon: Icons.remove,
                      onTap: () => setState(() {
                        if (_episodeOrder > 1) _episodeOrder--;
                      }),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_episodeOrder',
                      style: GoogleFonts.nunito(
                        color: textCol,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CounterBtn(
                      icon: Icons.add,
                      onTap: () => setState(() => _episodeOrder++),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Free episode', style: GoogleFonts.sora(color: textSec, fontSize: 12)),
                const Spacer(),
                Switch(
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v),
                  activeColor: cyan,
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: greenGrad,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const CircularProgressIndicator(color: textCol, strokeWidth: 2)
                    : Text(
                        'Approve & Publish',
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final seriesId = _newSeries ? null : _seriesIdController.text.trim();
    final newTitle = _newSeries ? _newTitleController.text.trim() : null;

    if (_newSeries && (newTitle == null || newTitle.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a series title')),
      );
      return;
    }
    if (!_newSeries && (seriesId == null || seriesId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a series ID')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.ref.read(adminRepositoryProvider).approveSubmission(
        submissionId: widget.sub['id'] as String,
        isFree: _isFree,
        episodeOrder: _episodeOrder,
        seriesId: seriesId,
        newSeriesTitle: newTitle,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.ref.invalidate(adminSubmissionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _RejectSheet extends StatefulWidget {
  final Map<String, dynamic> sub;
  final WidgetRef ref;

  const _RejectSheet({required this.sub, required this.ref});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderHi,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reject Submission',
              style: GoogleFonts.nunito(
                color: textCol,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.sub['title'] as String? ?? '',
              style: GoogleFonts.sora(color: textSec, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              style: GoogleFonts.sora(color: textCol, fontSize: 13),
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: GoogleFonts.sora(color: textDim, fontSize: 13),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: GoogleFonts.sora(color: textDim, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: pinkGrad,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const CircularProgressIndicator(color: textCol, strokeWidth: 2)
                    : Text(
                        'Reject',
                        style: GoogleFonts.nunito(
                          color: textCol,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a rejection reason')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.ref.read(adminRepositoryProvider).rejectSubmission(
        submissionId: widget.sub['id'] as String,
        reason: reason,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.ref.invalidate(adminSubmissionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: textCol, size: 16),
      ),
    );
  }
}

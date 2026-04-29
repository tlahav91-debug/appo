import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_series_provider.dart';

class CreatorAddEpisodeScreen extends ConsumerStatefulWidget {
  final String seriesId;
  const CreatorAddEpisodeScreen({super.key, required this.seriesId});

  @override
  ConsumerState<CreatorAddEpisodeScreen> createState() =>
      _CreatorAddEpisodeScreenState();
}

class _CreatorAddEpisodeScreenState
    extends ConsumerState<CreatorAddEpisodeScreen> {
  final _titleCtrl = TextEditingController();
  final _epNumCtrl = TextEditingController(text: '1');
  final _fileSizeCtrl = TextEditingController();
  bool _isFree = false;

  String? _submissionId;
  String? _uploadUrl;
  bool _requesting = false;
  bool _submitting = false;
  bool _uploadConfirmed = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _epNumCtrl.dispose();
    _fileSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestSlot() async {
    final title = _titleCtrl.text.trim();
    final epNum = int.tryParse(_epNumCtrl.text.trim()) ?? 0;
    final sizeMb = int.tryParse(_fileSizeCtrl.text.trim()) ?? 0;

    if (title.isEmpty) {
      _setError('Episode title is required');
      return;
    }
    if (epNum <= 0) {
      _setError('Enter a valid episode number');
      return;
    }
    if (sizeMb <= 0) {
      _setError('Enter the approximate video file size (MB)');
      return;
    }

    setState(() {
      _requesting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(creatorSeriesRepositoryProvider)
          .requestUploadSlot(
            seriesId: widget.seriesId,
            title: title,
            episodeNumber: epNum,
            fileSizeMb: sizeMb,
          );
      if (mounted) {
        setState(() {
          _submissionId = result.submissionId;
          _uploadUrl = result.uploadUrl;
          _requesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _requesting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitForReview() async {
    if (_submissionId == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(creatorSeriesRepositoryProvider)
          .submitForReview(_submissionId!);
      ref.invalidate(seriesSubmissionsProvider(widget.seriesId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _setError(String msg) =>
      setState(() => _error = msg);

  void _copyUrl() {
    if (_uploadUrl == null) return;
    Clipboard.setData(ClipboardData(text: _uploadUrl!));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Upload URL copied',
          style: GoogleFonts.sora(color: textCol)),
      backgroundColor: surface,
      behavior: SnackBarBehavior.floating,
    ));
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
          'Add Episode',
          style: GoogleFonts.nunito(
              color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _label('Episode Title'),
          const SizedBox(height: 8),
          _textField(_titleCtrl, hint: 'Episode title'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Episode Number'),
                    const SizedBox(height: 8),
                    _textField(_epNumCtrl,
                        hint: '1',
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('File Size (MB)'),
                    const SizedBox(height: 8),
                    _textField(_fileSizeCtrl,
                        hint: 'e.g. 500',
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // is_free toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('Free episode',
                    style: GoogleFonts.sora(color: textCol, fontSize: 14)),
                const Spacer(),
                Switch(
                  value: _isFree,
                  activeColor: gold,
                  onChanged: (v) => setState(() => _isFree = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Request Upload Slot button
          if (_submissionId == null)
            GestureDetector(
              onTap: _requesting ? null : _requestSlot,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: _requesting ? null : purpleGrad,
                  color: _requesting ? card : null,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: _requesting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: textCol, strokeWidth: 2))
                    : Text(
                        'Request Upload Slot',
                        style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
              ),
            ),

          // Upload URL section
          if (_uploadUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cyan),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: cyan, size: 16),
                      const SizedBox(width: 6),
                      Text('Upload slot created',
                          style: GoogleFonts.nunito(
                              color: cyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use this TUS upload URL with your video upload client:',
                    style: GoogleFonts.sora(color: textSec, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _uploadUrl!,
                    style: GoogleFonts.sora(
                        color: textDim, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _copyUrl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_outlined,
                            color: gold, size: 14),
                        const SizedBox(width: 4),
                        Text('Copy URL',
                            style: GoogleFonts.sora(
                                color: gold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Upload confirmation gate — prevents submitting before video is uploaded
            GestureDetector(
              onTap: () => setState(() => _uploadConfirmed = !_uploadConfirmed),
              child: Row(
                children: [
                  Checkbox(
                    value: _uploadConfirmed,
                    activeColor: cyan,
                    onChanged: (v) =>
                        setState(() => _uploadConfirmed = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'I have finished uploading the video to the TUS URL above',
                      style: GoogleFonts.sora(color: textSec, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: (_submitting || !_uploadConfirmed) ? null : _submitForReview,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: (_submitting || !_uploadConfirmed) ? null : goldGrad,
                  color: (_submitting || !_uploadConfirmed) ? card : null,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: textCol, strokeWidth: 2))
                    : Text(
                        'Submit for Review',
                        style: GoogleFonts.nunito(
                            color: textCol,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
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
    );
  }

  Widget _label(String text) =>
      Text(text, style: GoogleFonts.sora(color: textSec, fontSize: 12));

  Widget _textField(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.sora(color: textCol, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(color: textDim, fontSize: 15),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cyan, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

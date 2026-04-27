import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_provider.dart';

class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _whyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_displayNameCtrl.text.trim().isEmpty ||
        _bioCtrl.text.trim().isEmpty ||
        _whyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(applyCreatorProvider.notifier).apply(
      displayName: _displayNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      whyCreate: _whyCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err != null && err != 'ALREADY_APPLIED') {
      if (err == 'Not logged in') {
        context.go('/auth');
        return;
      }
      setState(() { _loading = false; _error = err; });
      return;
    }
    setState(() => _loading = false);
    ref.invalidate(creatorProfileProvider);
    context.go('/creator/status');
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
          'Become a Creator',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about yourself',
              style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'We review every application. We\'ll update you in the app.',
              style: GoogleFonts.sora(color: textSec, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _field('Creator name', _displayNameCtrl, maxLines: 1),
            const SizedBox(height: 16),
            _field('Short bio (max 300 chars)', _bioCtrl, maxLines: 3, maxLength: 300),
            const SizedBox(height: 16),
            _field('Why do you want to create on this platform?', _whyCtrl, maxLines: 4),
            const SizedBox(height: 28),
            if (_error != null) ...[
              Text(_error!, style: GoogleFonts.sora(color: pink, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: purpleGrad,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: textCol),
                      )
                    : Text(
                        'Submit Application',
                        style: GoogleFonts.nunito(
                          color: textCol, fontWeight: FontWeight.w800, fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(color: textSec, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.sora(color: textCol, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: surface,
            counterStyle: GoogleFonts.sora(color: textDim, fontSize: 11),
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
              borderSide: const BorderSide(color: purple),
            ),
          ),
        ),
      ],
    );
  }
}

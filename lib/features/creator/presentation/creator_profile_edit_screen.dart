import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_provider.dart';

class CreatorProfileEditScreen extends ConsumerStatefulWidget {
  const CreatorProfileEditScreen({super.key});

  @override
  ConsumerState<CreatorProfileEditScreen> createState() =>
      _CreatorProfileEditScreenState();
}

class _CreatorProfileEditScreenState
    extends ConsumerState<CreatorProfileEditScreen> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _payoutEmailCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(creatorProfileProvider).valueOrNull;
    _displayNameCtrl =
        TextEditingController(text: profile?['display_name'] as String? ?? '');
    _bioCtrl =
        TextEditingController(text: profile?['bio'] as String? ?? '');
    _payoutEmailCtrl =
        TextEditingController(text: profile?['payout_email'] as String? ?? '');
    _bioCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _payoutEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final displayName = _displayNameCtrl.text.trim();
    final bio = _bioCtrl.text;
    final payoutEmail = _payoutEmailCtrl.text.trim();

    if (displayName.length < 2 || displayName.length > 50) {
      _showError('Display name must be 2–50 characters.');
      return;
    }
    if (bio.length > 300) {
      _showError('Bio must be 300 characters or fewer.');
      return;
    }

    setState(() => _loading = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      final res = await Supabase.instance.client.functions.invoke(
        'update-creator-profile',
        body: {
          'display_name': displayName,
          'bio': bio,
          if (payoutEmail.isNotEmpty) 'payout_email': payoutEmail,
        },
      );

      if (res.status != 200) {
        final err =
            (res.data as Map?)?['error'] as String? ?? 'Unknown error';
        throw Exception(err);
      }

      // Invalidate providers so cached data refreshes
      final userId = session.user.id;
      ref.invalidate(creatorProfileProvider);
      ref.invalidate(publicCreatorProfileProvider(userId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated',
            style: GoogleFonts.sora(color: textCol),
          ),
          backgroundColor: surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.sora(color: textCol),
        ),
        backgroundColor: lava,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioLength = _bioCtrl.text.length;

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Edit Creator Profile',
          style: GoogleFonts.nunito(
            color: textCol,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // Display Name
          Text(
            'Display Name',
            style: GoogleFonts.sora(color: textSec, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Field(
            controller: _displayNameCtrl,
            hint: 'Your creator name',
            maxLength: 50,
          ),
          const SizedBox(height: 20),

          // Bio
          Text(
            'Bio',
            style: GoogleFonts.sora(color: textSec, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLength: 300,
            maxLines: 4,
            style: GoogleFonts.sora(color: textCol, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Tell your audience about yourself…',
              hintStyle: GoogleFonts.sora(color: textDim, fontSize: 15),
              counterText: '',
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
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$bioLength / 300',
              style: GoogleFonts.sora(
                color: bioLength > 280 ? lava : textDim,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Payout Email
          Text(
            'Payout Email',
            style: GoogleFonts.sora(color: textSec, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Field(
            controller: _payoutEmailCtrl,
            hint: 'email@example.com',
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          Text(
            'Used for Stripe payouts. Must match your Stripe account email.',
            style: GoogleFonts.sora(color: textDim, fontSize: 11),
          ),
          const SizedBox(height: 32),

          // Save button
          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _loading ? null : goldGrad,
                color: _loading ? card : null,
                borderRadius: BorderRadius.circular(26),
              ),
              alignment: Alignment.center,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
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
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: GoogleFonts.sora(color: textCol, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(color: textDim, fontSize: 15),
        counterText: '',
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
}

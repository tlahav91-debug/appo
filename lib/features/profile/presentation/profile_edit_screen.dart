import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../application/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _avatarCtrl;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _avatarCtrl = TextEditingController(text: profile?.avatarUrl ?? '');
    _avatarCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Username cannot be empty.');
      return;
    }
    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters.');
      return;
    }
    if (username.length > 24) {
      setState(() => _error = 'Username must be 24 characters or fewer.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final userId = ref.read(profileProvider).valueOrNull?.id;
      if (userId == null) throw Exception('Not authenticated');

      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            username: username,
            avatarUrl: _avatarCtrl.text.trim().isEmpty
                ? null
                : _avatarCtrl.text.trim(),
          );

      ref.invalidate(profileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 24),

          // Username field
          Text(
            'Username',
            style: GoogleFonts.sora(color: textSec, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Field(
            controller: _usernameCtrl,
            hint: 'Your display name',
            maxLength: 24,
          ),
          const SizedBox(height: 20),

          // Avatar URL field
          Text(
            'Avatar URL',
            style: GoogleFonts.sora(color: textSec, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Field(
            controller: _avatarCtrl,
            hint: 'https://example.com/avatar.jpg',
            maxLength: 500,
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a public image URL to set your avatar.',
            style: GoogleFonts.sora(color: textDim, fontSize: 11),
          ),
          const SizedBox(height: 28),

          // Preview
          if (_avatarCtrl.text.trim().isNotEmpty) ...[
            Text(
              'Preview',
              style: GoogleFonts.sora(color: textSec, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardHi,
                  border: Border.all(color: borderHi, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    _avatarCtrl.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: textDim,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Error message
          if (_error != null) ...[
            Text(
              _error!,
              style: GoogleFonts.sora(color: lava, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Save button
          GestureDetector(
            onTap: _saving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _saved ? null : pinkFull,
                color: _saved ? card : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _saved ? '✓ Saved!' : 'Save Changes',
                        style: GoogleFonts.nunito(
                          color: _saved ? textDim : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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

  const _Field({
    required this.controller,
    required this.hint,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
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
          borderSide: const BorderSide(color: pink, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

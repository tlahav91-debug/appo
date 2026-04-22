import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/stars.dart';
import '../../../shared/widgets/g_btn.dart';
import '../application/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await repo.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await repo.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          const Stars(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'DramaPlay',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: pink,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your story. Your choice.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          color: textSec,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            _ToggleTab(
                              label: 'Sign Up',
                              active: _isSignUp,
                              onTap: () => setState(() => _isSignUp = true),
                            ),
                            _ToggleTab(
                              label: 'Sign In',
                              active: !_isSignUp,
                              onTap: () => setState(() => _isSignUp = false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email field
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.sora(color: textCol),
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, color: textSec),
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 12),
                      // Password field
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        style: GoogleFonts.sora(color: textCol),
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: textSec),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      // Primary CTA
                      GBtn(
                        gradient: pinkGrad,
                        width: double.infinity,
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: textCol,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'Start Watching' : 'Sign In',
                                style: GoogleFonts.nunito(
                                  color: textCol,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.sora(color: textDim),
                          ),
                        ),
                        const Expanded(child: Divider(color: border)),
                      ]),
                      const SizedBox(height: 16),
                      // Apple Sign-In
                      GestureDetector(
                        onTap: _loading ? null : _appleSignIn,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: textCol,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apple, color: bgDeep, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Apple',
                                style: GoogleFonts.nunito(
                                  color: bgDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
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

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            gradient: active ? pinkFull : null,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: active ? textCol : textDim,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

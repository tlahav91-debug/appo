import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../application/creator_provider.dart';

class CreatorStatusScreen extends ConsumerWidget {
  const CreatorStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(creatorProfileProvider);

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: AppBar(
        backgroundColor: bgDeep,
        elevation: 0,
        leading: BackButton(color: textCol),
        title: Text(
          'Creator Application',
          style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: purple)),
        error: (e, _) => Center(
          child: Text('Error loading status', style: GoogleFonts.sora(color: textDim)),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No application found.', style: GoogleFonts.sora(color: textDim)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/creator/apply'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: purpleGrad,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(
                        'Apply Now',
                        style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final status = profile['status'] as String;
          final rejectionReason = profile['rejection_reason'] as String?;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusCard(status: status, rejectionReason: rejectionReason),
                if (status == 'approved') ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/creator/earnings'),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: goldGrad,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Go to Creator Studio',
                        style: GoogleFonts.nunito(
                          color: textCol, fontWeight: FontWeight.w800, fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/creator/analytics'),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: purpleGrad,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Analytics',
                        style: GoogleFonts.nunito(
                          color: textCol, fontWeight: FontWeight.w800, fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/creator/edit-profile'),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: cyanGrad,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.nunito(
                          color: textCol, fontWeight: FontWeight.w800, fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final String? rejectionReason;

  const _StatusCard({required this.status, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final (icon, label, grad, message) = switch (status) {
      'approved' => (
          '✅',
          'Approved',
          greenGrad,
          'Congratulations! Your creator account is active.',
        ),
      'rejected' => (
          '❌',
          'Not Approved',
          pinkGrad,
          rejectionReason ?? 'Your application was not approved.',
        ),
      _ => (
          '⏳',
          'Under Review',
          purpleGrad,
          'We\'re reviewing your application. This usually takes 24–48 hours.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(color: textCol, fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.sora(color: textCol, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

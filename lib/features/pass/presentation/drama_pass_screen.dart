import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hud.dart';
import '../../profile/application/profile_provider.dart';
import '../../shop/domain/gem_pack.dart';
import '../application/drama_pass_provider.dart';

const _kBenefits = [
  ('⚡', '+5 energy bonus every day'),
  ('🎬', 'Unlock episodes with fewer resets'),
  ('🎭', 'Exclusive Drama Pass badge in HUD'),
  ('💎', 'Priority access to new series'),
  ('🏆', 'Double XP on all episodes'),
];

class DramaPassScreen extends ConsumerWidget {
  const DramaPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final priceAsync = ref.watch(passLocalizedPriceProvider);
    final purchaseAsync = ref.watch(passSubscribeNotifierProvider);
    final isActive = profileAsync.valueOrNull?.dramaPassActive ?? false;
    final isLoading = purchaseAsync.isLoading;

    ref.listen(passSubscribeNotifierProvider, (_, next) {
      if (!next.hasValue || next.value == null) return;
      final result = next.value!;
      if (result.status == PurchaseStatus.success) {
        ref.invalidate(profileProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Drama Pass activated! 🎭',
                style: GoogleFonts.sora(color: textCol)),
            backgroundColor: purple,
          ));
        }
      } else if (result.status == PurchaseStatus.error && result.error != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.error!, style: GoogleFonts.sora(color: textCol)),
            backgroundColor: surface,
          ));
        }
      }
    });

    return Scaffold(
      backgroundColor: bgDeep,
      appBar: const HUD(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: purpleGrad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: purple.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Column(
                children: [
                  const Text('🎭', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(
                    'Drama Pass',
                    style: GoogleFonts.nunito(
                      color: textCol,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: green),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.nunito(
                          color: green,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Text(
                      priceAsync.valueOrNull != null
                          ? '${priceAsync.value} / month'
                          : 'Loading…',
                      style: GoogleFonts.sora(color: textSec, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'What you get',
                  style: GoogleFonts.nunito(
                    color: textCol,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (icon, text) in _kBenefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(
                          text,
                          style: GoogleFonts.sora(color: textSec, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (!isActive) ...[
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => ref.read(passSubscribeNotifierProvider.notifier).subscribe(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: pinkFull,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: textCol),
                              )
                            : Text(
                                priceAsync.valueOrNull != null
                                    ? 'Subscribe · ${priceAsync.value}/mo'
                                    : 'Subscribe',
                                style: GoogleFonts.nunito(
                                  color: textCol,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(passSubscribeNotifierProvider.notifier)
                              .restore(),
                      child: Text(
                        'Restore Purchase',
                        style: GoogleFonts.sora(color: textDim, fontSize: 13),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Cancel anytime. Billed monthly via App Store.',
                    style: GoogleFonts.sora(color: textDim, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

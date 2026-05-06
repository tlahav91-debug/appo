import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../features/energy/application/energy_provider.dart';
import '../../features/profile/application/profile_provider.dart';

class EnergyTimer extends ConsumerStatefulWidget {
  const EnergyTimer({super.key});

  @override
  ConsumerState<EnergyTimer> createState() => _EnergyTimerState();
}

class _EnergyTimerState extends ConsumerState<EnergyTimer> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final energy = ref.read(energyStateProvider);
    final next = energy.nextRefillIn;
    if (next == null) {
      if (mounted) setState(() => _remaining = null);
      return;
    }
    if (next == Duration.zero) {
      // Trigger a profile refresh so energy increments
      ref.invalidate(profileProvider);
    }
    if (mounted) setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = ref.watch(energyStateProvider);
    if (energy.isFull || _remaining == null) {
      return Text(
        'Energy full',
        style: GoogleFonts.sora(color: green, fontSize: 12),
      );
    }

    final unitsNeeded = EnergyState.max - energy.current;

    if (unitsNeeded >= 2) {
      // Total time = time to next tick + (remaining units - 1) full hour intervals
      final totalSeconds = _remaining!.inSeconds + (unitsNeeded - 1) * 3600;
      final hours = totalSeconds ~/ 3600;
      final mins = (totalSeconds % 3600) ~/ 60;
      final label = hours > 0 ? 'Full in ${hours}h ${mins}m' : 'Full in ${mins}m';
      return Text(
        label,
        style: GoogleFonts.sora(color: textSec, fontSize: 12),
      );
    }

    final mins = _remaining!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = _remaining!.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      '+1 energy in $mins:$secs',
      style: GoogleFonts.sora(color: textSec, fontSize: 12),
    );
  }
}

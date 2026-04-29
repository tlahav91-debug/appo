import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _ctrl.setVolume(0);
        _ctrl.play();
        _ctrl.addListener(_onVideoUpdate);
      }).catchError((_) {
        if (mounted) _navigate();
      });

    // Fallback in case video never finishes
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _navigate();
    });
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final pos = _ctrl.value.position;
    final dur = _ctrl.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur) _navigate();
  }

  void _navigate() {
    _ctrl.removeListener(_onVideoUpdate);
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onVideoUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: _ctrl.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _ctrl.value.size.width,
                  height: _ctrl.value.size.height,
                  child: VideoPlayer(_ctrl),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

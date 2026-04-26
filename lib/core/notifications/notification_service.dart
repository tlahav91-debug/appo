import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/tokens.dart';

class NotificationService {
  static const _promptShownKey = 'notifications_prompt_shown';
  static const _episodeCountKey = 'notification_episode_count';

  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Do NOT call requestPermission here — use soft-ask flow instead
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<void> registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _upsertToken(token);
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(_upsertToken);
  }

  Future<void> _upsertToken(String token) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'register-push-token',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {}
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Called each time an episode is viewed. Shows soft-ask on 3rd view.
  Future<void> onEpisodeViewed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_promptShownKey) ?? false;
    if (alreadyShown) return;

    // Check if already authorized (e.g. granted via system settings)
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await prefs.setBool(_promptShownKey, true);
        await registerCurrentToken();
        return;
      }
    }

    final count = (prefs.getInt(_episodeCountKey) ?? 0) + 1;
    await prefs.setInt(_episodeCountKey, count);

    if (count >= 3 && context.mounted) {
      await _showSoftAsk(context, prefs);
    }
  }

  Future<void> _showSoftAsk(BuildContext context, SharedPreferences prefs) async {
    await prefs.setBool(_promptShownKey, true);

    if (!context.mounted) return;

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificationSoftAsk(),
    );

    if (agreed == true) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await registerCurrentToken();
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}

class _NotificationSoftAsk extends StatelessWidget {
  const _NotificationSoftAsk();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderHi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🔔', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            'Never miss an episode',
            style: GoogleFonts.nunito(
              color: textCol,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified when new episodes drop and when your streak is about to expire.',
            style: GoogleFonts.sora(color: textSec, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: pinkFull,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Notify me',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Not now',
              style: GoogleFonts.sora(color: textDim, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

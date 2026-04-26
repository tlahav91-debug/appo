import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails('drama_play', 'DramaPlay'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}

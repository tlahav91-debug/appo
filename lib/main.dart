import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/deep_link/deep_link_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/application/onboarding_provider.dart';

// Must be a top-level function; called by FCM when the app is terminated
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage _) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  assert(supabaseUrl.isNotEmpty, 'SUPABASE_URL must be set via --dart-define');
  assert(supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY must be set via --dart-define');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await incrementLaunchCount();
  await MobileAds.instance.initialize();

  const posthogKey = String.fromEnvironment('POSTHOG_API_KEY');
  if (posthogKey.isNotEmpty) {
    const posthogHost = String.fromEnvironment(
      'POSTHOG_HOST',
      defaultValue: 'https://app.posthog.com',
    );
    final config = PostHogConfig(posthogKey);
    config.host = posthogHost;
    await PostHog().setup(config);
  }

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  runApp(const ProviderScope(child: DramaPlayApp()));
}

class DramaPlayApp extends ConsumerStatefulWidget {
  const DramaPlayApp({super.key});

  @override
  ConsumerState<DramaPlayApp> createState() => _DramaPlayAppState();
}

class _DramaPlayAppState extends ConsumerState<DramaPlayApp> {
  final _deepLinkService = DeepLinkService();
  bool _deepLinkInitialized = false;

  @override
  void initState() {
    super.initState();
    _wireNotificationNavigation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_deepLinkInitialized) {
      _deepLinkInitialized = true;
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.init(ref.read(routerProvider));
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  void _wireNotificationNavigation() {
    // Terminated state: app opened by tapping a notification
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _navigateFromMessage(msg);
    });
    // Background state: app brought to foreground by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
  }

  void _navigateFromMessage(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || !mounted) return;
    // Only navigate if user is authenticated; router redirect handles the rest
    if (Supabase.instance.client.auth.currentSession == null) return;
    ref.read(routerProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'DramaPlay',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

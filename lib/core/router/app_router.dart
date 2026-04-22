import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/collectibles/presentation/album_screen.dart';
import '../../features/episodes/domain/episode.dart';
import '../../features/episodes/presentation/series_screen.dart';
import '../../features/episodes/presentation/episode_detail_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final onAuth = state.matchedLocation == '/auth';
      final onSplash = state.matchedLocation == '/';

      if (onSplash) return isAuth ? '/home' : '/auth';
      if (!isAuth && !onAuth) return '/auth';
      if (isAuth && onAuth) return '/home';
      return null;
    },
    refreshListenable: _AuthStateNotifier(),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/home', builder: (_, __) => const AppShell()),
      GoRoute(
        path: '/series/:seriesId',
        builder: (_, state) => SeriesScreen(
          seriesId: state.pathParameters['seriesId']!,
        ),
      ),
      GoRoute(
        path: '/series/:seriesId/episode/:episodeId',
        builder: (_, state) => EpisodeDetailScreen(
          episode: state.extra as Episode,
        ),
      ),
      GoRoute(
        path: '/album/:seriesId',
        builder: (_, state) => AlbumScreen(
          seriesId: state.pathParameters['seriesId']!,
        ),
      ),
    ],
  );
});

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

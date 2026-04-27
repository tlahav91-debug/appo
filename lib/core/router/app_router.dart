import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/affinity/presentation/affinity_screen.dart';
import '../../features/club/presentation/club_screen.dart';
import '../../features/club/presentation/club_search_screen.dart';
import '../../features/collectibles/presentation/album_screen.dart';
import '../../features/events/presentation/lava_quest_screen.dart';
import '../../features/profile/presentation/events_screen.dart';
import '../../features/profile/presentation/journey_screen.dart';
import '../../features/profile/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/referral/presentation/referral_screen.dart';
import '../../features/pass/presentation/drama_pass_screen.dart';
import '../../features/race/presentation/race_screen.dart';
import '../../features/shop/presentation/gem_store_screen.dart';
import '../../features/episodes/domain/episode.dart';
import '../../features/episodes/presentation/series_screen.dart';
import '../../features/episodes/presentation/episode_detail_screen.dart';
import '../../features/social/presentation/social_feed_screen.dart';
import '../../features/creator/presentation/creator_apply_screen.dart';
import '../../features/creator/presentation/creator_earnings_screen.dart';
import '../../features/creator/presentation/creator_status_screen.dart';
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
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
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
      GoRoute(
        path: '/shop/gems',
        builder: (_, __) => const GemStoreScreen(),
      ),
      GoRoute(
        path: '/pass',
        builder: (_, __) => const DramaPassScreen(),
      ),
      GoRoute(
        path: '/race/:raceId',
        builder: (_, state) => RaceScreen(
          raceId: state.pathParameters['raceId']!,
        ),
      ),
      GoRoute(
        path: '/quest/:questId',
        builder: (_, state) => LavaQuestScreen(
          questId: state.pathParameters['questId']!,
        ),
      ),
      GoRoute(
        path: '/affinity/:seriesId',
        builder: (_, state) => AffinityScreen(
          seriesId: state.pathParameters['seriesId']!,
        ),
      ),
      GoRoute(
        path: '/club/search',
        builder: (_, __) => const ClubSearchScreen(),
      ),
      GoRoute(
        path: '/club/:clubId',
        builder: (_, state) => ClubScreen(
          clubId: state.pathParameters['clubId']!,
        ),
      ),
      GoRoute(
        path: '/events',
        builder: (_, __) => const EventsScreen(),
      ),
      GoRoute(
        path: '/journey',
        builder: (_, __) => const JourneyScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(path: '/social', builder: (_, __) => const SocialFeedScreen()),
      GoRoute(path: '/creator/apply', builder: (_, __) => const CreatorApplyScreen()),
      GoRoute(path: '/creator/status', builder: (_, __) => const CreatorStatusScreen()),
      GoRoute(path: '/creator/earnings', builder: (_, __) => const CreatorEarningsScreen()),
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

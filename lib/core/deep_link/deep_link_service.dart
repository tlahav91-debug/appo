import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Uri? _pendingUri;

  Future<void> init(GoRouter router) async {
    // Flush pending URI once auth resolves
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && _pendingUri != null) {
        _navigate(router, _pendingUri!);
        _pendingUri = null;
      }
    });

    // Cold-start: capture the URI that launched the app
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(router, initial);
    }

    // Foreground: live stream
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(router, uri);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleUri(GoRouter router, Uri uri) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _pendingUri = uri;
      return;
    }
    _navigate(router, uri);
  }

  void _navigate(GoRouter router, Uri uri) {
    final path = uri.path;

    // Drop mid-episode deep links — episode screen requires state.extra
    final episodePattern = RegExp(r'^/series/[^/]+/episode/[^/]+$');
    if (episodePattern.hasMatch(path)) {
      // Gracefully fall back to series screen
      final seriesId = uri.pathSegments[1];
      router.go('/series/$seriesId');
      return;
    }

    // Recognised routable paths
    final routable = RegExp(
      r'^/(series/[^/]+(/album)?|creator/[^/]+|race/[^/]+|quest/[^/]+)$',
    );
    if (routable.hasMatch(path)) {
      router.go(path);
    }
    // Unknown paths: silently ignored
  }
}

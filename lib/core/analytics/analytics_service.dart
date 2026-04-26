import 'dart:async';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  void identify(String userId, Map<String, dynamic> properties) {
    unawaited(
      PostHog()
          .identify(userId: userId, userProperties: properties)
          .catchError((_) {}),
    );
  }

  void capture(String event, {Map<String, dynamic>? properties}) {
    unawaited(
      PostHog()
          .capture(eventName: event, properties: properties)
          .catchError((_) {}),
    );
  }

  void reset() {
    unawaited(PostHog().reset().catchError((_) {}));
  }
}

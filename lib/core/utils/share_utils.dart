import 'package:share_plus/share_plus.dart';

const String _appBaseUrl = 'https://appo.app';

Future<void> shareSeries(String seriesId, String seriesTitle) async {
  await Share.share(
    'Watch "$seriesTitle" on Appo! $_appBaseUrl/series/$seriesId',
    subject: seriesTitle,
  );
}

Future<void> shareCreator(String creatorId, String displayName) async {
  await Share.share(
    'Check out $displayName on Appo! $_appBaseUrl/creator/$creatorId',
    subject: displayName,
  );
}

Future<void> shareEpisode(
    String seriesId, String episodeId, String title) async {
  await Share.share(
    'Watch "$title" on Appo! $_appBaseUrl/series/$seriesId/episode/$episodeId',
    subject: title,
  );
}

Future<void> shareClub(String clubId, String clubName) async {
  await Share.share(
    'Join me in "$clubName" on Appo! $_appBaseUrl/clubs/$clubId/join',
    subject: 'Join $clubName on Appo',
  );
}

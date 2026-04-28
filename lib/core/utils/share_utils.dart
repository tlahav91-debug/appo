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

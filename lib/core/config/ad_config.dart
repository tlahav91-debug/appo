// Ad unit IDs — set via --dart-define=ADMOB_REWARDED_UNIT_ID=ca-app-pub-xxx/xxx
// Falls back to Google's official test IDs when not set.
const String kRewardedAdUnitId = String.fromEnvironment(
  'ADMOB_REWARDED_UNIT_ID',
  defaultValue: 'ca-app-pub-3940256099942544/1712485313', // iOS test ID
);

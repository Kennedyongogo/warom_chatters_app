/// WAROM API base URL.
///
/// Override at build/run time:
/// `flutter run --dart-define=WAROM_API_BASE=http://192.168.1.10:4000`
///
/// Default points at the hosted WAROM API.
const String kWaromApiBase = String.fromEnvironment(
  'WAROM_API_BASE',
  defaultValue: 'http://84.247.176.143:3033',
);

const String kChatterAccountType = 'chatter';

/// Google / Apple sign-in. Keep off until official WAROM email + OAuth are configured.
const bool kSocialAuthEnabled = false;

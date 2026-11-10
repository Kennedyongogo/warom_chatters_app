/// Registration progress, in the order the server allows it to advance.
enum OnboardingStep {
  email,
  terms,
  birthDate,
  basics,
  photos,
  about,
  preferences,
  location,
  activate,
  done;

  bool isBefore(OnboardingStep other) => index < other.index;
}

enum AccountStatus { onboarding, active, ineligible }

enum AuthProvider {
  phone('phone number'),
  google('Google'),
  apple('Apple');

  const AuthProvider(this.label);
  final String label;
}

class Account {
  final String id;
  final AuthProvider provider;
  final DateTime createdAt;
  String? phone;
  bool phoneVerified;
  String? email;
  bool emailVerified;
  String? termsVersion;
  DateTime? termsAcceptedAt;
  bool marketingOptIn;
  bool locationFromDevice;
  OnboardingStep step;
  AccountStatus status;

  Account({
    required this.id,
    required this.provider,
    required this.createdAt,
    this.phone,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    this.termsVersion,
    this.termsAcceptedAt,
    this.marketingOptIn = false,
    this.locationFromDevice = false,
    this.step = OnboardingStep.email,
    this.status = AccountStatus.onboarding,
  });
}

class OtpTicket {
  final String phone;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  const OtpTicket(this.phone, this.expiresAt, this.resendAvailableAt);
}

class AuthOutcome {
  final Account account;
  final bool isNewAccount;

  const AuthOutcome(this.account, this.isNewAccount);
}

class Country {
  final String name;
  final String dialCode;
  final String flag;

  const Country(this.name, this.dialCode, this.flag);

  static const supported = [
    Country('Kenya', '+254', '🇰🇪'),
    Country('Tanzania', '+255', '🇹🇿'),
    Country('Uganda', '+256', '🇺🇬'),
    Country('Rwanda', '+250', '🇷🇼'),
  ];
}

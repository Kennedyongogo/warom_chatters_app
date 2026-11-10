import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/account.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../landing/landing_page.dart';
import 'onboarding_flow.dart';

class EmailStepPage extends StatefulWidget {
  const EmailStepPage({super.key});

  @override
  State<EmailStepPage> createState() => _EmailStepPageState();
}

class _EmailStepPageState extends State<EmailStepPage> {
  final _api = MtaaniApi.instance;
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final ok = await guarded(context, () => _api.requestEmailCode(_email.text));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _sentTo = _email.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sentTo != null;
    return OnboardingScaffold(
      step: OnboardingStep.email,
      title: sent ? 'Check your inbox' : 'Add your email',
      subtitle: sent
          ? 'Enter the 6-digit code we sent to $_sentTo.'
          : 'Optional, but it helps you recover your account if you change your number.',
      busy: _busy,
      primaryLabel: sent ? 'Verify email' : 'Send code',
      onPrimary: sent
          ? () => submitStep(context, () => _api.verifyEmailCode(_code.text), OnboardingStep.terms,
              setBusy: (b) => setState(() => _busy = b))
          : _send,
      secondary: TextButton(
        onPressed: _busy
            ? null
            : () => submitStep(context, _api.skipEmail, OnboardingStep.terms, setBusy: (b) => setState(() => _busy = b)),
        child: const Text('Skip for now', style: TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w700)),
      ),
      children: [
        if (!sent)
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
          )
        else ...[
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 26, letterSpacing: 14, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: _busy ? null : _send, child: const Text('Resend code')),
              TextButton(
                onPressed: () => setState(() {
                  _sentTo = null;
                  _code.clear();
                }),
                child: const Text('Use a different email'),
              ),
            ],
          ),
          const DemoHint('Demo: no email is sent. The code is ${MtaaniApi.demoCode}.'),
        ],
      ],
    );
  }
}

class TermsStepPage extends StatefulWidget {
  const TermsStepPage({super.key});

  @override
  State<TermsStepPage> createState() => _TermsStepPageState();
}

class _TermsStepPageState extends State<TermsStepPage> {
  bool _agreed = false;
  bool _marketing = false;
  bool _busy = false;

  static const _documents = [
    (
      Icons.description_outlined,
      'Terms of Use',
      [
        'You must be 18 or older to use Mtaani.',
        'One account per person, with your real name, age and recent photos.',
        'We may suspend accounts that break these terms or our community rules.',
      ],
    ),
    (
      Icons.privacy_tip_outlined,
      'Privacy Policy',
      [
        'Your phone number and email are never shown to other members.',
        'Others only see an approximate distance, never your exact location.',
        'You can download or delete your data at any time.',
      ],
    ),
    (
      Icons.diversity_1_outlined,
      'Community Guidelines',
      [
        'Be respectful. No harassment, hate speech or explicit content.',
        'No scams, selling or asking for money.',
        'Report anyone who makes you feel unsafe.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: OnboardingStep.terms,
      title: 'Our promise to each other',
      subtitle: 'Please read and accept these to continue. We record the version you accept and when.',
      busy: _busy,
      primaryLabel: 'Agree and continue',
      onPrimary: _agreed
          ? () => submitStep(
                context,
                () => MtaaniApi.instance.acceptTerms(marketingOptIn: _marketing),
                OnboardingStep.birthDate,
                setBusy: (b) => setState(() => _busy = b),
              )
          : null,
      children: [
        for (final doc in _documents)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MtaaniColors.line),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(doc.$1, color: MtaaniColors.coralDeep),
                title: Text(doc.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in doc.$3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('•  $line', style: const TextStyle(height: 1.4)),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: MtaaniColors.coralDeep,
          title: const Text('I agree to the Terms of Use, Privacy Policy and Community Guidelines',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
          subtitle: const Text('Version ${MtaaniApi.termsVersion} · required'),
        ),
        SwitchListTile(
          value: _marketing,
          onChanged: (v) => setState(() => _marketing = v),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: MtaaniColors.coralDeep,
          title: const Text('Send me dating tips and offers', style: TextStyle(fontSize: 14.5)),
          subtitle: const Text('Optional. You can change this later.'),
        ),
      ],
    );
  }
}

class BirthDateStepPage extends StatefulWidget {
  const BirthDateStepPage({super.key});

  @override
  State<BirthDateStepPage> createState() => _BirthDateStepPageState();
}

class _BirthDateStepPageState extends State<BirthDateStepPage> {
  DateTime? _date;
  bool _busy = false;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Your date of birth',
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: OnboardingStep.birthDate,
      title: 'When\'s your birthday?',
      subtitle: 'Mtaani is for adults 18 and over. Your age appears on your profile; your birth date doesn\'t.',
      busy: _busy,
      primaryLabel: 'Continue',
      onPrimary: _date == null
          ? null
          : () => submitStep(
                context,
                () => MtaaniApi.instance.submitBirthDate(_date!),
                OnboardingStep.basics,
                setBusy: (b) => setState(() => _busy = b),
              ),
      children: [
        InkWell(
          onTap: _pick,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date of birth', suffixIcon: Icon(Icons.cake_outlined)),
            child: Text(
              _date == null ? 'Select your date of birth' : DateFormat('d MMMM yyyy').format(_date!),
              style: TextStyle(fontSize: 16, color: _date == null ? MtaaniColors.muted : MtaaniColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, size: 16, color: MtaaniColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'We check your age on our servers. You can\'t change your date of birth later, so make sure it\'s right.',
                style: TextStyle(fontSize: 13, color: MtaaniColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class IneligiblePage extends StatelessWidget {
  const IneligiblePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: MtaaniColors.blush, shape: BoxShape.circle),
                child: const Icon(Icons.eighteen_up_rating_outlined, size: 46, color: MtaaniColors.coralDeep),
              ),
              const SizedBox(height: 24),
              const Text('Mtaani is for adults only',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
              const SizedBox(height: 10),
              const Text(
                'You need to be 18 or older to create an account. We haven\'t created a profile for you, '
                'and this number can\'t be used to sign up until you\'re eligible.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: MtaaniColors.muted, height: 1.5),
              ),
              const Spacer(),
              PillButton.primary(
                onTap: () {
                  MtaaniApi.instance.logOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                    (_) => false,
                  );
                },
                child: const Text('Back to start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

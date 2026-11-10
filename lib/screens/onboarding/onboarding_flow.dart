import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';
import 'account_steps.dart';
import 'activation_page.dart';
import 'profile_steps.dart';

Widget pageForStep(OnboardingStep step) => switch (step) {
      OnboardingStep.email => const EmailStepPage(),
      OnboardingStep.terms => const TermsStepPage(),
      OnboardingStep.birthDate => const BirthDateStepPage(),
      OnboardingStep.basics => const BasicsStepPage(),
      OnboardingStep.photos => const PhotosStepPage(),
      OnboardingStep.about => const AboutStepPage(),
      OnboardingStep.preferences => const PreferencesStepPage(),
      OnboardingStep.location => const LocationStepPage(),
      OnboardingStep.activate => const ActivationPage(),
      OnboardingStep.done => const HomeShell(),
    };

/// After signing in: drops the sign-in screens and resumes wherever the server says the account is.
void enterApp(BuildContext context) {
  final account = MtaaniApi.instance.account!;
  if (account.status == AccountStatus.ineligible) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const IneligiblePage()), (_) => false);
    return;
  }
  final finished = account.step == OnboardingStep.done;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => pageForStep(account.step)),
    (route) => !finished && route.isFirst,
  );
}

void goToStep(BuildContext context, OnboardingStep step) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => pageForStep(step)));
}

/// Runs a step's save call and moves on. Routes under-18 rejections to the ineligible screen.
Future<void> submitStep(
  BuildContext context,
  Future<void> Function() save,
  OnboardingStep next, {
  required ValueChanged<bool> setBusy,
}) async {
  setBusy(true);
  try {
    await save();
    if (context.mounted) goToStep(context, next);
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (e.code == ApiException.ineligible) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const IneligiblePage()), (_) => false);
    } else {
      showApiError(context, e);
    }
  } finally {
    if (context.mounted) setBusy(false);
  }
}

class OnboardingScaffold extends StatelessWidget {
  final OnboardingStep step;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final Widget? secondary;

  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.busy = false,
    this.secondary,
  });

  String get _phase => switch (step) {
        OnboardingStep.email || OnboardingStep.terms => 'Account',
        OnboardingStep.birthDate => 'Eligibility',
        OnboardingStep.activate || OnboardingStep.done => 'Activate',
        _ => 'Your profile',
      };

  @override
  Widget build(BuildContext context) {
    final progress = (step.index + 1) / (OnboardingStep.activate.index + 1);
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase.toUpperCase(),
            style: const TextStyle(fontSize: 12.5, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: MtaaniColors.coralDeep)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: progress - 0.1, end: progress),
                duration: const Duration(milliseconds: 450),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: MtaaniColors.line,
                  color: MtaaniColors.coralDeep,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MtaaniColors.ink, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 15, color: MtaaniColors.muted, height: 1.4)),
                  const SizedBox(height: 26),
                  ...children,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: PillButton.primary(
                onTap: busy ? null : onPrimary,
                child: busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(primaryLabel),
              ),
            ),
            if (secondary != null) secondary! else const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class DemoHint extends StatelessWidget {
  final String text;

  const DemoHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: MtaaniColors.coralDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, color: MtaaniColors.ink, height: 1.35))),
        ],
      ),
    );
  }
}

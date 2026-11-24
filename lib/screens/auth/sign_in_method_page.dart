import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/account.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../legal/warom_legal.dart';
import '../legal/policy_page.dart';
import '../onboarding/onboarding_flow.dart';
import 'email_auth_page.dart';

enum AuthMode { create, logIn }

class SignInMethodPage extends StatefulWidget {
  final AuthMode mode;

  const SignInMethodPage({super.key, required this.mode});

  @override
  State<SignInMethodPage> createState() => _SignInMethodPageState();
}

class _SignInMethodPageState extends State<SignInMethodPage> {
  AuthProvider? _busy;

  bool get _creating => widget.mode == AuthMode.create;

  Future<void> _withProvider(AuthProvider provider) async {
    setState(() => _busy = provider);
    try {
      final email = 'chatter.${provider.name}@warom.app';
      final username = 'chatter_${provider.name}';
      final providerId = 'demo_${provider.name}_chatter';

      var session = await WaromAuth.instance.loginExistingProviderEmail(email);
      var isNew = false;

      if (session == null) {
        try {
          session = await WaromAuth.instance.registerWithProvider(
            provider: provider.name,
            providerId: providerId,
            email: email,
            username: username,
          );
          isNew = true;
        } on ApiException {
          await MtaaniApi.instance.continueWithProvider(provider);
          if (!mounted) return;
          enterApp(context);
          return;
        }
      }

      MtaaniApi.instance.adoptRemoteUser(
        user: session.user,
        provider: provider,
        isNew: isNew,
        skipOnboarding: !isNew,
      );
      if (!mounted) return;
      enterApp(context);
    } catch (e) {
      if (!mounted) return;
      final ok = await guarded(context, () async {
        await MtaaniApi.instance.continueWithProvider(provider);
      });
      if (ok && mounted) enterApp(context);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MtaaniColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: MtaaniColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: MtaaniColors.coral.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(child: HeartMark(size: 40)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _creating ? 'Create your account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: MtaaniColors.ink,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _creating
                  ? 'Choose how you want to join WAROM.'
                  : 'Sign in to continue where you left off.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                color: MtaaniColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            _AuthMethodButton(
              loading: false,
              onTap: _busy != null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmailAuthPage(mode: widget.mode)),
                      ),
              background: Colors.white,
              foreground: MtaaniColors.ink,
              borderColor: MtaaniColors.coral.withValues(alpha: 0.28),
              icon: const Icon(Icons.mail_outline_rounded, size: 22),
              label: 'Continue with Email',
            ),
            const SizedBox(height: 18),
            const _OrDivider(),
            const SizedBox(height: 18),
            _AuthMethodButton(
              loading: _busy == AuthProvider.google,
              onTap: (!kSocialAuthEnabled || _busy != null)
                  ? null
                  : () => _withProvider(AuthProvider.google),
              background: Colors.white,
              foreground: MtaaniColors.ink,
              borderColor: MtaaniColors.line,
              icon: const _ProviderIcon(provider: AuthProvider.google, size: 22),
              label: 'Continue with Google',
            ),
            const SizedBox(height: 12),
            _AuthMethodButton(
              loading: _busy == AuthProvider.apple,
              onTap: (!kSocialAuthEnabled || _busy != null)
                  ? null
                  : () => _withProvider(AuthProvider.apple),
              background: const Color(0xFF111111),
              foreground: Colors.white,
              borderColor: const Color(0xFF111111),
              icon: const Icon(Icons.apple, size: 24, color: Colors.white),
              label: 'Continue with Apple',
            ),
            const SizedBox(height: 36),
            TextButton(
              onPressed: _busy != null
                  ? null
                  : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignInMethodPage(
                            mode: _creating ? AuthMode.logIn : AuthMode.create,
                          ),
                        ),
                      );
                    },
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14.5, color: MtaaniColors.muted),
                  children: [
                    TextSpan(text: _creating ? 'Already have an account? ' : 'New here? '),
                    TextSpan(
                      text: _creating ? 'Log in' : 'Create an account',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: MtaaniColors.coralDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 12.5, color: MtaaniColors.muted, height: 1.4),
                children: [
                  const TextSpan(text: 'By continuing you agree to WAROM '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => PolicyPage.open(context, WaromLegal.terms.slug),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: MtaaniColors.coralDeep,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => PolicyPage.open(context, WaromLegal.privacy.slug),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: MtaaniColors.coralDeep,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: MtaaniColors.line, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: MtaaniColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: MtaaniColors.line, thickness: 1)),
      ],
    );
  }
}

class _AuthMethodButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final Widget icon;
  final String label;

  const _AuthMethodButton({
    required this.onTap,
    required this.loading,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !loading ? 0.55 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.1),
            ),
            child: loading
                ? Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(width: 24, child: Center(child: icon)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: foreground.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  final AuthProvider provider;
  final double size;

  const _ProviderIcon({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => const SweepGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(b),
      child: Text('G', style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1)),
    );
  }
}

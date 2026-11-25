import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../legal/warom_legal.dart';
import '../../models/account.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
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

class _SignInMethodPageState extends State<SignInMethodPage>
    with SingleTickerProviderStateMixin {
  AuthProvider? _busy;
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _heroScale;

  bool get _creating => widget.mode == AuthMode.create;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _intro, curve: const Interval(0.05, 0.85, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.1, 1, curve: Curves.easeOutCubic)),
    );
    _heroScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
    );
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

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
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: MtaaniColors.canvas,
        body: Stack(
          children: [
            // Immersive hero plane
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height * 0.46,
              child: ScaleTransition(
                scale: _heroScale,
                alignment: Alignment.center,
                child: const _HeroBackdrop(),
              ),
            ),
            // Content (under the back button so taps aren’t swallowed)
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: topInset + 44)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _HeroCopy(creating: _creating),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    SliverToBoxAdapter(
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 20),
                        child: _AuthPanel(
                          creating: _creating,
                          busy: _busy,
                          onEmail: _busy != null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EmailAuthPage(mode: widget.mode),
                                    ),
                                  ),
                          onGoogle: (!kSocialAuthEnabled || _busy != null)
                              ? null
                              : () => _withProvider(AuthProvider.google),
                          onApple: (!kSocialAuthEnabled || _busy != null)
                              ? null
                              : () => _withProvider(AuthProvider.apple),
                          onToggleMode: _busy != null
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          image: AssetImage('assets/images/landing_couple.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment(0, -0.25),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MtaaniColors.night.withValues(alpha: 0.35),
                MtaaniColors.night.withValues(alpha: 0.15),
                MtaaniColors.canvas.withValues(alpha: 0.15),
                MtaaniColors.canvas,
              ],
              stops: const [0, 0.35, 0.72, 1],
            ),
          ),
        ),
        Positioned(
          right: -30,
          top: 60,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: 0.25,
              child: Icon(
                Icons.favorite_rounded,
                size: 120,
                color: MtaaniColors.coral.withValues(alpha: 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool creating;

  const _HeroCopy({required this.creating});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          creating ? 'Turn conversations\ninto earnings' : 'Your chats.\nYour earnings.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          creating
              ? 'Meet people worldwide. Get gifted. Take calls. Cash out as a WAROM chatter.'
              : 'Pick up where you left off — messages, gifts, calls, and payouts.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        const _ValueRibbon(),
      ],
    );
  }
}

class _ValueRibbon extends StatelessWidget {
  const _ValueRibbon();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.forum_rounded, 'Chat'),
      (Icons.card_giftcard_rounded, 'Gifts'),
      (Icons.call_rounded, 'Calls'),
      (Icons.payments_rounded, 'Payouts'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1, size: 15, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthPanel extends StatelessWidget {
  final bool creating;
  final AuthProvider? busy;
  final VoidCallback? onEmail;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onToggleMode;

  const _AuthPanel({
    required this.creating,
    required this.busy,
    required this.onEmail,
    required this.onGoogle,
    required this.onApple,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      decoration: const BoxDecoration(
        color: MtaaniColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: MtaaniColors.line,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            creating ? 'Create your chatter account' : 'Welcome back',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: MtaaniColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            creating
                ? 'Join in under a minute. You can finish your profile next.'
                : 'Sign in to continue earning on WAROM.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: MtaaniColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _AuthMethodButton(
            loading: false,
            onTap: onEmail,
            background: MtaaniColors.coralDeep,
            foreground: Colors.white,
            borderColor: MtaaniColors.coralDeep,
            icon: const Icon(Icons.mail_outline_rounded, size: 22, color: Colors.white),
            label: creating ? 'Continue with Email' : 'Log in with Email',
            emphasize: true,
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          _AuthMethodButton(
            loading: busy == AuthProvider.google,
            onTap: onGoogle,
            background: Colors.white,
            foreground: MtaaniColors.ink,
            borderColor: MtaaniColors.line,
            icon: const _ProviderIcon(provider: AuthProvider.google, size: 22),
            label: 'Continue with Google',
          ),
          const SizedBox(height: 10),
          _AuthMethodButton(
            loading: busy == AuthProvider.apple,
            onTap: onApple,
            background: MtaaniColors.night,
            foreground: Colors.white,
            borderColor: MtaaniColors.night,
            icon: const Icon(Icons.apple, size: 24, color: Colors.white),
            label: 'Continue with Apple',
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onToggleMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14.5, color: MtaaniColors.muted),
                children: [
                  TextSpan(text: creating ? 'Already a chatter? ' : 'New to WAROM? '),
                  TextSpan(
                    text: creating ? 'Log in' : 'Create an account',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: MtaaniColors.coralDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: MtaaniColors.muted, height: 1.4),
              children: [
                const TextSpan(text: 'By continuing you agree to '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => PolicyPage.open(context, WaromLegal.terms.slug),
                    child: const Text(
                      'Terms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MtaaniColors.coralDeep,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' & '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => PolicyPage.open(context, WaromLegal.privacy.slug),
                    child: const Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 12,
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
          const SizedBox(height: 12),
        ],
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
            'or continue with',
            style: TextStyle(
              color: MtaaniColors.muted,
              fontSize: 12.5,
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
  final bool emphasize;

  const _AuthMethodButton({
    required this.onTap,
    required this.loading,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null && !loading ? 0.55 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        elevation: emphasize ? 3 : 0,
        shadowColor: MtaaniColors.coralDeep.withValues(alpha: 0.35),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: foreground.withValues(alpha: 0.55),
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
    // provider kept for hot-reload compatibility / future multi-provider icons
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
      child: Text(
        provider == AuthProvider.google ? 'G' : 'A',
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1),
      ),
    );
  }
}

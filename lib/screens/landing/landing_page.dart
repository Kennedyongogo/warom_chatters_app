import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth/sign_in_method_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  static const background = AssetImage('assets/images/landing_couple.jpg');

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _coral = MtaaniColors.coral;
  static const _coralDeep = MtaaniColors.coralDeep;
  static const _ink = MtaaniColors.ink;
  static const _night = MtaaniColors.night;

  void _openLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInMethodPage(mode: AuthMode.logIn)));
  }

  void _openRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInMethodPage(mode: AuthMode.create)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _night,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _night,
        body: Stack(
          children: [
            const Positioned.fill(
              child: Image(image: LandingPage.background, fit: BoxFit.cover, alignment: Alignment(0, -0.2)),
            ),
            // Cream haze at the top keeps the dark wordmark readable over the sky.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xE6F2E1D6), Color(0x00F2E1D6)],
                    stops: [0, 0.3],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00130E12), Color(0xB3130E12), Color(0xF2130E12), _night],
                    stops: [0.42, 0.6, 0.78, 1],
                  ),
                ),
              ),
            ),
            const Positioned(left: -46, bottom: -34, child: _CornerHeart(angle: -0.35)),
            const Positioned(right: -40, bottom: -28, child: _CornerHeart(angle: 0.3)),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  const _Brand(),
                  const Spacer(),
                  _EntranceFade(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.22,
                                letterSpacing: -0.4,
                              ),
                              children: [
                                TextSpan(text: 'Find someone special\nnear you in '),
                                TextSpan(text: 'Kenya', style: TextStyle(color: _coral)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Meet amazing people, make real connections,\nand see where it leads.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 15, height: 1.45),
                          ),
                          const SizedBox(height: 30),
                          PillButton.primary(
                            onTap: _openRegister,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Create Account'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          PillButton(
                            onTap: _openLogin,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.4),
                            child: const Text('Log In'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5),
                              ),
                              GestureDetector(
                                onTap: _openLogin,
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(color: _coral, fontSize: 13.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeartMark(size: 58),
            SizedBox(width: 10),
            Text(
              'Mtaani',
              style: TextStyle(
                color: _LandingPageState._ink,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Real People. Meaningful Connections.',
          style: TextStyle(color: Color(0xFF3B3540), fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _CornerHeart extends StatelessWidget {
  final double angle;

  const _CornerHeart({required this.angle});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle,
        child: Icon(Icons.favorite_rounded, size: 130, color: _LandingPageState._coralDeep.withValues(alpha: 0.28)),
      ),
    );
  }
}

class _EntranceFade extends StatelessWidget {
  final Widget child;

  const _EntranceFade({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

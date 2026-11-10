import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/profile.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../matches/chat_page.dart';

class MatchPage extends StatefulWidget {
  final Match match;
  final Profile other;

  const MatchPage({super.key, required this.match, required this.other});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = MtaaniApi.instance.me!;
    final pop = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _intro, curve: const Interval(0.3, 1, curve: Curves.easeOut));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF2FF7A59), Color(0xF2EF3F55), Color(0xF2B0123F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: fade,
                  child: const Text(
                    'It\'s a Match!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: fade,
                  child: Text(
                    'You and ${widget.other.firstName} like each other.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 16.5),
                  ),
                ),
                const SizedBox(height: 44),
                ScaleTransition(
                  scale: pop,
                  child: SizedBox(
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.translate(
                          offset: const Offset(-58, 0),
                          child: Transform.rotate(angle: -math.pi / 28, child: _MatchPhoto(profile: me)),
                        ),
                        Transform.translate(
                          offset: const Offset(58, 0),
                          child: Transform.rotate(angle: math.pi / 28, child: _MatchPhoto(profile: widget.other)),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14)],
                          ),
                          child: const Center(child: HeartMark(size: 32)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: fade,
                  child: Column(
                    children: [
                      PillButton(
                        color: Colors.white,
                        foreground: MtaaniColors.coralDeep,
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ChatPage(matchId: widget.match.id)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_rounded, size: 20),
                            SizedBox(width: 10),
                            Text('Send a message'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      PillButton(
                        border: Border.all(color: Colors.white, width: 1.4),
                        onTap: () => Navigator.pop(context),
                        child: const Text('Keep swiping'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchPhoto extends StatelessWidget {
  final Profile profile;

  const _MatchPhoto({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
        image: DecorationImage(image: photoProvider(profile.photos.first), fit: BoxFit.cover, alignment: Alignment.topCenter),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/profile.dart';
import '../../models/social.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class SwipeCard extends StatefulWidget {
  final Profile profile;
  final String distance;
  final Set<String> sharedInterests;
  final ValueChanged<SwipeAction> onSwiped;
  final VoidCallback onOpen;

  const SwipeCard({
    super.key,
    required this.profile,
    required this.distance,
    required this.sharedInterests,
    required this.onSwiped,
    required this.onOpen,
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  Offset _drag = Offset.zero;
  Animation<Offset>? _flight;
  bool _gone = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Offset get _offset => _flight?.value ?? _drag;

  /// Animates the card off screen, then reports the decision.
  void swipe(SwipeAction action) {
    if (_gone) return;
    _gone = true;
    HapticFeedback.lightImpact();
    final dir = action == SwipeAction.like ? 1.0 : -1.0;
    final width = MediaQuery.sizeOf(context).width;
    _flight = Tween(begin: _offset, end: Offset(dir * width * 1.6, _offset.dy + 60))
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.forward(from: 0).whenComplete(() => widget.onSwiped(action));
  }

  void _springBack() {
    _flight = Tween(begin: _drag, end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _drag = Offset.zero;
    _anim.forward(from: 0);
  }

  void _onPanStart(DragStartDetails _) {
    if (_gone) return;
    if (_flight != null) {
      _drag = _flight!.value;
      _anim.stop();
      _flight = null;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_gone) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_gone) return;
    final width = MediaQuery.sizeOf(context).width;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_drag.dx > width * 0.28 || vx > 900) {
      swipe(SwipeAction.like);
    } else if (_drag.dx < -width * 0.28 || vx < -900) {
      swipe(SwipeAction.pass);
    } else {
      _springBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onOpen,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final offset = _offset;
          final progress = (offset.dx / (width * 0.35)).clamp(-1.0, 1.0);
          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: offset.dx / width * 0.32,
              child: ProfileCardFace(
                profile: widget.profile,
                distance: widget.distance,
                sharedInterests: widget.sharedInterests,
                likeOpacity: progress > 0 ? progress : 0,
                nopeOpacity: progress < 0 ? -progress : 0,
                onOpen: widget.onOpen,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileCardFace extends StatelessWidget {
  final Profile profile;
  final String distance;
  final Set<String> sharedInterests;
  final double likeOpacity;
  final double nopeOpacity;
  final VoidCallback? onOpen;

  const ProfileCardFace({
    super.key,
    required this.profile,
    required this.distance,
    required this.sharedInterests,
    this.likeOpacity = 0,
    this.nopeOpacity = 0,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final interests = [
      ...profile.interests.where(sharedInterests.contains),
      ...profile.interests.where((i) => !sharedInterests.contains(i)),
    ].take(4);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: photoProvider(profile.photos.first), fit: BoxFit.cover, alignment: Alignment.topCenter),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x00000000), Color(0xCC130E12)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 30,
              child: _Stamp(text: 'LIKE', color: MtaaniColors.like, angle: -0.35, opacity: likeOpacity),
            ),
            Positioned(
              right: 22,
              top: 30,
              child: _Stamp(text: 'NOPE', color: MtaaniColors.coral, angle: 0.35, opacity: nopeOpacity),
            ),
            Positioned(
              left: 20,
              right: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('${profile.age}',
                            style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w400)),
                      ),
                      const Spacer(),
                      if (onOpen != null)
                        IconButton.filled(
                          onPressed: onOpen,
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.22)),
                          icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                        ),
                    ],
                  ),
                  if (profile.work != null) _InfoLine(icon: Icons.work_outline_rounded, text: profile.work!),
                  _InfoLine(icon: Icons.location_on_outlined, text: distance),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final i in interests) InterestChip(label: i, highlighted: sharedInterests.contains(i), onDark: true),
                    ],
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  final String text;
  final Color color;
  final double angle;
  final double opacity;

  const _Stamp({required this.text, required this.color, required this.angle, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: TextStyle(color: color, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      ),
    );
  }
}

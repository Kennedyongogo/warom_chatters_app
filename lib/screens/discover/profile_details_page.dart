import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/safety_sheet.dart';

/// Full profile. With [showActions] it pops with the chosen [SwipeAction].
class ProfileDetailsPage extends StatelessWidget {
  final Profile profile;
  final bool showActions;

  const ProfileDetailsPage({super.key, required this.profile, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    final shared = profile.interests.toSet().intersection(api.me?.interests.toSet() ?? const {});
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: height * 0.58,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: MtaaniColors.ink,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MtaaniColors.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView(
                    children: [
                      for (final p in profile.photos)
                        Image(image: photoProvider(p), fit: BoxFit.cover, alignment: Alignment.topCenter),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(22, 20, 22, showActions ? 130 : 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${profile.name}, ${profile.age}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
                      const SizedBox(height: 8),
                      if (profile.work != null) _Line(icon: Icons.work_outline_rounded, text: profile.work!),
                      _Line(icon: Icons.location_on_outlined, text: api.distanceLabel(profile)),
                      const SizedBox(height: 22),
                      const _Heading('About'),
                      Text(profile.bio, style: const TextStyle(fontSize: 16, height: 1.5, color: MtaaniColors.ink)),
                      const SizedBox(height: 22),
                      _Heading(shared.isEmpty ? 'Interests' : 'Interests · ${shared.length} in common'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final i in profile.interests) InterestChip(label: i, highlighted: shared.contains(i)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final ended = await showSafetySheet(context, profile: profile);
                            if (ended && context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shield_outlined, color: MtaaniColors.muted),
                          label: Text('Block or report ${profile.firstName}',
                              style: const TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showActions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(40, 20, 40, 20 + MediaQuery.paddingOf(context).bottom),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFFFF), Colors.white],
                    stops: [0, 0.4],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleButton(
                      icon: Icons.close_rounded,
                      color: MtaaniColors.coral,
                      onTap: () => Navigator.pop(context, SwipeAction.pass),
                    ),
                    _CircleButton(
                      icon: Icons.favorite_rounded,
                      color: Colors.white,
                      gradient: MtaaniColors.brandGradient,
                      onTap: () => Navigator.pop(context, SwipeAction.like),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: MtaaniColors.muted)),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MtaaniColors.muted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15.5, color: MtaaniColors.ink)),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.color, required this.onTap, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 66,
          height: 66,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../landing/landing_page.dart';
import 'edit_profile_page.dart';
import 'how_it_works_page.dart';
import 'preferences_page.dart';
import 'safety_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _leave(BuildContext context, {required bool resetDemo}) {
    final api = MtaaniApi.instance;
    resetDemo ? api.reset() : api.logOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final me = api.me;
          if (me == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
              const SizedBox(height: 20),
              _Header(profile: me, onEdit: () => _push(context, const EditProfilePage())),
              const SizedBox(height: 24),
              _Group(children: [
                _Item(
                  icon: Icons.edit_outlined,
                  title: 'Edit profile',
                  subtitle: 'Photos, bio and interests',
                  onTap: () => _push(context, const EditProfilePage()),
                ),
                _Item(
                  icon: Icons.tune_rounded,
                  title: 'Discovery preferences',
                  subtitle: '${me.showMe.label} · ${me.minAge}-${me.maxAge} · within ${me.maxDistanceKm} km',
                  onTap: () => _push(context, const PreferencesPage()),
                ),
                _Item(
                  icon: Icons.shield_outlined,
                  title: 'Safety & privacy',
                  subtitle: 'Visibility, blocked people, safety tips',
                  onTap: () => _push(context, const SafetyPage()),
                ),
              ]),
              const SizedBox(height: 16),
              _Group(children: [
                _Item(
                  icon: Icons.auto_graph_rounded,
                  title: 'How Mtaani works',
                  subtitle: 'Live view of the matching rules',
                  accent: true,
                  onTap: () => _push(context, const HowItWorksPage()),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off_rounded, color: MtaaniColors.ink),
                  title: const Text('Simulate poor network', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Demo: requests fail so you can see swipes aren\'t lost'),
                  value: api.simulateNetworkFailure,
                  activeThumbColor: MtaaniColors.coralDeep,
                  onChanged: (v) => api.simulateNetworkFailure = v,
                ),
                _Item(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset demo',
                  subtitle: 'Clear all likes, matches and messages',
                  onTap: () => _leave(context, resetDemo: true),
                ),
              ]),
              const SizedBox(height: 16),
              _Group(children: [
                _Item(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  onTap: () => _leave(context, resetDemo: false),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Profile profile;
  final VoidCallback onEdit;

  const _Header({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final completeness = [
      profile.photos.isNotEmpty,
      profile.photos.length >= 3,
      profile.bio.isNotEmpty,
      profile.interests.length >= 3,
      profile.work != null && profile.work!.isNotEmpty,
    ].where((x) => x).length / 5;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 132,
              child: CircularProgressIndicator(
                value: completeness,
                strokeWidth: 5,
                backgroundColor: MtaaniColors.line,
                color: MtaaniColors.coralDeep,
              ),
            ),
            Avatar(profile: profile, size: 116),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: MtaaniColors.coralDeep, borderRadius: BorderRadius.circular(100)),
                child: Text('${(completeness * 100).round()}% complete',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('${profile.name}, ${profile.age}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
        const SizedBox(height: 4),
        Text(profile.area.name, style: const TextStyle(color: MtaaniColors.muted)),
        if (!profile.discoverable) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(100)),
            child: const Text('Hidden from Discover',
                style: TextStyle(color: MtaaniColors.coralDeep, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MtaaniColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56, color: MtaaniColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool accent;

  const _Item({required this.icon, required this.title, this.subtitle, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final color = accent ? MtaaniColors.coralDeep : MtaaniColors.ink;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
      onTap: onTap,
    );
  }
}

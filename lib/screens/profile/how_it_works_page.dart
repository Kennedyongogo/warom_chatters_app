import 'package:flutter/material.dart';

import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';

/// Pitch screen: shows the server-side rules working on live demo data.
class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('How Mtaani works')),
      body: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final stats = api.stats;
          final checks = api.explainDiscovery();
          final eligible = checks.where((c) => c.excludedBecause == null).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: MtaaniColors.brandGradient, borderRadius: BorderRadius.circular(22)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.white, size: 30),
                    SizedBox(height: 10),
                    Text('The app never decides',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                      'Who you see, whether a match exists, who can message whom and who gets suspended are '
                      'all decided by the Mtaani server. The phone only displays the result.',
                      style: TextStyle(color: Colors.white, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Title('This session'),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  for (final e in stats.entries) _Stat(value: e.value, label: e.key),
                ],
              ),
              const SizedBox(height: 26),
              _Title('Discovery right now · $eligible of ${checks.length} shown'),
              const Text(
                'Every member is checked against both people\'s preferences, distance, blocks and past swipes '
                'before they can appear on your screen.',
                style: TextStyle(color: MtaaniColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final c in checks) _CheckRow(check: c),
              const SizedBox(height: 26),
              const _Title('How a match happens'),
              ...const [
                ('You swipe right', 'Your like is saved once on the server, with a timestamp.'),
                ('Server checks for a reciprocal like', 'Has this person already liked you?'),
                ('No: wait', 'Your like may appear in their Likes tab. No chat is possible yet.'),
                ('Yes: one transaction', 'Confirms both likes, no blocks and both accounts active, then creates exactly one match.'),
                ('It\'s a Match!', 'Both people are notified and a private chat opens.'),
              ].indexed.map((e) => _Step(index: e.$1 + 1, title: e.$2.$1, body: e.$2.$2)),
              const SizedBox(height: 22),
              const _Title('Chat rules'),
              ...const [
                'Only the two people in an active match can message each other.',
                'Every message is checked for membership and blocks before it is delivered.',
                'Unmatching or blocking ends the conversation for both people.',
                'Messages and profiles can be reported at any time.',
              ].map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.lock_rounded, size: 16, color: MtaaniColors.coralDeep),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 15, height: 1.4))),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: MtaaniColors.coralDeep)),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MtaaniColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: MtaaniColors.ink)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: MtaaniColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final DiscoveryCheck check;

  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final ok = check.excludedBecause == null;
    final p = check.profile;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFEAF8F1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? MtaaniColors.like.withValues(alpha: 0.4) : MtaaniColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ok ? MtaaniColors.like : MtaaniColors.line,
            child: Text(p.name.isEmpty ? '?' : p.name[0],
                style: TextStyle(color: ok ? Colors.white : MtaaniColors.muted, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.name}, ${p.age} · ${p.gender.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  ok ? 'Eligible, can appear in Discover' : check.excludedBecause!,
                  style: TextStyle(fontSize: 13, color: ok ? const Color(0xFF1C8A5F) : MtaaniColors.muted),
                ),
              ],
            ),
          ),
          Icon(ok ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              color: ok ? MtaaniColors.like : MtaaniColors.muted),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final String title;
  final String body;

  const _Step({required this.index, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: MtaaniColors.blush, shape: BoxShape.circle),
            child: Text('$index', style: const TextStyle(color: MtaaniColors.coralDeep, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: MtaaniColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

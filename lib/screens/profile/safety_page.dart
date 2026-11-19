import 'package:flutter/material.dart';

import '../../legal/warom_legal.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../legal/policy_page.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & privacy')),
      body: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final me = api.me!;
          final blocked = api.blockedProfiles;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: MtaaniColors.line),
                ),
                child: SwitchListTile(
                  title: const Text('Show me in Discover', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Turn off to take a break. Your matches and chats stay.'),
                  value: me.discoverable,
                  activeThumbColor: MtaaniColors.coralDeep,
                  onChanged: (v) => guarded(context, () => api.updateProfile((p) => p.discoverable = v)),
                ),
              ),
              const SizedBox(height: 24),
              const _Title('Blocked people'),
              if (blocked.isEmpty)
                const Text('You haven\'t blocked anyone.', style: TextStyle(color: MtaaniColors.muted))
              else
                for (final p in blocked)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Avatar(profile: p, size: 44),
                    title: Text(p.firstName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: TextButton(
                      onPressed: () => guarded(context, () => api.unblock(p.id)),
                      child: const Text('Unblock', style: TextStyle(color: MtaaniColors.coralDeep)),
                    ),
                  ),
              const SizedBox(height: 24),
              const _Title('Dating safely'),
              for (final tip in const [
                (Icons.chat_outlined, 'Keep conversations on Warom until you trust someone.'),
                (Icons.storefront_outlined, 'Meet first in a busy public place, like a café or mall.'),
                (Icons.share_location_outlined, 'Tell a friend where you\'re going and who you\'re meeting.'),
                (Icons.payments_outlined, 'Never send money or M-Pesa to someone you haven\'t met.'),
                (Icons.flag_outlined, 'Report anyone who makes you uncomfortable. We review every report.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tip.$1, color: MtaaniColors.coralDeep, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tip.$2, style: const TextStyle(fontSize: 15, height: 1.4))),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const _Title('Legal'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: MtaaniColors.coralDeep),
                title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
                onTap: () => PolicyPage.open(context, WaromLegal.terms.slug),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined, color: MtaaniColors.coralDeep),
                title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
                onTap: () => PolicyPage.open(context, WaromLegal.privacy.slug),
              ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 12.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: MtaaniColors.muted)),
    );
  }
}

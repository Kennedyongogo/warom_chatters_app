import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../gifts/gifts_page.dart';
import '../landing/landing_page.dart';
import '../vip/vip_page.dart';
import '../wallet/wallet_page.dart';
import 'change_password_page.dart';
import 'delete_account_page.dart';
import 'edit_profile_page.dart';
import 'kyc_page.dart';
import 'locked_photos_page.dart';
import 'people_list_page.dart';
import 'privacy_settings_page.dart';
import 'safety_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _leave(BuildContext context) async {
    try {
      await WaromAuth.instance.clear();
    } catch (_) {}
    MtaaniApi.instance.logOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    final waromUser = WaromAuth.instance.user;
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final me = api.me;
          final name = me?.name ?? waromUser?['username']?.toString() ?? 'You';
          final age = me?.age;
          final area = me?.area.name ?? waromUser?['city']?.toString() ?? 'Worldwide';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
              ),
              const SizedBox(height: 20),
              if (me != null)
                _Header(profile: me, onEdit: () => _push(context, const EditProfilePage()))
              else
                Column(
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: MtaaniColors.blush,
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: MtaaniColors.coralDeep),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      age == null ? name : '$name, $age',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(area, style: const TextStyle(color: MtaaniColors.muted)),
                  ],
                ),
              const SizedBox(height: 24),
              _Group(children: [
                _Item(
                  icon: Icons.edit_outlined,
                  title: 'Edit profile',
                  subtitle: 'Photos, bio and interests',
                  onTap: () => _push(context, const EditProfilePage()),
                ),
                _Item(
                  icon: Icons.visibility_outlined,
                  title: 'Visitors',
                  subtitle: 'Who viewed your profile',
                  onTap: () => _push(
                    context,
                    PeopleListPage(
                      title: 'Visitors',
                      loader: () => WaromApi.instance.visitors(),
                      emptyTitle: 'No visitors yet',
                      emptyMessage: 'People who view your profile will show up here.',
                      emptyIcon: Icons.visibility_outlined,
                    ),
                  ),
                ),
                _Item(
                  icon: Icons.people_outline_rounded,
                  title: 'Followers',
                  onTap: () => _push(
                    context,
                    PeopleListPage(
                      title: 'Followers',
                      loader: () => WaromApi.instance.followers(),
                      emptyTitle: 'No followers',
                      emptyMessage: 'When people follow you, they appear here.',
                    ),
                  ),
                ),
                _Item(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Following',
                  onTap: () => _push(
                    context,
                    PeopleListPage(
                      title: 'Following',
                      loader: () => WaromApi.instance.following(),
                      emptyTitle: 'Not following anyone',
                      emptyMessage: 'People you follow will show up here.',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _Group(children: [
                _Item(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet',
                  subtitle: 'Coins and purchases',
                  onTap: () => _push(context, const WalletPage()),
                ),
                _Item(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Gifts',
                  subtitle: 'Send and received gifts',
                  onTap: () => _push(context, const GiftsPage()),
                ),
                _Item(
                  icon: Icons.workspace_premium_outlined,
                  title: 'VIP',
                  subtitle: 'Plans and status',
                  onTap: () => _push(context, const VipPage()),
                ),
                _Item(
                  icon: Icons.lock_outline_rounded,
                  title: 'Locked photos',
                  subtitle: 'Sell unlockable media',
                  onTap: () => _push(context, const LockedPhotosPage()),
                ),
                _Item(
                  icon: Icons.verified_user_outlined,
                  title: 'KYC & verification',
                  subtitle: 'Required for withdrawals',
                  onTap: () => _push(context, const KycPage()),
                ),
              ]),
              const SizedBox(height: 16),
              _Group(children: [
                _Item(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy',
                  subtitle: 'Visibility and online status',
                  onTap: () => _push(context, const PrivacySettingsPage()),
                ),
                _Item(
                  icon: Icons.shield_outlined,
                  title: 'Safety',
                  subtitle: 'Blocked people and tips',
                  onTap: () => _push(context, const SafetyPage()),
                ),
                _Item(
                  icon: Icons.password_rounded,
                  title: 'Change password',
                  onTap: () => _push(context, const ChangePasswordPage()),
                ),
                _Item(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete account',
                  onTap: () => _push(context, const DeleteAccountPage()),
                ),
              ]),
              const SizedBox(height: 16),
              _Group(children: [
                _Item(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  onTap: () => _leave(context),
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
    return Column(
      children: [
        Avatar(profile: profile, size: 116),
        const SizedBox(height: 14),
        Text(
          '${profile.name}, ${profile.age}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
        ),
        const SizedBox(height: 4),
        Text(profile.area.name, style: const TextStyle(color: MtaaniColors.muted)),
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

  const _Item({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: MtaaniColors.ink),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: MtaaniColors.ink)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
      onTap: onTap,
    );
  }
}

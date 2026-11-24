import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_api.dart';
import '../../services/warom_auth.dart';
import '../../services/warom_realtime.dart';
import '../../theme.dart';
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
      await WaromRealtime.instance.disconnect();
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
              const SizedBox(height: 20),
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

class _Header extends StatefulWidget {
  final Profile profile;
  final VoidCallback onEdit;

  const _Header({required this.profile, required this.onEdit});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  static const _avatarSize = 104.0;
  late final PageController _pages = PageController();

  Profile get profile => widget.profile;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final work = profile.work?.trim();
    final bio = profile.bio.trim();
    final interests = profile.interests;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MtaaniColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RotatingAvatar(
            photos: profile.photos,
            name: profile.name,
            size: _avatarSize,
            controller: _pages,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.name}, ${profile.age}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: MtaaniColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(Icons.edit_outlined, size: 20, color: MtaaniColors.coralDeep),
                    ),
                  ],
                ),
                Text(
                  profile.area.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: MtaaniColors.muted, fontSize: 13),
                ),
                if (work != null && work.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    work,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MtaaniColors.coralDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, height: 1.35, color: MtaaniColors.ink),
                  ),
                ],
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final interest in interests.take(2)) ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: MtaaniColors.blush,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              interest,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: MtaaniColors.coralDeep,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (interests.length > 2)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MtaaniColors.canvas,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: MtaaniColors.line),
                          ),
                          child: Text(
                            '+${interests.length - 2}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              color: MtaaniColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatingAvatar extends StatefulWidget {
  final List<String> photos;
  final String name;
  final double size;
  final PageController controller;

  const _RotatingAvatar({
    required this.photos,
    required this.name,
    required this.size,
    required this.controller,
  });

  @override
  State<_RotatingAvatar> createState() => _RotatingAvatarState();
}

class _RotatingAvatarState extends State<_RotatingAvatar> {
  @override
  void initState() {
    super.initState();
    _armAutoplay();
  }

  @override
  void didUpdateWidget(covariant _RotatingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.length != widget.photos.length) _armAutoplay();
  }

  void _armAutoplay() {
    Future<void>.delayed(const Duration(seconds: 3), _tick);
  }

  void _tick() {
    if (!mounted || widget.photos.length < 2 || !widget.controller.hasClients) {
      _armAutoplay();
      return;
    }
    final next = ((widget.controller.page?.round() ?? 0) + 1) % widget.photos.length;
    widget.controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
    _armAutoplay();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final size = widget.size;

    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: MtaaniColors.brandGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: ClipOval(
          child: SizedBox.square(
            dimension: size,
            child: photos.isEmpty
                ? ColoredBox(
                    color: MtaaniColors.blush,
                    child: Center(
                      child: Text(
                        widget.name.isEmpty ? '?' : widget.name[0].toUpperCase(),
                        style: TextStyle(
                          color: MtaaniColors.coralDeep,
                          fontWeight: FontWeight.w800,
                          fontSize: size * 0.36,
                        ),
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: widget.controller,
                    itemCount: photos.length,
                    itemBuilder: (context, i) {
                      return Image(
                        image: photoProvider(photos[i]),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      );
                    },
                  ),
          ),
        ),
      ),
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

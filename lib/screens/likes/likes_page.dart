import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';

class LikesPage extends StatelessWidget {
  const LikesPage({super.key});

  void _showGold(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 52, color: MtaaniColors.gold),
              const SizedBox(height: 10),
              const Text('Mtaani Gold', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Coming soon', style: TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              for (final perk in const [
                'See everyone who likes you',
                'Like them back instantly from this tab',
                'Super Likes to stand out',
                'Priority in Discover',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: MtaaniColors.gold, size: 20),
                      const SizedBox(width: 10),
                      Text(perk, style: const TextStyle(fontSize: 15.5)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              PillButton(
                color: MtaaniColors.gold,
                onTap: () => Navigator.pop(context),
                child: const Text('Notify me when it launches'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final likes = api.likesReceived;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Likes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
                      const SizedBox(height: 4),
                      Text(
                        likes.isEmpty
                            ? 'No new likes yet'
                            : '${likes.length} ${likes.length == 1 ? 'person likes' : 'people like'} you',
                        style: const TextStyle(fontSize: 15, color: MtaaniColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (likes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Your admirers will appear here',
                    message: 'Complete your profile and keep swiping. When someone likes you, you\'ll see them here.',
                    action: SizedBox(
                      width: 200,
                      child: PillButton.primary(
                        height: 48,
                        onTap: () => context.findAncestorStateOfType<HomeShellState>()?.openTab(0),
                        child: const Text('Go to Discover'),
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: MtaaniColors.coralDeep),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'These people are in your Discover queue. Like them back there to match instantly.',
                              style: TextStyle(fontSize: 13.5, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid.builder(
                    itemCount: likes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, i) => _BlurredLike(
                      profile: likes[i],
                      distance: api.distanceLabel(likes[i]),
                      onTap: () => _showGold(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: PillButton(
                      color: MtaaniColors.gold,
                      onTap: () => _showGold(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded),
                          SizedBox(width: 8),
                          Text('See who likes you'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BlurredLike extends StatelessWidget {
  final Profile profile;
  final String distance;
  final VoidCallback onTap;

  const _BlurredLike({required this.profile, required this.distance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Image(image: photoProvider(profile.photos.first), fit: BoxFit.cover),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x99000000)],
                ),
              ),
            ),
            const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 30)),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Age ${profile.age}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(distance, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

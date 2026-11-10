import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../profile/preferences_page.dart';
import 'match_page.dart';
import 'profile_details_page.dart';
import 'swipe_card.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _api = MtaaniApi.instance;
  final List<Profile> _queue = [];
  final Set<String> _pending = {};
  final Map<String, GlobalKey<SwipeCardState>> _keys = {};
  bool _loading = false;
  bool _exhausted = false;
  Object? _error;
  late int _version = _api.discoveryVersion;

  @override
  void initState() {
    super.initState();
    _api.addListener(_onApiChanged);
    _loadMore();
  }

  @override
  void dispose() {
    _api.removeListener(_onApiChanged);
    super.dispose();
  }

  void _onApiChanged() {
    if (_api.discoveryVersion == _version || _api.me == null) return;
    _version = _api.discoveryVersion;
    setState(() {
      _queue.clear();
      _exhausted = false;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await _api.discover(skip: {..._queue.map((p) => p.id), ..._pending});
      if (!mounted) return;
      setState(() {
        _queue.addAll(batch);
        _exhausted = batch.isEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(Profile profile, SwipeAction action) async {
    setState(() {
      _queue.remove(profile);
      _pending.add(profile.id);
    });
    if (_queue.length < 2 && !_exhausted) _loadMore();
    try {
      final result = await _api.swipe(profile.id, action);
      if (!mounted) return;
      if (result.matched) {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => MatchPage(match: result.match!, other: profile),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // The card animated away optimistically; put it back so the decision is never silently lost.
      setState(() => _queue.insert(0, profile));
      final verb = action == SwipeAction.like ? 'like' : 'pass';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Your $verb on ${profile.firstName} wasn\'t saved. $e'),
          action: SnackBarAction(label: 'Retry', onPressed: () => _decide(profile, action)),
        ));
    } finally {
      _pending.remove(profile.id);
    }
  }

  void _swipeTop(SwipeAction action) {
    if (_queue.isEmpty) return;
    _keys[_queue.first.id]?.currentState?.swipe(action);
  }

  Future<void> _openDetails(Profile profile) async {
    final action = await Navigator.push<SwipeAction>(
      context,
      MaterialPageRoute(builder: (_) => ProfileDetailsPage(profile: profile, showActions: true)),
    );
    if (action != null && mounted) _swipeTop(action);
  }

  Set<String> _shared(Profile p) => p.interests.toSet().intersection(_api.me?.interests.toSet() ?? const {});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
            child: Row(
              children: [
                const BrandTitle(),
                const Spacer(),
                IconButton(
                  tooltip: 'Discovery preferences',
                  icon: const Icon(Icons.tune_rounded, color: MtaaniColors.ink),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesPage())),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: _buildDeck(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundAction(
                  icon: Icons.close_rounded,
                  color: MtaaniColors.coral,
                  size: 64,
                  onTap: _queue.isEmpty ? null : () => _swipeTop(SwipeAction.pass),
                ),
                _RoundAction(
                  icon: Icons.star_rounded,
                  color: MtaaniColors.gold,
                  size: 50,
                  onTap: _queue.isEmpty
                      ? null
                      : () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Super Likes are coming in a future release.'))),
                ),
                _RoundAction(
                  icon: Icons.favorite_rounded,
                  color: Colors.white,
                  gradient: MtaaniColors.brandGradient,
                  size: 64,
                  onTap: _queue.isEmpty ? null : () => _swipeTop(SwipeAction.like),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeck() {
    if (_queue.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator(color: MtaaniColors.coralDeep));
      if (_error != null) {
        return EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Can\'t load profiles',
          message: '$_error',
          action: SizedBox(width: 200, child: PillButton.primary(onTap: _loadMore, height: 48, child: const Text('Try again'))),
        );
      }
      return EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'You\'re all caught up',
        message: 'You\'ve seen everyone who fits your preferences nearby. Widen your age range or distance to meet more people.',
        action: SizedBox(
          width: 220,
          child: PillButton.primary(
            height: 48,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesPage())),
            child: const Text('Adjust preferences'),
          ),
        ),
      );
    }
    final visible = _queue.take(2).toList();
    return Stack(
      children: [
        if (visible.length > 1)
          Positioned.fill(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 12),
                child: Transform.scale(
                  scale: 0.95,
                  child: ProfileCardFace(
                    profile: visible[1],
                    distance: _api.distanceLabel(visible[1]),
                    sharedInterests: _shared(visible[1]),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: SwipeCard(
            key: _keys.putIfAbsent(visible[0].id, GlobalKey<SwipeCardState>.new),
            profile: visible[0],
            distance: _api.distanceLabel(visible[0]),
            sharedInterests: _shared(visible[0]),
            onSwiped: (action) => _decide(visible[0], action),
            onOpen: () => _openDetails(visible[0]),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final double size;
  final VoidCallback? onTap;

  const _RoundAction({required this.icon, required this.color, required this.size, this.gradient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black26,
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
            child: Icon(icon, color: color, size: size * 0.48),
          ),
        ),
      ),
    );
  }
}

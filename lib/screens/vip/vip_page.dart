import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  late Future<_VipBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_VipBundle> _load() async {
    final me = await WaromApi.instance.vipMe();
    final plans = await WaromApi.instance.vipPlans();
    return _VipBundle(me: me, plans: plans);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _subscribe(String planId) async {
    try {
      await WaromApi.instance.subscribeVip(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VIP activated')));
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VIP')),
      body: FutureBuilder<_VipBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final me = snap.data!.me;
          final plans = snap.data!.plans;
          final active = me['is_vip'] == true || me['active'] == true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              SoftCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3D6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: MtaaniColors.gold, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active ? 'VIP active' : 'You are not VIP yet',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            active
                                ? '${me['plan_name'] ?? 'Premium'} · expires ${me['expires_at'] ?? 'soon'}'
                                : 'Unlock badges, boosts, and VIP-only perks.',
                            style: const TextStyle(color: MtaaniColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Plans'),
              if (plans.isEmpty)
                const EmptyLike(
                  icon: Icons.workspace_premium_outlined,
                  title: 'No plans',
                  message: 'VIP plans will appear here when configured.',
                )
              else
                for (final raw in plans)
                  if (raw is Map)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${raw['name'] ?? 'VIP'}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${raw['description'] ?? raw['perks'] ?? 'Premium benefits'}',
                              style: const TextStyle(color: MtaaniColors.muted, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '${raw['price_coins'] ?? raw['price'] ?? '—'} coins',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: MtaaniColors.coralDeep),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: () => _subscribe('${raw['id']}'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: MtaaniColors.coralDeep,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  ),
                                  child: const Text('Subscribe'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _VipBundle {
  final Map<String, dynamic> me;
  final List<dynamic> plans;

  const _VipBundle({required this.me, required this.plans});
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<_WalletBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WalletBundle> _load() async {
    final wallet = await WaromApi.instance.wallet();
    final catalogue = await WaromApi.instance.catalogue();
    final history = await WaromApi.instance.walletHistory();
    return _WalletBundle(wallet: wallet, catalogue: catalogue, history: history);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _buy(String packageId) async {
    try {
      await WaromApi.instance.buyCoins(packageId);
      if (mounted) {
        showSuccessSnack(context, 'Coins added to your wallet');
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: FutureBuilder<_WalletBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final wallet = snap.data!.wallet;
          final balance = (wallet['coin_balance'] as num?)?.toInt() ??
              (wallet['balance'] as num?)?.toInt() ??
              0;
          final packages = (snap.data!.catalogue['coin_packages'] is List)
              ? snap.data!.catalogue['coin_packages'] as List
              : (snap.data!.catalogue['packages'] is List)
                  ? snap.data!.catalogue['packages'] as List
                  : const [];

          return RefreshIndicator(
            color: MtaaniColors.coralDeep,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                SoftCard(
                  child: Column(
                    children: [
                      const Text('Coin balance', style: TextStyle(color: MtaaniColors.muted)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.decimalPattern().format(balance),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Buy coins'),
                if (packages.isEmpty)
                  const Text('No packages available.', style: TextStyle(color: MtaaniColors.muted))
                else
                  for (final raw in packages)
                    if (raw is Map)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SoftCard(
                          onTap: () => _buy('${raw['id']}'),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: MtaaniColors.gold, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${raw['coins'] ?? raw['amount'] ?? raw['name'] ?? 'Coins'}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    Text(
                                      '${raw['price_label'] ?? raw['price'] ?? ''}',
                                      style: const TextStyle(color: MtaaniColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                const SectionLabel('History'),
                if (snap.data!.history.isEmpty)
                  const Text('No wallet activity yet.', style: TextStyle(color: MtaaniColors.muted))
                else
                  for (final raw in snap.data!.history)
                    if (raw is Map)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${raw['description'] ?? raw['type'] ?? 'Transaction'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${raw['created_at'] ?? ''}'),
                        trailing: Text(
                          '${raw['amount_coins'] ?? raw['amount'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WalletBundle {
  final Map<String, dynamic> wallet;
  final Map<String, dynamic> catalogue;
  final List<dynamic> history;

  const _WalletBundle({
    required this.wallet,
    required this.catalogue,
    required this.history,
  });
}

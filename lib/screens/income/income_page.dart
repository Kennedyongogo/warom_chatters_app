import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';
import '../profile/kyc_page.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  late Future<_IncomeBundle> _future;
  final _amount = TextEditingController();
  final _method = TextEditingController(text: 'mpesa');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _method.dispose();
    super.dispose();
  }

  Future<_IncomeBundle> _load() async {
    final api = WaromApi.instance;
    final income = await api.income();
    final tx = await api.incomeTransactions();
    final holds = await api.incomeHolds();
    return _IncomeBundle(income: income, transactions: tx, holds: holds);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _withdraw() async {
    final coins = int.tryParse(_amount.text.trim());
    if (coins == null || coins <= 0) {
      showWarnSnack(context, 'Enter a valid amount');
      return;
    }
    try {
      await WaromApi.instance.requestWithdraw(
        amountCoins: coins,
        payoutMethod: _method.text.trim().isEmpty ? 'mpesa' : _method.text.trim(),
      );
      if (mounted) {
        showSuccessSnack(context, 'Withdrawal requested');
        _amount.clear();
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  int _coins(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      body: FutureBuilder<_IncomeBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final data = snap.data!;
          final income = data.income;
          final pending = _coins(income, ['pending_earnings', 'pending', 'pending_coins']);
          final available = _coins(income, ['available_earnings', 'available', 'available_coins']);
          final lifetime = _coins(income, ['lifetime_earnings', 'lifetime', 'total_earned']);
          final txList = (data.transactions['transactions'] is List)
              ? data.transactions['transactions'] as List
              : (data.transactions['items'] is List)
                  ? data.transactions['items'] as List
                  : data.transactions.values.whereType<List>().expand((e) => e).toList();

          return RefreshIndicator(
            color: MtaaniColors.coralDeep,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                SoftCard(
                  child: Column(
                    children: [
                      const Text('Available to withdraw', style: TextStyle(color: MtaaniColors.muted)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.decimalPattern().format(available),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
                      ),
                      const Text('coins', style: TextStyle(color: MtaaniColors.muted)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _Stat(label: 'Pending', value: pending)),
                          Expanded(child: _Stat(label: 'Lifetime', value: lifetime)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycPage())),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: MtaaniColors.coralDeep),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete KYC to unlock withdrawals',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: MtaaniColors.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Amount in coins'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _method,
                        decoration: const InputDecoration(hintText: 'Payout method'),
                      ),
                      const SizedBox(height: 12),
                      PillButton.primary(onTap: _withdraw, child: const Text('Request withdrawal')),
                    ],
                  ),
                ),
                if (data.holds.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const SectionLabel('Holds'),
                  for (final raw in data.holds)
                    if (raw is Map)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SoftCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: MtaaniColors.gold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${raw['amount_coins'] ?? raw['amount'] ?? 0} coins · ${raw['status'] ?? 'holding'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                const SizedBox(height: 10),
                const SectionLabel('Transactions'),
                if (txList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No earnings yet.', textAlign: TextAlign.center, style: TextStyle(color: MtaaniColors.muted)),
                  )
                else
                  for (final raw in txList)
                    if (raw is Map)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: MtaaniColors.blush,
                          child: Icon(Icons.payments_rounded, color: MtaaniColors.coralDeep),
                        ),
                        title: Text(
                          '${raw['description'] ?? raw['type'] ?? 'Earning'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${raw['created_at'] ?? raw['status'] ?? ''}'),
                        trailing: Text(
                          '+${raw['amount_coins'] ?? raw['amount'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: MtaaniColors.like),
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

class _IncomeBundle {
  final Map<String, dynamic> income;
  final Map<String, dynamic> transactions;
  final List<dynamic> holds;

  const _IncomeBundle({
    required this.income,
    required this.transactions,
    required this.holds,
  });
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          NumberFormat.decimalPattern().format(value),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: MtaaniColors.muted, fontSize: 13)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../services/mtaani_api.dart';
import '../theme.dart';

/// Pitch-only controls, reachable before logging in.
void showDemoOptions(BuildContext context) {
  final api = MtaaniApi.instance;
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: api,
      builder: (context, _) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 6),
              child: Text('Demo options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Demo account: 0712 345 678 (Juma). Every verification code is ${MtaaniApi.demoCode}.',
                style: TextStyle(color: MtaaniColors.muted),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.wifi_off_rounded),
              title: const Text('Simulate poor network', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Every request fails until switched off'),
              value: api.simulateNetworkFailure,
              activeThumbColor: MtaaniColors.coralDeep,
              onChanged: (v) => api.simulateNetworkFailure = v,
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset demo', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Remove new accounts, likes, matches and messages'),
              onTap: () {
                api.reset();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

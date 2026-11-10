import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/mtaani_api.dart';
import '../theme.dart';
import 'common.dart';

const _reportReasons = [
  'Fake profile or scam',
  'Inappropriate photos',
  'Harassment or offensive messages',
  'Under 18',
  'Something else',
];

/// Unmatch / block / report options. Resolves to true when the connection was ended.
Future<bool> showSafetySheet(BuildContext context, {required Profile profile, String? matchId}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matchId != null)
            ListTile(
              leading: const Icon(Icons.heart_broken_outlined),
              title: Text('Unmatch ${profile.firstName}'),
              subtitle: const Text('The conversation ends and neither of you can send new messages.'),
              onTap: () => Navigator.pop(context, 'unmatch'),
            ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: MtaaniColors.coralDeep),
            title: Text('Block ${profile.firstName}', style: const TextStyle(color: MtaaniColors.coralDeep)),
            subtitle: const Text('You won\'t see each other anywhere on Mtaani.'),
            onTap: () => Navigator.pop(context, 'block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: MtaaniColors.coralDeep),
            title: Text('Report ${profile.firstName}', style: const TextStyle(color: MtaaniColors.coralDeep)),
            subtitle: const Text('Our safety team reviews every report.'),
            onTap: () => Navigator.pop(context, 'report'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return false;
  final api = MtaaniApi.instance;
  switch (choice) {
    case 'unmatch':
      final ok = await _confirm(context, 'Unmatch ${profile.firstName}?', 'This can\'t be undone.', 'Unmatch');
      if (!ok || !context.mounted) return false;
      return guarded(context, () => api.unmatch(matchId!));
    case 'block':
      final ok = await _confirm(
        context,
        'Block ${profile.firstName}?',
        'They won\'t be able to see your profile or message you, and you won\'t see theirs.',
        'Block',
      );
      if (!ok || !context.mounted) return false;
      final done = await guarded(context, () => api.block(profile.id));
      if (done && context.mounted) _toast(context, '${profile.firstName} has been blocked.');
      return done;
    case 'report':
      return _report(context, profile);
  }
  return false;
}

/// Reporting also blocks, so the reporter never sees the person again.
Future<bool> _report(BuildContext context, Profile profile, {String? messageText}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              messageText == null ? 'Why are you reporting ${profile.firstName}?' : 'Why are you reporting this message?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          for (final r in _reportReasons)
            ListTile(title: Text(r), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.pop(context, r)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return false;
  final api = MtaaniApi.instance;
  final done = await guarded(context, () async {
    await api.report(profile.id, reason);
    await api.block(profile.id);
  });
  if (done && context.mounted) {
    _toast(context, 'Thanks for keeping Mtaani safe. We\'ll review this and ${profile.firstName} has been blocked.');
  }
  return done;
}

Future<bool> reportMessage(BuildContext context, Profile sender, String text) =>
    _report(context, sender, messageText: text);

Future<bool> _confirm(BuildContext context, String title, String body, String action) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: MtaaniColors.coralDeep),
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

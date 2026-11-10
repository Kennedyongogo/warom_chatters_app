import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_fields.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final _me = MtaaniApi.instance.me!;
  late ShowMe _showMe = _me.showMe;
  late RangeValues _ages = RangeValues(_me.minAge.toDouble(), _me.maxAge.toDouble());
  late double _distance = _me.maxDistanceKm.toDouble();
  late Area _area = _me.area;
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => MtaaniApi.instance.updateProfile((me) {
        me
          ..showMe = _showMe
          ..minAge = _ages.start.round()
          ..maxAge = _ages.end.round()
          ..maxDistanceKm = _distance.round()
          ..area = _area;
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery preferences')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const FieldLabel('Show me'),
                  ChoiceRow<ShowMe>(
                    options: ShowMe.values,
                    value: _showMe,
                    label: (s) => s.label,
                    onChanged: (s) => setState(() => _showMe = s),
                  ),
                  const SizedBox(height: 22),
                  DiscoveryPreferenceFields(
                    ageRange: _ages,
                    distanceKm: _distance,
                    onAgeRange: (v) => setState(() => _ages = v),
                    onDistance: (v) => setState(() => _distance = v),
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Your area'),
                  DropdownButtonFormField<Area>(
                    initialValue: _area,
                    isExpanded: true,
                    items: [for (final a in Area.all) DropdownMenuItem(value: a, child: Text(a.name))],
                    onChanged: (a) => setState(() => _area = a ?? _area),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Mtaani only shows you people whose preferences include you too, so everyone you see could '
                    'genuinely be interested.',
                    style: TextStyle(color: Colors.black54, height: 1.45),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PillButton.primary(onTap: _busy ? null : _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}

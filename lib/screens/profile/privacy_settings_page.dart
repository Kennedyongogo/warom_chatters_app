import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _loading = true;
  Object? _error;
  String _visibility = 'public';
  bool _showOnline = true;
  bool _showVisitors = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await WaromApi.instance.privacy();
      final settings = data['privacy_settings'];
      setState(() {
        _visibility = '${data['profile_visibility'] ?? 'public'}';
        if (settings is Map) {
          _showOnline = settings['show_online'] != false;
          _showVisitors = settings['show_visitors'] != false;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await WaromApi.instance.updatePrivacy(
        visibility: _visibility,
        settings: {
          'show_online': _showOnline,
          'show_visitors': _showVisitors,
        },
      );
      if (mounted) {
        showSuccessSnack(context, 'Privacy updated');
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(error: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profile visibility', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            items: const [
                              DropdownMenuItem(value: 'public', child: Text('Public')),
                              DropdownMenuItem(value: 'matches', child: Text('Matches only')),
                              DropdownMenuItem(value: 'private', child: Text('Private')),
                            ],
                            onChanged: (v) => setState(() => _visibility = v ?? 'public'),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show online status'),
                            value: _showOnline,
                            activeThumbColor: MtaaniColors.coralDeep,
                            onChanged: (v) => setState(() => _showOnline = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Allow visitor history'),
                            value: _showVisitors,
                            activeThumbColor: MtaaniColors.coralDeep,
                            onChanged: (v) => setState(() => _showVisitors = v),
                          ),
                          const SizedBox(height: 8),
                          PillButton.primary(
                            onTap: _saving ? null : _save,
                            height: 48,
                            child: Text(_saving ? 'Saving…' : 'Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/mtaani_api.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_fields.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _me = MtaaniApi.instance.me!;
  late List<String> _photos = [..._me.photos];
  late List<String> _interests = [..._me.interests];
  late final _bio = TextEditingController(text: _me.bio);
  late final _work = TextEditingController(text: _me.work ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _bio.dispose();
    _work.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await guarded(
      context,
      () => MtaaniApi.instance.updateProfile((me) {
        me
          ..photos = _photos
          ..interests = _interests
          ..bio = _bio.text.trim()
          ..work = _work.text.trim().isEmpty ? null : _work.text.trim();
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      showSuccessSnack(context, 'Profile saved');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  FieldLabel('Photos', hint: '${_photos.length}/$maxPhotos'),
                  PhotoGrid(
                    photos: _photos,
                    upload: MtaaniApi.instance.uploadPhoto,
                    onChanged: (p) => setState(() => _photos = p),
                  ),
                  const SizedBox(height: 22),
                  const FieldLabel('Bio'),
                  TextField(controller: _bio, maxLines: 4, maxLength: 300),
                  const SizedBox(height: 10),
                  const FieldLabel('Work'),
                  TextField(controller: _work, decoration: const InputDecoration(hintText: 'What do you do?')),
                  const SizedBox(height: 22),
                  FieldLabel('Interests', hint: '${_interests.length}/$maxInterests'),
                  InterestsPicker(selected: _interests, onChanged: (i) => setState(() => _interests = i)),
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

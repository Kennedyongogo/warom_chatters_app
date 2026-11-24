import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/profile.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/profile_fields.dart';

import 'onboarding_flow.dart';

class BasicsStepPage extends StatefulWidget {
  const BasicsStepPage({super.key});

  @override
  State<BasicsStepPage> createState() => _BasicsStepPageState();
}

class _BasicsStepPageState extends State<BasicsStepPage> {
  final _me = MtaaniApi.instance.me!;
  late final _name = TextEditingController(text: _me.name);
  late Gender? _gender = _me.name.isEmpty ? null : _me.gender;
  late ShowMe? _showMe = _me.name.isEmpty ? null : _me.showMe;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _name.text.trim().length >= 2 && _gender != null && _showMe != null;
    return OnboardingScaffold(
      step: OnboardingStep.basics,
      title: 'Tell us about you',
      subtitle: 'We only show you to people looking for someone like you, and the other way round.',
      busy: _busy,
      primaryLabel: 'Continue',
      onPrimary: ready
          ? () => submitStep(
                context,
                () => MtaaniApi.instance.saveBasics(name: _name.text, gender: _gender!, showMe: _showMe!),
                OnboardingStep.photos,
                setBusy: (b) => setState(() => _busy = b),
              )
          : null,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'First name', helperText: 'This is how you\'ll appear on Warom'),
        ),
        const SizedBox(height: 18),
        const FieldLabel('I am a'),
        ChoiceRow<Gender?>(
          options: Gender.values,
          value: _gender,
          label: (g) => g!.label,
          onChanged: (g) => setState(() => _gender = g),
        ),
        const SizedBox(height: 22),
        const FieldLabel('Show me'),
        ChoiceRow<ShowMe?>(
          options: ShowMe.values,
          value: _showMe,
          label: (s) => s!.label,
          onChanged: (s) => setState(() => _showMe = s),
        ),
      ],
    );
  }
}

class PhotosStepPage extends StatefulWidget {
  const PhotosStepPage({super.key});

  @override
  State<PhotosStepPage> createState() => _PhotosStepPageState();
}

class _PhotosStepPageState extends State<PhotosStepPage> {
  late List<String> _photos = [...MtaaniApi.instance.me!.photos];
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: OnboardingStep.photos,
      title: 'Add your photos',
      subtitle: 'Add at least one clear, recent photo of just you. Tap a photo to make it your main one or reorder.',
      busy: _busy,
      primaryLabel: 'Continue',
      onPrimary: _photos.isEmpty
          ? null
          : () => submitStep(
                context,
                () => MtaaniApi.instance.savePhotos(_photos),
                OnboardingStep.about,
                setBusy: (b) => setState(() => _busy = b),
              ),
      children: [
        PhotoGrid(
          photos: _photos,
          upload: MtaaniApi.instance.uploadPhoto,
          onChanged: (p) => setState(() => _photos = p),
        ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 16, color: MtaaniColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Photos are reviewed before your profile goes live. Nudity, other people\'s photos and contact '
                'details aren\'t allowed.',
                style: TextStyle(fontSize: 13, color: MtaaniColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AboutStepPage extends StatefulWidget {
  const AboutStepPage({super.key});

  @override
  State<AboutStepPage> createState() => _AboutStepPageState();
}

class _AboutStepPageState extends State<AboutStepPage> {
  final _me = MtaaniApi.instance.me!;
  late final _bio = TextEditingController(text: _me.bio);
  late final _work = TextEditingController(text: _me.work ?? '');
  late List<String> _interests = [..._me.interests];
  bool _busy = false;

  @override
  void dispose() {
    _bio.dispose();
    _work.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _interests.length >= 3 && _bio.text.trim().length >= 10;
    return OnboardingScaffold(
      step: OnboardingStep.about,
      title: 'Show your personality',
      subtitle: 'Pick 3 to 5 interests and write a short bio. Matches love a good conversation starter.',
      busy: _busy,
      primaryLabel: 'Continue',
      onPrimary: ready
          ? () => submitStep(
                context,
                () => MtaaniApi.instance.saveAbout(bio: _bio.text, interests: _interests, work: _work.text),
                OnboardingStep.activate,
                setBusy: (b) => setState(() => _busy = b),
              )
          : null,
      children: [
        FieldLabel('Interests', hint: '${_interests.length}/$maxInterests'),
        InterestsPicker(selected: _interests, onChanged: (i) => setState(() => _interests = i)),
        const SizedBox(height: 22),
        const FieldLabel('Bio'),
        TextField(
          controller: _bio,
          maxLines: 4,
          maxLength: 300,
          scrollPadding: const EdgeInsets.only(bottom: 120),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Weekend plans, favourite food, what makes you laugh...'),
        ),
        const SizedBox(height: 6),
        const FieldLabel('Work', hint: 'Optional'),
        TextField(
          controller: _work,
          scrollPadding: const EdgeInsets.only(bottom: 120),
          decoration: const InputDecoration(hintText: 'What do you do?'),
        ),
      ],
    );
  }
}

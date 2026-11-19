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
                OnboardingStep.location,
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
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Weekend plans, favourite food, what makes you laugh...'),
        ),
        const SizedBox(height: 6),
        const FieldLabel('Work', hint: 'Optional'),
        TextField(controller: _work, decoration: const InputDecoration(hintText: 'What do you do?')),
      ],
    );
  }
}

class LocationStepPage extends StatefulWidget {
  const LocationStepPage({super.key});

  @override
  State<LocationStepPage> createState() => _LocationStepPageState();
}

class _LocationStepPageState extends State<LocationStepPage> {
  bool _manual = false;
  Area _area = MtaaniApi.instance.me!.area;
  bool _busy = false;

  void _save(Area area, {required bool fromDevice}) => submitStep(
        context,
        () => MtaaniApi.instance.saveLocation(area, fromDevice: fromDevice),
        OnboardingStep.activate,
        setBusy: (b) => setState(() => _busy = b),
      );

  /// Stands in for the operating system's permission prompt until real location is wired up.
  Future<void> _requestPermission() async {
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_on_rounded),
        title: const Text('Allow Warom to access this device\'s approximate location?'),
        content: const Text('Simulated system prompt', style: TextStyle(color: MtaaniColors.muted, fontSize: 12.5)),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('While using the app')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Only this time')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Don\'t allow')),
        ],
      ),
    );
    if (!mounted) return;
    if (granted == true) {
      _save(Area.all.first, fromDevice: true);
    } else {
      setState(() => _manual = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No problem. Choose your area instead.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: OnboardingStep.location,
      title: _manual ? 'Where are you based?' : 'Find people around you',
      subtitle: _manual
          ? 'Choose the area you spend most of your time in. You can change it any time.'
          : 'Warom uses your approximate location to show people nearby — wherever you are.',
      busy: _busy,
      primaryLabel: _manual ? 'Continue' : 'Allow location',
      onPrimary: _manual ? () => _save(_area, fromDevice: false) : _requestPermission,
      secondary: _manual
          ? null
          : TextButton(
              onPressed: _busy ? null : () => setState(() => _manual = true),
              child: const Text('Choose my area instead',
                  style: TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w700)),
            ),
      children: _manual
          ? [
              DropdownButtonFormField<Area>(
                initialValue: _area,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.location_city_rounded)),
                items: [for (final a in Area.all) DropdownMenuItem(value: a, child: Text(a.name))],
                onChanged: (a) => setState(() => _area = a ?? _area),
              ),
            ]
          : [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(color: MtaaniColors.blush, shape: BoxShape.circle),
                  child: const Icon(Icons.near_me_rounded, size: 56, color: MtaaniColors.coralDeep),
                ),
              ),
              const SizedBox(height: 26),
              for (final (icon, text) in const [
                (Icons.blur_on_rounded, 'We only use approximate location, never your exact address.'),
                (Icons.visibility_off_outlined, 'Others see a distance like "4 km away", never where you are.'),
                (Icons.phonelink_lock_outlined, 'Only while you\'re using the app. Turn it off any time.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: MtaaniColors.coralDeep, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
                    ],
                  ),
                ),
            ],
    );
  }
}

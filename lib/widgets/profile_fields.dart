import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile.dart';
import '../theme.dart';

const allInterests = [
  'Travel', 'Coffee', 'Music', 'Afrobeats', 'Dancing', 'Hiking', 'Nature', 'Cooking', //
  'Food', 'Football', 'Basketball', 'Fitness', 'Yoga', 'Reading', 'Movies', 'Art',
  'Photography', 'Tech', 'Jazz', 'Chess', 'Volunteering', 'Wildlife', 'Swimming', 'Business',
];

const maxPhotos = 6;
const maxInterests = 5;

class PhotoGrid extends StatefulWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  /// Sends a picked image to storage and returns the stored reference.
  final Future<String> Function(String localPath) upload;

  const PhotoGrid({super.key, required this.photos, required this.onChanged, required this.upload});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  int _uploading = 0;

  List<String> get photos => widget.photos;

  Future<void> _upload(String localPath) async {
    setState(() => _uploading++);
    try {
      final stored = await widget.upload(localPath);
      if (mounted) widget.onChanged([...widget.photos, stored]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Photo upload failed. $e'),
          action: SnackBarAction(label: 'Retry', onPressed: () => _upload(localPath)),
        ));
    } finally {
      if (mounted) setState(() => _uploading--);
    }
  }

  Future<void> _manage(int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star_rounded, color: MtaaniColors.coralDeep),
                title: const Text('Make main photo'),
                onTap: () => Navigator.pop(context, 'main'),
              ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded),
                title: const Text('Move earlier'),
                onTap: () => Navigator.pop(context, 'earlier'),
              ),
            if (index < photos.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_forward_rounded),
                title: const Text('Move later'),
                onTap: () => Navigator.pop(context, 'later'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: MtaaniColors.coralDeep),
              title: const Text('Remove photo', style: TextStyle(color: MtaaniColors.coralDeep)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final next = [...photos];
    final photo = next.removeAt(index);
    switch (choice) {
      case 'main':
        next.insert(0, photo);
      case 'earlier':
        next.insert(index - 1, photo);
      case 'later':
        next.insert(index + 1, photo);
      case 'remove':
        break;
    }
    widget.onChanged(next);
  }

  Future<void> _add(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: MtaaniColors.coralDeep),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: MtaaniColors.coralDeep),
              title: const Text('Use a sample photo (demo)'),
              onTap: () => Navigator.pop(context, 'sample'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    String? path;
    if (choice == 'gallery') {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      path = file?.path;
    } else {
      path = 'assets/images/profiles/juma.jpg';
    }
    if (path != null) await _upload(path);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: maxPhotos,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, i) {
        if (i < photos.length) {
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => _manage(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image(image: photoProvider(photos[i]), fit: BoxFit.cover),
                ),
              ),
              if (i == 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                    child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => widget.onChanged([...photos]..removeAt(i)),
                  child: const CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close_rounded, size: 16, color: MtaaniColors.ink),
                  ),
                ),
              ),
            ],
          );
        }
        if (i < photos.length + _uploading) {
          return Container(
            decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: MtaaniColors.coralDeep),
                ),
                SizedBox(height: 8),
                Text('Uploading', style: TextStyle(fontSize: 12, color: MtaaniColors.coralDeep, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }
        final isNext = i == photos.length + _uploading;
        return GestureDetector(
          onTap: isNext ? () => _add(context) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isNext ? MtaaniColors.blush : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNext ? MtaaniColors.coral.withValues(alpha: 0.5) : MtaaniColors.line),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 30,
              color: isNext ? MtaaniColors.coralDeep : MtaaniColors.line,
            ),
          ),
        );
      },
    );
  }
}

class InterestsPicker extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const InterestsPicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final interest in allInterests)
          FilterChip(
            label: Text(interest),
            selected: selected.contains(interest),
            showCheckmark: false,
            selectedColor: MtaaniColors.blush,
            side: BorderSide(
              color: selected.contains(interest) ? MtaaniColors.coral : MtaaniColors.line,
            ),
            labelStyle: TextStyle(
              color: selected.contains(interest) ? MtaaniColors.coralDeep : MtaaniColors.ink,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (on) {
              if (on && selected.length >= maxInterests) return;
              onChanged(on ? [...selected, interest] : (selected.toList()..remove(interest)));
            },
          ),
      ],
    );
  }
}

class ChoiceRow<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const ChoiceRow({super.key, required this.options, required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final o in options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: o == options.last ? 0 : 10),
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o == value ? MtaaniColors.blush : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: o == value ? MtaaniColors.coral : MtaaniColors.line, width: o == value ? 1.6 : 1),
                  ),
                  child: Text(
                    label(o),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: o == value ? MtaaniColors.coralDeep : MtaaniColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;

  const FieldLabel(this.text, {super.key, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MtaaniColors.ink)),
          if (hint != null) ...[
            const Spacer(),
            Text(hint!, style: const TextStyle(fontSize: 13, color: MtaaniColors.muted, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// Age range and distance controls shared by onboarding and the preferences screen.
class DiscoveryPreferenceFields extends StatelessWidget {
  final RangeValues ageRange;
  final double distanceKm;
  final ValueChanged<RangeValues> onAgeRange;
  final ValueChanged<double> onDistance;

  const DiscoveryPreferenceFields({
    super.key,
    required this.ageRange,
    required this.distanceKm,
    required this.onAgeRange,
    required this.onDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel('Age range', hint: '${ageRange.start.round()} - ${ageRange.end.round()}'),
        RangeSlider(
          values: ageRange,
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: MtaaniColors.coralDeep,
          onChanged: onAgeRange,
        ),
        const SizedBox(height: 8),
        FieldLabel('Maximum distance', hint: '${distanceKm.round()} km'),
        Slider(
          value: distanceKm,
          min: 2,
          max: 100,
          divisions: 49,
          activeColor: MtaaniColors.coralDeep,
          onChanged: onDistance,
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile.dart';
import '../theme.dart';
import 'common.dart';

const allInterests = [
  'Travel', 'Coffee', 'Music', 'Afrobeats', 'Dancing', 'Hiking', 'Nature', 'Cooking', //
  'Food', 'Football', 'Basketball', 'Fitness', 'Yoga', 'Reading', 'Movies', 'Art',
  'Photography', 'Tech', 'Jazz', 'Chess', 'Volunteering', 'Wildlife', 'Swimming', 'Business',
];

const maxPhotos = 6;
const maxInterests = 5;

class _PendingUpload {
  final String localPath;
  final String id;

  const _PendingUpload({required this.localPath, required this.id});
}

class PhotoGrid extends StatefulWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  /// Sends a picked image to storage and returns the stored reference.
  final Future<String> Function(String localPath) upload;

  /// Called whenever upload activity starts/stops so parents can disable Continue.
  final ValueChanged<bool>? onUploadingChanged;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onChanged,
    required this.upload,
    this.onUploadingChanged,
  });

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final List<_PendingUpload> _pending = [];

  List<String> get photos => widget.photos;
  bool get _isUploading => _pending.isNotEmpty;
  int get _slotCount => (photos.length + _pending.length).clamp(0, maxPhotos);

  void _notifyUploading() => widget.onUploadingChanged?.call(_isUploading);

  Future<void> _upload(String localPath) async {
    if (photos.length + _pending.length >= maxPhotos) return;

    final pending = _PendingUpload(
      localPath: localPath,
      id: '${DateTime.now().microsecondsSinceEpoch}',
    );
    setState(() => _pending.add(pending));
    _notifyUploading();

    try {
      final stored = await widget.upload(localPath);
      if (!mounted) return;
      setState(() => _pending.removeWhere((p) => p.id == pending.id));
      widget.onChanged([...widget.photos, stored]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pending.removeWhere((p) => p.id == pending.id));
      showApiError(context, e, retry: () => _upload(localPath));
    } finally {
      if (mounted) _notifyUploading();
    }
  }

  Future<void> _manage(int index) async {
    if (_isUploading) return;
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

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      // Smaller encode = faster upload on mobile networks.
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 72,
      requestFullMetadata: false,
    );
    if (file != null) await _upload(file.path);
  }

  Future<void> _add(BuildContext context) async {
    if (_isUploading || photos.length >= maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: MtaaniColors.line,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const Text(
                'Add a photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'Clear face photos work best. Upload starts right away.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: MtaaniColors.muted, height: 1.35),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: MtaaniColors.blush,
                  child: Icon(Icons.photo_library_outlined, color: MtaaniColors.coralDeep),
                ),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: MtaaniColors.blush,
                  child: Icon(Icons.photo_camera_outlined, color: MtaaniColors.coralDeep),
                ),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isUploading)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: MtaaniColors.blush,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MtaaniColors.coral.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: MtaaniColors.coralDeep),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Uploading photo… you can keep browsing while this finishes.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MtaaniColors.coralDeep,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        GridView.builder(
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
              return _PhotoTile(
                image: photoProvider(photos[i]),
                isMain: i == 0,
                onTap: () => _manage(i),
                onRemove: () => widget.onChanged([...photos]..removeAt(i)),
              );
            }

            final pendingIndex = i - photos.length;
            if (pendingIndex < _pending.length) {
              final pending = _pending[pendingIndex];
              return _PhotoTile(
                image: FileImage(File(pending.localPath)),
                uploading: true,
                isMain: photos.isEmpty && pendingIndex == 0,
              );
            }

            final isNext = i == _slotCount;
            return GestureDetector(
              onTap: isNext ? () => _add(context) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isNext ? MtaaniColors.blush : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isNext ? MtaaniColors.coral.withValues(alpha: 0.55) : MtaaniColors.line,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 26,
                      color: isNext ? MtaaniColors.coralDeep : MtaaniColors.line,
                    ),
                    if (isNext) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: MtaaniColors.coralDeep,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ImageProvider image;
  final bool isMain;
  final bool uploading;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _PhotoTile({
    required this.image,
    this.isMain = false,
    this.uploading = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: MtaaniColors.blush,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: MtaaniColors.coralDeep),
              ),
            ),
          ),
        ),
        if (uploading)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Uploading',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        if (isMain && !uploading)
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
              child: const Text(
                'Main',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (!uploading && onRemove != null)
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemove,
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

  const ChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
  });

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
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o == value ? MtaaniColors.blush : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: o == value ? MtaaniColors.coral : MtaaniColors.line,
                      width: o == value ? 1.6 : 1,
                    ),
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

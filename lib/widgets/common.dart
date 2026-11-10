import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile.dart';
import '../models/social.dart';
import '../theme.dart';

class PillButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final BoxBorder? border;
  final Color? shadow;
  final Color foreground;
  final double height;

  const PillButton({
    super.key,
    required this.onTap,
    required this.child,
    this.gradient,
    this.color,
    this.border,
    this.shadow,
    this.foreground = Colors.white,
    this.height = 56,
  });

  const PillButton.primary({super.key, required this.onTap, required this.child, this.height = 56})
      : gradient = MtaaniColors.brandGradient,
        color = null,
        border = null,
        shadow = const Color(0x55EF3F55),
        foreground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(100);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          border: border,
          borderRadius: shape,
          boxShadow: shadow == null || !enabled ? null : [BoxShadow(color: shadow!, blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  }
                : null,
            borderRadius: shape,
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground, fontSize: 17, fontWeight: FontWeight.w600),
                  child: IconTheme.merge(data: IconThemeData(color: foreground), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-tone heart used as the in-app Mtaani mark.
class HeartMark extends StatelessWidget {
  final double size;

  const HeartMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFEF4A60), Color(0xFFEF4A60), Color(0xFFFF8A8E), Color(0xFFFF8A8E)],
        stops: [0, 0.5, 0.5, 1],
      ).createShader(bounds),
      child: Icon(Icons.favorite_rounded, size: size),
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeartMark(size: 28),
        SizedBox(width: 6),
        Text(
          'Mtaani',
          style: TextStyle(color: MtaaniColors.ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

class Avatar extends StatelessWidget {
  final Profile profile;
  final double size;
  final bool ring;

  const Avatar({super.key, required this.profile, this.size = 52, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final image = profile.photos.isEmpty
        ? Container(
            color: MtaaniColors.blush,
            alignment: Alignment.center,
            child: Text(
              profile.name.isEmpty ? '?' : profile.name[0],
              style: TextStyle(color: MtaaniColors.coralDeep, fontWeight: FontWeight.w800, fontSize: size * 0.4),
            ),
          )
        : Image(image: photoProvider(profile.photos.first), fit: BoxFit.cover, alignment: Alignment.topCenter);
    final circle = ClipOval(child: SizedBox.square(dimension: size, child: image));
    if (!ring) return circle;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: MtaaniColors.brandGradient),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: circle,
      ),
    );
  }
}

class InterestChip extends StatelessWidget {
  final String label;
  final bool highlighted;
  final bool onDark;

  const InterestChip({super.key, required this.label, this.highlighted = false, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? Colors.white.withValues(alpha: highlighted ? 0.95 : 0.18)
        : (highlighted ? MtaaniColors.blush : Colors.white);
    final fg = onDark ? (highlighted ? MtaaniColors.coralDeep : Colors.white) : (highlighted ? MtaaniColors.coralDeep : MtaaniColors.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: onDark ? null : Border.all(color: highlighted ? MtaaniColors.coral.withValues(alpha: 0.4) : MtaaniColors.line),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: MtaaniColors.blush, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: MtaaniColors.coralDeep),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MtaaniColors.ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, height: 1.45, color: MtaaniColors.muted)),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

void showApiError(BuildContext context, Object error, {VoidCallback? retry}) {
  final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: retry == null ? null : SnackBarAction(label: 'Retry', onPressed: retry),
    ));
}

/// Runs [call], showing any server rejection to the user. Returns whether it succeeded.
Future<bool> guarded(BuildContext context, Future<void> Function() call) async {
  try {
    await call();
    return true;
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return false;
  }
}

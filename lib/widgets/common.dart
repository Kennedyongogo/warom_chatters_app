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
  final double fontSize;

  const PillButton({
    super.key,
    required this.onTap,
    required this.child,
    this.gradient,
    this.color,
    this.border,
    this.shadow,
    this.foreground = Colors.white,
    this.height = 48,
    this.fontSize = 15,
  });

  const PillButton.primary({
    super.key,
    required this.onTap,
    required this.child,
    this.height = 48,
    this.fontSize = 15,
  })  : gradient = MtaaniColors.brandGradient,
        color = null,
        border = null,
        shadow = const Color(0x33EF3F55),
        foreground = Colors.white;

  PillButton.secondary({
    super.key,
    required this.onTap,
    required this.child,
    this.height = 48,
    this.fontSize = 15,
  })  : gradient = null,
        color = Colors.white,
        border = Border.all(color: MtaaniColors.line),
        shadow = MtaaniColors.ink.withValues(alpha: 0.04),
        foreground = MtaaniColors.coralDeep;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(16);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          border: border,
          borderRadius: shape,
          boxShadow: shadow == null || !enabled
              ? null
              : [
                  BoxShadow(
                    color: shadow!,
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
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
            splashColor: foreground.withValues(alpha: 0.12),
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: Center(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: foreground,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 18),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-tone heart used as the in-app Warom mark.
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
          'Warom',
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

enum AppSnackKind { success, error, info, warn }

void showSuccessSnack(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
  showAppSnack(context, message, kind: AppSnackKind.success, duration: duration);
}

void showInfoSnack(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
  showAppSnack(context, message, kind: AppSnackKind.info, duration: duration);
}

void showWarnSnack(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
  showAppSnack(context, message, kind: AppSnackKind.warn, duration: duration);
}

void showApiError(BuildContext context, Object error, {VoidCallback? retry}) {
  final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
  showAppSnack(
    context,
    message,
    kind: AppSnackKind.error,
    duration: const Duration(seconds: 4),
    action: retry == null
        ? null
        : SnackBarAction(label: 'Retry', textColor: MtaaniColors.coralDeep, onPressed: retry),
  );
}

void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final IconData icon = switch (kind) {
    AppSnackKind.success => Icons.check_circle_rounded,
    AppSnackKind.error => Icons.error_outline_rounded,
    AppSnackKind.warn => Icons.info_rounded,
    AppSnackKind.info => Icons.favorite_rounded,
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: EdgeInsets.zero,
      content: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MtaaniColors.blush,
              Color.lerp(MtaaniColors.blush, MtaaniColors.coral, 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MtaaniColors.coral.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: MtaaniColors.coralDeep.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: MtaaniColors.coralDeep, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: MtaaniColors.coralDeep,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 6),
                action,
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Runs [call], showing any server rejection to the user. Returns whether it succeeded.
Future<bool> guarded(
  BuildContext context,
  Future<void> Function() call, {
  String? successMessage,
}) async {
  try {
    await call();
    if (successMessage != null && context.mounted) {
      showSuccessSnack(context, successMessage);
    }
    return true;
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return false;
  }
}

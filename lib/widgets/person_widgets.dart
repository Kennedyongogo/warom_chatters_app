import 'package:flutter/material.dart';

import '../models/person.dart';
import '../theme.dart';

class PersonAvatar extends StatelessWidget {
  final Person person;
  final double size;
  final bool ring;

  const PersonAvatar({
    super.key,
    required this.person,
    this.size = 52,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = person.avatarUrl;
    final image = url == null
        ? Container(
            color: MtaaniColors.blush,
            alignment: Alignment.center,
            child: Text(
              person.displayName.isEmpty ? '?' : person.displayName[0].toUpperCase(),
              style: TextStyle(
                color: MtaaniColors.coralDeep,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38,
              ),
            ),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: MtaaniColors.blush,
              alignment: Alignment.center,
              child: Icon(Icons.person_rounded, color: MtaaniColors.coralDeep, size: size * 0.45),
            ),
          );

    final circle = ClipOval(child: SizedBox.square(dimension: size, child: image));
    Widget body = circle;
    if (ring) {
      body = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: MtaaniColors.brandGradient),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: circle,
        ),
      );
    }

    if (!person.isOnline) return body;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: MtaaniColors.like,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class PersonTile extends StatelessWidget {
  final Person person;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitle;

  const PersonTile({
    super.key,
    required this.person,
    this.onTap,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: PersonAvatar(person: person, size: 52, ring: person.isVip),
      title: Row(
        children: [
          Flexible(
            child: Text(
              person.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: MtaaniColors.ink),
            ),
          ),
          if (person.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded, size: 16, color: MtaaniColors.coralDeep),
          ],
        ],
      ),
      subtitle: Text(
        subtitle ?? person.locationLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: MtaaniColors.muted),
      ),
      trailing: trailing,
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(color: MtaaniColors.muted, height: 1.35)),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: MtaaniColors.coralDeep,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MtaaniColors.line),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: body,
      ),
    );
  }
}

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: MtaaniColors.coralDeep));
  }
}

class ErrorBody extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorBody({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyLike(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load',
      message: '$error',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class EmptyLike extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyLike({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MtaaniColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.45, color: MtaaniColors.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config.dart';

/// Profile photo when available, otherwise the first letter in a circle
/// (capitals), per the task brief.
class ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final String initial;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    required this.initial,
    this.radius = 28,
  });

  String? get _imageUrl {
    final p = imagePath;
    if (p == null || p.trim().isEmpty) return null;
    if (p.startsWith('http')) return p;
    final origin = Uri.parse(AppConfig.apiBase).origin;
    return '$origin/${p.startsWith('/') ? p.substring(1) : p}';
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (url == null) return fallback;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }
}

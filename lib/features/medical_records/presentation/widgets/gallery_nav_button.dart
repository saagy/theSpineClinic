library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Floating circular chevron button for desktop/mouse gallery navigation.
class GalleryNavButton extends StatelessWidget {
  const GalleryNavButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface.withAlpha(210),
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p8),
          child: Icon(icon, size: 28, color: cs.onSurface),
        ),
      ),
    );
  }
}

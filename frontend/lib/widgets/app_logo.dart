import 'package:flutter/material.dart';

/// MediTrack brand logo used on splash, auth, about, etc.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showBackground = false,
    this.backgroundColor,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.medication_rounded,
        size: size * 0.7,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!showBackground) return image;

    return Container(
      width: size + 16,
      height: size + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: image,
    );
  }
}

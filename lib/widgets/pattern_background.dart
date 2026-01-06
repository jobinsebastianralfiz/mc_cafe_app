import 'package:flutter/material.dart';

class PatternBackground extends StatelessWidget {
  final Widget child;
  final Widget? backgroundImage;
  final double patternOpacity;

  const PatternBackground({
    super.key,
    required this.child,
    this.backgroundImage,
    this.patternOpacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color(0xFFC38A44), // tan/brown
            Color(0xFFD4A574), // primaryLight
            Color(0xFFFFFCF9), // off-white/cream
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background image (optional, e.g., coffee cup)
          if (backgroundImage != null)
            Positioned.fill(child: backgroundImage!),

          // Pattern overlay (black)
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                'assets/images/pattern 2.png',
                fit: BoxFit.cover,
                color: Colors.black,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),

          // Child content (UI elements)
          child,
        ],
      ),
    );
  }
}

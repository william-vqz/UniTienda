// lib/widgets/slide_fade_in.dart
import 'package:flutter/material.dart';

class SlideFadeIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration =
        const Duration(milliseconds: 260), // FIX: 350 → 260ms más ágil
  });

  @override
  Widget build(BuildContext context) {
    // FIX: usar delay escalonado por índice pero con cap para no tardar
    // mucho en listas largas (máx 5 items con delay, el resto aparece ya)
    final delay = Duration(milliseconds: (index.clamp(0, 5) * 40));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Normalizar el valor para que el delay no afecte la curva
        final adjusted = ((value -
                (delay.inMilliseconds /
                    (duration.inMilliseconds + delay.inMilliseconds)))
            .clamp(0.0, 1.0));
        final t = adjusted == 0 ? 0.0 : adjusted;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset:
                Offset(0, 14 * (1 - t)), // FIX: 20 → 14px menos desplazamiento
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

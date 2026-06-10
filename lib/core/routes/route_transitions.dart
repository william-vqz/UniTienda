// lib/core/routes/route_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// FIX: reducir duración de transiciones para que se sienta más rápido
Page<T> buildSlideTransition<T>(Widget child) => CustomTransitionPage<T>(
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(
                0.18, 0.0), // FIX: menos desplazamiento = más fluido
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 220), // FIX: 300 → 220ms
      reverseTransitionDuration:
          const Duration(milliseconds: 160), // FIX: 200 → 160ms
    );

Page<T> buildFadeTransition<T>(Widget child) => CustomTransitionPage<T>(
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 180), // FIX: 250 → 180ms
    );

// NUEVO: transición bottom-sheet para pantallas modales (checkout, cart)
Page<T> buildBottomSlideTransition<T>(Widget child) => CustomTransitionPage<T>(
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    );

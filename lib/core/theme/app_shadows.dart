import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> lightSubtle = [
    BoxShadow(
      color: const Color(0xFF6366F1).withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lightCard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> darkSubtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF6366F1).withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(
      color: const Color(0xFF6366F1).withOpacity(0.4),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];
}

import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static TextStyle displayLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headlineLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
      letterSpacing: -0.3,
    );
  }

  static TextStyle headlineMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle titleLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle titleMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle titleSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFamily: fontFamily,
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      fontFamily: fontFamily,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      fontFamily: fontFamily,
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
      fontFamily: fontFamily,
      letterSpacing: 0.2,
    );
  }
}

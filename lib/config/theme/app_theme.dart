import 'package:flutter/material.dart';

import 'app_spacing.dart';

const _seedColor = Colors.deepPurple;

ThemeData buildLightTheme({
  double contrastLevel = 0.0,
  double spacingScale = 1.0,
}) => ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
    contrastLevel: contrastLevel,
  ),
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  extensions: [AppSpacing.scaled(spacingScale)],
);

ThemeData buildDarkTheme({
  double contrastLevel = 0.0,
  double spacingScale = 1.0,
}) => ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
    contrastLevel: contrastLevel,
  ),
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  extensions: [AppSpacing.scaled(spacingScale)],
);

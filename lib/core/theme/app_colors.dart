import 'package:flutter/material.dart';

/// The Kisima palette: a night sky, brass and lamp light.
///
/// Brass is kept for what matters most on a screen: the passage being
/// read, the play button and progress. Lamp is for headings.
class AppColors {
  /// Usiku. The ground of every screen.
  static const Color night = Color(0xFF131A3A);

  /// The water at the bottom of the well. Behind the player.
  static const Color deep = Color(0xFF0B1028);

  /// The app icon's blue.
  static const Color well = Color(0xFF18225A);

  /// A surface lifted off the night, for the passage being read.
  static const Color raised = Color(0xFF1B2450);

  /// Hairlines and quiet outlines.
  static const Color line = Color(0xFF2C3672);

  /// Shaba.
  static const Color brass = Color(0xFFE4B24C);

  /// Taa.
  static const Color lamp = Color(0xFFF6E3B4);

  /// Main reading text. 14.4 to 1 against night.
  static const Color ivory = Color(0xFFF3EBDD);

  /// Secondary text. 8.0 to 1 against night.
  static const Color mist = Color(0xFFA9B1D6);

  /// Captions. 5.6 to 1 against night.
  static const Color dim = Color(0xFF8D93B0);
}

import 'package:flutter/material.dart';

/// One set of colours for the Kisima look. Named by the job each colour
/// does, so the same names work in the dark and in the light.
class Palette {
  /// The ground of every screen.
  final Color ground;

  /// The player bar and bottom sheets.
  final Color sunk;

  /// The passage being read, and the one thing a screen is about.
  final Color card;

  /// Hairlines and quiet outlines.
  final Color line;

  /// Brass. Kept for the active passage, the play button and progress.
  final Color accent;

  /// Text and icons that sit on brass.
  final Color onAccent;

  /// Headings.
  final Color heading;

  /// Main reading text.
  final Color text;

  /// Secondary text.
  final Color soft;

  /// Captions and labels.
  final Color caption;

  const Palette({
    required this.ground,
    required this.sunk,
    required this.card,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.heading,
    required this.text,
    required this.soft,
    required this.caption,
  });
}

class AppColors {
  /// Usiku: night sky, brass and lamp light.
  static const Palette dark = Palette(
    ground: Color(0xFF131A3A),
    sunk: Color(0xFF0B1028),
    card: Color(0xFF1B2450),
    line: Color(0xFF2C3672),
    accent: Color(0xFFE4B24C),
    onAccent: Color(0xFF131A3A),
    heading: Color(0xFFF6E3B4),
    text: Color(0xFFF3EBDD),
    soft: Color(0xFFA9B1D6),
    caption: Color(0xFF8D93B0),
  );

  /// Mchana: lime-washed wall, ink and darker brass.
  static const Palette light = Palette(
    ground: Color(0xFFF6F0E3),
    sunk: Color(0xFFFBF7EE),
    card: Color(0xFFFFFDF8),
    line: Color(0xFFCFC2A8),
    accent: Color(0xFFB07A12),
    onAccent: Color(0xFF0B1028),
    heading: Color(0xFF18225A),
    text: Color(0xFF1B2040),
    soft: Color(0xFF4B5275),
    caption: Color(0xFF5F6583),
  );

  /// The colours for the phone's current setting, light or dark.
  static Palette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// The mark keeps its own colours in both modes, like the app icon.
  static const Color markWater = Color(0xFF0B1130);
  static const Color markRim = Color(0xFFE4B24C);
  static const Color markDrop = Color(0xFFF6E3B4);
}

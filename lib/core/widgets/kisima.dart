import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Maktoob mark: a stone well seen from above, with one ripple and
/// one drop. The same drawing as the app icon.
class WellMark extends StatelessWidget {
  final double size;

  const WellMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _WellPainter()),
    );
  }
}

class _WellPainter extends CustomPainter {
  const _WellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // The mark is drawn on a 400 unit grid, 200 units from centre to rim.
    final unit = size.shortestSide / 400;

    canvas.drawCircle(
      center,
      200 * unit,
      Paint()..color = AppColors.markWater,
    );

    final rim = Paint()
      ..color = AppColors.markRim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 52 * unit;
    final rimRect = Rect.fromCircle(center: center, radius: 174 * unit);
    const stones = 8;
    const gap = 0.157; // radians, about nine degrees
    const step = 2 * math.pi / stones;
    for (var i = 0; i < stones; i++) {
      canvas.drawArc(rimRect, i * step + gap / 2, step - gap, false, rim);
    }

    canvas.drawCircle(
      center,
      96 * unit,
      Paint()
        ..color = AppColors.markRim.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18 * unit,
    );
    canvas.drawCircle(center, 44 * unit, Paint()..color = AppColors.markDrop);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A row of small dots, borrowed from the border of a kanga.
class DottedBand extends StatelessWidget {
  final Color? color;

  const DottedBand({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: CustomPaint(
        painter: _DotsPainter(color ?? AppColors.of(context).line),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  final Color color;

  const _DotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 14.0;
    final count = (size.width / spacing).floor();
    final start = (size.width - (count - 1) * spacing) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(start + i * spacing, size.height / 2),
        2.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// A card with an arched top, borrowed from the carved doors of the
/// Swahili coast. Used for the one thing a screen is about.
class ArchCard extends StatelessWidget {
  final Widget child;
  final double arch;
  final EdgeInsetsGeometry padding;

  const ArchCard({
    super.key,
    required this.child,
    this.arch = 36,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: k.card,
        border: Border.all(color: k.accent, width: 1.2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(arch),
          topRight: Radius.circular(arch),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
      ),
      child: child,
    );
  }
}

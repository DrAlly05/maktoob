import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kisima.dart';

/// One paragraph of a book.
///
/// Swahili is the main text once it exists. The original sits beneath it,
/// smaller and quieter, and can be hidden. The paragraph being read is
/// lifted into an arched card.
class PassageCard extends StatelessWidget {
  final String original;
  final String? swahili;
  final bool active;
  final bool showOriginal;
  final bool originalRightToLeft;
  final double fontSize;
  final VoidCallback? onTap;

  const PassageCard({
    super.key,
    required this.original,
    this.swahili,
    this.active = false,
    this.showOriginal = true,
    this.originalRightToLeft = false,
    this.fontSize = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final translated = swahili != null && swahili!.isNotEmpty;
    final originalSize = fontSize - 4 < 12 ? 12.0 : fontSize - 4;
    final originalDirection =
        originalRightToLeft ? TextDirection.rtl : TextDirection.ltr;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (translated)
          Text(
            swahili!,
            style: TextStyle(
              fontFamily: AppTheme.display,
              fontSize: fontSize + 3,
              height: 1.45,
              color: AppColors.ivory,
            ),
          ),
        if (translated && showOriginal) const SizedBox(height: 12),
        if (!translated || showOriginal)
          Text(
            original,
            textDirection: originalDirection,
            style: TextStyle(
              fontSize: translated ? originalSize : fontSize,
              height: 1.6,
              color: translated ? AppColors.dim : AppColors.mist,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: active
              ? ArchCard(child: content)
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: content,
                ),
        ),
      ),
    );
  }
}

/// A quiet line of information above the text.
class StatusBanner extends StatelessWidget {
  final String text;

  const StatusBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppColors.mist,
        ),
      ),
    );
  }
}

/// The docked player. It counts paragraphs, not seconds, because the
/// phone's voice speaks one paragraph at a time and has no clock.
class PlayerBar extends StatelessWidget {
  final bool playing;
  final int section;
  final int sectionCount;
  final int paragraph;
  final int paragraphCount;
  final String speedLabel;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSpeed;

  const PlayerBar({
    super.key,
    required this.playing,
    required this.section,
    required this.sectionCount,
    required this.paragraph,
    required this.paragraphCount,
    required this.speedLabel,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final progress = paragraphCount == 0 || paragraph >= paragraphCount
        ? (paragraphCount == 0 ? 0.0 : 1.0)
        : paragraph / paragraphCount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Sehemu $section kati ya $sectionCount',
                    style: const TextStyle(fontSize: 12, color: AppColors.dim),
                  ),
                  const Spacer(),
                  Text(
                    'Aya $paragraph kati ya $paragraphCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mist,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.line,
                  color: AppColors.brass,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ivory,
                        side: const BorderSide(color: AppColors.line),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(56, 44),
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: onSpeed,
                      child: Text(speedLabel),
                    ),
                  ),
                  _SkipButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Aya iliyopita',
                    onPressed: onPrevious,
                  ),
                  PlayButton(playing: playing, onPressed: onPlayPause),
                  _SkipButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Aya ijayo',
                    onPressed: onNext,
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SkipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null ? AppColors.line : AppColors.ivory;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: SizedBox(
        width: 72,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: onPressed == null ? AppColors.line : AppColors.dim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The play button. While the voice is speaking, ripples leave it the
/// way they leave a drop in a well.
class PlayButton extends StatefulWidget {
  final bool playing;
  final VoidCallback onPressed;

  const PlayButton({super.key, required this.playing, required this.onPressed});

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _ripple.repeat();
  }

  @override
  void didUpdateWidget(covariant PlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_ripple.isAnimating) {
      _ripple.repeat();
    } else if (!widget.playing && _ripple.isAnimating) {
      _ripple.stop();
      _ripple.value = 0;
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ripple,
              builder: (context, child) => CustomPaint(
                painter: _RipplePainter(_ripple.value, widget.playing),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: widget.playing ? 'Simamisha' : 'Sikiliza kwa Kiswahili',
            child: Material(
              color: AppColors.brass,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: Icon(
                    widget.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                    color: AppColors.night,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final bool playing;

  const _RipplePainter(this.progress, this.playing);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (!playing) {
      canvas.drawCircle(
        center,
        37,
        Paint()
          ..color = AppColors.brass.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }
    for (var i = 0; i < 2; i++) {
      final t = (progress + i / 2) % 1.0;
      canvas.drawCircle(
        center,
        31 + 13 * t,
        Paint()
          ..color = AppColors.brass.withValues(alpha: 0.55 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.playing != playing;
  }
}

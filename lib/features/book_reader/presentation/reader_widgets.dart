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
    final k = AppColors.of(context);
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
              color: k.text,
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
              color: translated ? k.caption : k.soft,
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
    final k = AppColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: k.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: k.soft,
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
  final VoidCallback? onPreviousSection;
  final VoidCallback? onNextSection;

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
    this.onPreviousSection,
    this.onNextSection,
  });

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    final progress = paragraphCount == 0 || paragraph >= paragraphCount
        ? (paragraphCount == 0 ? 0.0 : 1.0)
        : paragraph / paragraphCount;

    return Container(
      decoration: BoxDecoration(
        color: k.sunk,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _SectionArrow(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Sehemu iliyopita',
                    onPressed: onPreviousSection,
                  ),
                  Text(
                    'Sehemu $section kati ya $sectionCount',
                    style: TextStyle(fontSize: 12, color: k.caption),
                  ),
                  _SectionArrow(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Sehemu ijayo',
                    onPressed: onNextSection,
                  ),
                  const Spacer(),
                  Text(
                    'Aya $paragraph kati ya $paragraphCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: k.soft,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: k.line,
                    color: k.accent,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: k.text,
                        side: BorderSide(color: k.line),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionArrow extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _SectionArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      iconSize: 22,
      color: k.soft,
      disabledColor: k.line,
      onPressed: onPressed,
      icon: Icon(icon),
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
    final k = AppColors.of(context);
    final color = onPressed == null ? k.line : k.text;
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
                color: onPressed == null ? k.line : k.caption,
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
    final k = AppColors.of(context);
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
                painter: _RipplePainter(
                  _ripple.value,
                  widget.playing,
                  k.accent,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: widget.playing ? 'Simamisha' : 'Sikiliza kwa Kiswahili',
            child: Material(
              color: k.accent,
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
                    color: k.onAccent,
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

  final Color color;

  const _RipplePainter(this.progress, this.playing, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (!playing) {
      canvas.drawCircle(
        center,
        37,
        Paint()
          ..color = color.withValues(alpha: 0.3)
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
          ..color = color.withValues(alpha: 0.55 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playing != playing ||
        oldDelegate.color != color;
  }
}

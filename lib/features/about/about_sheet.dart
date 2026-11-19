import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kisima.dart';

/// Shows who made Maktoob and where to find him.
void showAboutMaktoob(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.deep,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  static const List<(String, String)> _links = [
    ('TikTok', 'https://www.tiktok.com/@drallysaid'),
    ('Facebook', 'https://www.facebook.com/drallysaidtz'),
    ('LinkedIn', 'https://www.linkedin.com/in/dr-ally-said-tz/'),
    ('Tovuti', 'https://lunomj.com'),
  ];

  Future<void> _open(String address) async {
    await launchUrl(
      Uri.parse(address),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                WellMark(size: 40),
                SizedBox(width: 12),
                Text(
                  'Maktoob',
                  style: TextStyle(
                    fontFamily: AppTheme.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 26,
                    color: AppColors.lamp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'App ya kusoma na kusikiliza vitabu kwa lugha yako.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.ivory,
              ),
            ),
            const SizedBox(height: 20),
            const DottedBand(),
            const SizedBox(height: 20),
            const Text(
              'IMETENGENEZWA NA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.dim,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dkt. Ally Said',
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: AppColors.ivory,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (name, address) in _links)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ivory,
                      side: const BorderSide(color: AppColors.line),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    onPressed: () => _open(address),
                    child: Text(name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

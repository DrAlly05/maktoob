// Draws the main screens to PNG files so the look can be checked without
// a phone. Run by the cloud build, not by the normal test command:
//
//   flutter test --update-goldens tool/preview/preview_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktoob/core/theme/app_colors.dart';
import 'package:maktoob/core/theme/app_theme.dart';
import 'package:maktoob/features/book_reader/presentation/reader_widgets.dart';
import 'package:maktoob/main.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await loader.load();
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await _loadFont('Fraunces', [
      'assets/fonts/Fraunces-Regular.ttf',
      'assets/fonts/Fraunces-SemiBold.ttf',
      'assets/fonts/Fraunces-Italic.ttf',
    ]);
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ]);
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final icons = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) await _loadFont('MaterialIcons', [icons.path]);
    }
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    final name = mode == ThemeMode.dark ? 'dark' : 'light';
    final k = mode == ThemeMode.dark ? AppColors.dark : AppColors.light;

    testWidgets('home $name', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const HomeScreen(),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('home-$name.png'),
      );
    });

    testWidgets('reader $name', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'As a Man Thinketh',
                                  style: TextStyle(
                                    fontFamily: AppTheme.display,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 15,
                                    color: k.soft,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Thought and Character',
                                  style: TextStyle(
                                    fontFamily: AppTheme.display,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 28,
                                    height: 1.15,
                                    color: k.heading,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const PassageCard(
                            original:
                                'The aphorism, As a man thinketh in his heart '
                                'so is he, embraces the whole of a man\'s being.',
                            swahili:
                                'Methali isemayo, aonavyo mtu nafsini mwake '
                                'ndivyo alivyo, inagusa maisha yote ya '
                                'mwanadamu.',
                          ),
                          const PassageCard(
                            active: true,
                            original:
                                'A man is literally what he thinks, his '
                                'character being the complete sum of all his '
                                'thoughts.',
                            swahili:
                                'Mtu ni kile hasa anachokiwaza. Tabia yake ni '
                                'jumla kamili ya mawazo yake yote.',
                          ),
                          const PassageCard(
                            original:
                                'As the plant springs from, and could not be '
                                'without, the seed, so every act of a man '
                                'springs from the hidden seeds of thought.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  PlayerBar(
                    playing: true,
                    section: 2,
                    sectionCount: 9,
                    paragraph: 2,
                    paragraphCount: 14,
                    speedLabel: '1.0x',
                    onPlayPause: () {},
                    onPrevious: () {},
                    onNext: () {},
                    onSpeed: () {},
                    onPreviousSection: () {},
                    onNextSection: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('reader-$name.png'),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/kisima.dart';
import 'features/about/about_sheet.dart';
import 'features/book_reader/presentation/reader_screen.dart';
import 'file_manager.dart';

void main() {
  runApp(const MaktoobApp());
}

class MaktoobApp extends StatelessWidget {
  const MaktoobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maktoob',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Dark status bar icons on the light ground, light ones on the dark.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _opening = false;

  /// Chooses an EPUB file, parses it and opens the reader.
  Future<void> _openBook() async {
    if (_opening) return;

    final file = await FileManager.pickEpubFile();
    if (file == null || !mounted) return;

    setState(() => _opening = true);
    final book = await FileManager.parseEpub(file);
    if (!mounted) return;
    setState(() => _opening = false);

    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faili hili halikuweza kufunguliwa kama kitabu.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onAbout: () => showAboutMaktoob(context)),
              const SizedBox(height: 36),
              ArchCard(
                arch: 72,
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Soma na sikiliza kitabu chochote kwa Kiswahili.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.display,
                        fontWeight: FontWeight.w600,
                        fontSize: 27,
                        height: 1.2,
                        color: k.heading,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chagua kitabu kilicho kwenye simu yako. Maktoob '
                      'itakitafsiri na kukusomea, aya kwa aya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: k.soft,
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 54,
                      child: _opening
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: k.accent,
                                foregroundColor: k.onAccent,
                                textStyle: const TextStyle(
                                  fontFamily: AppTheme.body,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: _openBook,
                              child: const Text('Fungua kitabu'),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const DottedBand(),
              const SizedBox(height: 32),
              Text(
                'JINSI INAVYOFANYA KAZI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: k.caption,
                ),
              ),
              const SizedBox(height: 18),
              const _Step(
                number: '1',
                title: 'Chagua kitabu',
                body: 'Faili la EPUB lililo kwenye simu yako.',
              ),
              const _Step(
                number: '2',
                title: 'Bonyeza Sikiliza',
                body: 'Tafsiri hufanyika ndani ya simu. Intaneti '
                    'inahitajika mara ya kwanza tu.',
              ),
              const _Step(
                number: '3',
                title: 'Fuata kwa macho na masikio',
                body: 'Aya inayosomwa huwaka, na unaweza kuona '
                    'maandishi ya asili chini yake.',
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: k.soft,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => showAboutMaktoob(context),
                  child: const Text('Imetengenezwa na Dkt. Ally Said'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAbout;

  const _Header({required this.onAbout});

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    return Row(
      children: [
        const WellMark(size: 46),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maktoob',
                style: TextStyle(
                  fontFamily: AppTheme.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                  height: 1.1,
                  color: k.heading,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'KISIMA CHA MAARIFA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: k.soft,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Kuhusu Maktoob',
          color: k.soft,
          onPressed: onAbout,
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Step({required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final k = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: k.line, width: 1.5),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: k.heading,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: k.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: k.soft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

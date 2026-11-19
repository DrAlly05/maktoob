import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
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
      theme: AppTheme.darkTheme,
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
          content: Text('This file could not be opened as an EPUB book.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maktoob 📖'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Maktoob',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (_opening)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _openBook,
                child: const Text('Open a book (EPUB)'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DocViewerApp());
}

class DocViewerApp extends StatelessWidget {
  const DocViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2F5D8A);
    return MaterialApp(
      title: '문서 뷰어',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

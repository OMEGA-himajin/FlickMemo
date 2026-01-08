import 'package:flutter/material.dart';

void main() {
  runApp(const FlickMemoApp());
}

class FlickMemoApp extends StatelessWidget {
  const FlickMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlickMemo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlickMemo')),
      body: const Center(child: Text('FlickMemo UI is under construction.')),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const SeniorEaseApp());
}

class SeniorEaseApp extends StatelessWidget {
  const SeniorEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeniorEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('SeniorEase'))),
    );
  }
}

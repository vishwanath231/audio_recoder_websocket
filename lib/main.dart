// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_recorder_app/pages/home_page.dart';
import 'package:audio_recorder_app/provider/audio_recording_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioRecordingProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

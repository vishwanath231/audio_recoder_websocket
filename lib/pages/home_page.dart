// lib/pages/home_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import '../provider/audio_recording_provider.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? _recordingTimer;
  StreamSubscription<Duration>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerSubscription = audioPlayer.positionStream.listen((position) {
      context.read<AudioRecordingProvider>().updatePlaybackPosition(position.inSeconds);
    });
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        context.read<AudioRecordingProvider>().stopPlaying();
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Consumer<AudioRecordingProvider>(
        builder: (context, recordingProvider, child) {
          if (recordingProvider.isPlaying) {
            return Container(); // Return an empty container when the FAB should be hidden
          } else {
            return _recordingButton();
          }
        },
      ),
      body: Consumer<AudioRecordingProvider>(
        builder: (context, recordingProvider, child) {
          return _buildUI(recordingProvider);
        },
      ),
    );
  }

  Widget _buildUI(AudioRecordingProvider recordingProvider) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (recordingProvider.isRecording)
            Text(
              "Recording... ${recordingProvider.recordingDuration} s",
              style: TextStyle(
                fontSize: 24,
                color: Colors.red,
              ),
            ),
          if (recordingProvider.recordingPath != null)
            MaterialButton(
              onPressed: () async {
                if (audioPlayer.playing) {
                  audioPlayer.stop();
                  recordingProvider.stopPlaying();
                } else {
                  await audioPlayer.setFilePath(recordingProvider.recordingPath!);
                  audioPlayer.play();
                  recordingProvider.startPlaying();
                }
              },
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                recordingProvider.isPlaying
                    ? "Stop Playing Recording"
                    : "Start Playing Recording",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          if (recordingProvider.isPlaying)
            Column(
              children: [
                Text(
                  "Duration: ${recordingProvider.playbackPosition} s",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          if (recordingProvider.recordingPath == null && !recordingProvider.isRecording)
            const Text(
              "No Recording Found. :(",
            ),
        ],
      ),
    );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        final recordingProvider = context.read<AudioRecordingProvider>();

        if (recordingProvider.isRecording) {
          String? filePath = await audioRecorder.stop();
          _recordingTimer?.cancel();
          if (filePath != null) {
            recordingProvider.stopRecording(filePath);
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
            final String filePath = p.join(appDocumentsDir.path, "recording.wav");
            recordingProvider.startRecording();


            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );

            // Start the timer to update the recording duration
            _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              recordingProvider.updateRecordingDuration(recordingProvider.recordingDuration + 1);
            });

            // Stop recording after 10 seconds
            Future.delayed(const Duration(seconds: 10), () async {
              if (recordingProvider.isRecording) {
                String? filePath = await audioRecorder.stop();
                _recordingTimer?.cancel();
                if (filePath != null) {
                  recordingProvider.stopRecording(filePath);
                }
              }
            });
          }
        }
      },
      child: Icon(
        context.read<AudioRecordingProvider>().isRecording ? Icons.stop : Icons.mic,
      ),
    );
  }
}

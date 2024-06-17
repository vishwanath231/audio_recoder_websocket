import 'dart:async';
import 'dart:io';

import 'package:audio_recorder_app/components/loader.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../provider/audio_recording_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  late AudioPlayer audioPlayer;
  Timer? _recordingTimer;
  bool isPlaybackStarted = false; // Track playback state
  StreamSubscription<Duration>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerSubscription = audioPlayer.positionStream.listen((position) {
      context.read<AudioRecordingProvider>().updatePlaybackPosition(position.inSeconds);
    });
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        context.read<AudioRecordingProvider>().stopPlaying();
        setState(() {
          isPlaybackStarted = false; // Reset playback state
        });
      }
    });
  }

  void _handlePlaybackCompleted() {
    if (isPlaybackStarted) {
      context.read<AudioRecordingProvider>().stopPlaying();
      audioPlayer.stop();
      setState(() {
        isPlaybackStarted = false; // Reset playback state
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _toggleRecording(AudioRecordingProvider recordingProvider) async {
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

        _recordingTimer = Timer.periodic(
          const Duration(seconds: 1),
              (timer) {
            recordingProvider.updateRecordingDuration(
              recordingProvider.recordingDuration + 1,
            );
          },
        );
      }
    }
  }

  void _startPlayback(String filePath, AudioRecordingProvider recordingProvider) async {
    if (isPlaybackStarted) {
      _handlePlaybackCompleted();
    }

    await audioPlayer.setFilePath(filePath);
    await audioPlayer.play();
    setState(() {
      recordingProvider.startPlaying();
      isPlaybackStarted = true; // Set playback started flag
    });

    // Start monitoring playback duration
    _monitorPlaybackDuration(recordingProvider);
  }

  void _monitorPlaybackDuration(AudioRecordingProvider recordingProvider) {
    _playerSubscription?.onData((position) {
      if (audioPlayer.duration != null && position >= audioPlayer.duration!) {
        _handlePlaybackCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AudioRecordingProvider>(
        builder: (context, recordingProvider, child) {
          if (recordingProvider.recordingPath != null &&
              !recordingProvider.isLoading &&
              !recordingProvider.isPlaying) {
            // Start playback after the current build cycle completes
            WidgetsBinding.instance!.addPostFrameCallback((_) {
              _startPlayback(recordingProvider.recordingPath!, recordingProvider);
            });
          } else if (recordingProvider.isPlaying) {
            // Check if audio playback duration has completed
            _monitorPlaybackDuration(recordingProvider);
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(),
              recordingProvider.isLoading
                  ? const Center(child: ThreeDotLoadingIndicator())
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),  // Semi-transparent black shadow
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _toggleRecording(recordingProvider),
                      icon: Icon(
                        recordingProvider.isRecording ? Icons.stop : Icons.mic,
                        size: 48.0,
                        color: Color(0xffb98c3c),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatDuration(Duration(seconds: recordingProvider.recordingDuration)),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xff1c468c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 20.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 80,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

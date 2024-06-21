import 'dart:async';
import 'dart:io';

import 'package:audio_recorder_app/components/loader.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../provider/audio_recording_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AudioPlayer _audioPlayer;
  late AudioRecorder _audioRecorder;
  Timer? _recordingTimer;
  bool _isPlaybackStarted = false;
  StreamSubscription<Duration>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioRecorder = AudioRecorder();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerSubscription = _audioPlayer.positionStream.listen((position) {
      context.read<AudioRecordingProvider>().updatePlaybackPosition(position.inSeconds);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        context.read<AudioRecordingProvider>().stopPlaying();
        setState(() {
          _isPlaybackStarted = false;
        });
      }
    });
  }

  void _handlePlaybackCompleted() {
    if (_isPlaybackStarted) {
      context.read<AudioRecordingProvider>().stopPlaying();
      _audioPlayer.stop();
      setState(() {
        _isPlaybackStarted = false;
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playerSubscription?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose(); // Dispose AudioRecorder instance
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
      String? filePath = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      if (filePath != null) {
        recordingProvider.stopRecording(filePath);
        // No need to start playback here, as it will be handled in the provider
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String filePath = p.join(appDocumentsDir.path, "recording.wav");
        recordingProvider.startRecording();

        await _audioRecorder.start(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AudioRecordingProvider>(
        builder: (context, recordingProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(), // Add your top content here
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color
                      borderRadius: BorderRadius.circular(15), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/avatar.png', // Replace with your actual image path
                        width: 290,
                        height: 290,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: recordingProvider.isLoading
                            ? null
                            : () => _toggleRecording(recordingProvider),
                        icon: recordingProvider.isLoading
                            ? ThreeDotWaveLoadingIndicator() // Show loading indicator
                            : Icon(
                          recordingProvider.isRecording ? Icons.stop : Icons.mic,
                          size: 38.0,
                          color: const Color(0xffb98c3c),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    child: Text(
                      _formatDuration(Duration(seconds: recordingProvider.recordingDuration)),
                      style: const TextStyle(
                        fontSize: 24,
                        color: const Color(0xff1c468c),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
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

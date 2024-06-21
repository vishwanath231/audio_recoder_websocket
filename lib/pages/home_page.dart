import 'dart:async';
import 'dart:io';

import 'package:audio_recorder_app/components/loader.dart';
import 'package:audio_recorder_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../provider/audio_recording_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  late AudioPlayer audioPlayer;
  Timer? _recordingTimer;
  bool isPlaybackStarted = false;
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
          isPlaybackStarted = false;
        });
      }
    });
  }

  void _handlePlaybackCompleted() {
    if (isPlaybackStarted) {
      context.read<AudioRecordingProvider>().stopPlaying();
      audioPlayer.stop();
      setState(() {
        isPlaybackStarted = false;
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
        // No need to start playback here, as it will be handled in the provider
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

  // Future<void> _logout(BuildContext context) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('user_id');
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => LoginScreen()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.logout),
      //       onPressed: () => _logout(context),
      //     ),
      //   ],
      // ),
      backgroundColor: Colors.white,
      body: Consumer<AudioRecordingProvider>(
        builder: (context, recordingProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(),
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
                          offset: Offset(0, 3), // changes position of shadow
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
                        // border: Border.all(color: Color(0xFFFBCDAD)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3),
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
                          color: Color(0xffb98c3c),
                        ), // Show mic or stop icon based on recording state
                      ),

                    ),

                  ),
                  Positioned(
                    bottom: -80,
                    child: Text(
                    _formatDuration(Duration(seconds: recordingProvider.recordingDuration)),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xff1c468c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),)
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
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:just_audio/just_audio.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';


class AudioRecordingProvider extends ChangeNotifier {
  String? _recordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  int _recordingDuration = 0;
  int _playbackPosition = 0;
  late IO.Socket _socket;
  late AudioPlayer _audioPlayer;

  AudioRecordingProvider() {
    _initWebSocket();
    _audioPlayer = AudioPlayer();
  }

  String? get recordingPath => _recordingPath;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  int get recordingDuration => _recordingDuration;
  int get playbackPosition => _playbackPosition;

  void _initWebSocket() {
    _socket = IO.io('https://demo.carebells.org', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to WebSocket server');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
    });

    _socket.on('audio_data', (data) {
      print("========================================> audio received");

      Map<String, dynamic> message = data as Map<String, dynamic>;
      List<int> audioData = List<int>.from(message['audio']);
      _playAudioFromBytes(audioData);
    });
  }



  Future<void> _sendAudioToWebSocket(String filePath) async {

    print("========================================> audio send processing...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? _userId = prefs.getInt('user_id');

    if(_userId != null){
      File audioFile = File(filePath);
      if (await audioFile.exists()) {
        List<int> audioBytes = await audioFile.readAsBytes();
        Map<String, dynamic> response = {
          "user_id": _userId,
          "prompt": {
            "audio": audioBytes,
            "text": "test"
          }
        };
        _socket.emit('audio', response);

        print("========================================> audio sended compledted");

      }
    }else {
      print("id not found!");
    }

  }

  void startRecording() {
    _isRecording = true;
    _recordingPath = null;
    _recordingDuration = 0;
    notifyListeners();
  }

  void stopRecording(String? path) {
    _isRecording = false;
    _isLoading = true;
    _recordingDuration = 0;
    notifyListeners();

    if (path != null) {
      _sendAudioToWebSocket(path);
    }
  }

  void updateRecordingDuration(int duration) {
    _recordingDuration = duration;
    notifyListeners();
  }

  void startPlaying() {
    _isPlaying = true;
    notifyListeners();
  }

  void stopPlaying() {
    _isPlaying = false;
    notifyListeners();
  }

  void updatePlaybackPosition(int position) {
    _playbackPosition = position;
    notifyListeners();
  }

  Future<void> _playAudioFromBytes(List<int> audioBytes) async {
    try {
      // Create a Stream of bytes from the List<int>
      final stream = Stream.value(audioBytes).asBroadcastStream();

      // Set the audio source to the AudioPlayer from bytes
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(
            audioBytes,
            mimeType: 'audio/mpeg', // Adjust mime type as necessary
          ),
        ),
      );
      _isLoading = false;
      notifyListeners();

      // Play the audio
      await _audioPlayer.play();

    } catch (e) {
      print('Error playing audio: $e');
    }
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:just_audio/just_audio.dart'; // Add this import

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
      Map<String, dynamic> message = data as Map<String, dynamic>;
      List<int> audioData = List<int>.from(message['audio']);
      _saveAudioLocally(audioData);
    });
  }

  Future<void> _sendAudioToWebSocket(String filePath) async {
    File audioFile = File(filePath);
    if (await audioFile.exists()) {
      List<int> audioBytes = await audioFile.readAsBytes();
      Map<String, dynamic> response = {
        "user_id": 1,
        "prompt": {
          "audio": audioBytes,
          "text": "test"
        }
      };
      _socket.emit('audio', response);
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

  Future<void> _saveAudioLocally(List<int> audioBytes) async {
    try {
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDocumentsDir.path}/beat.mp3';

      await File(filePath).writeAsBytes(audioBytes);
      _recordingPath = filePath;

      _isLoading = false;
      notifyListeners();

      // Play the beat.mp3 file automatically
      await _playSavedAudio();
    } catch (e) {
      print('Error saving audio locally: $e');
    }
  }

  Future<void> _playSavedAudio() async {
    if (_recordingPath != null) {
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
    }
  }
}
// lib/provider/audio_recording_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

class AudioRecordingProvider extends ChangeNotifier {
  String? _recordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingDuration = 0;
  int _playbackPosition = 0;
  late IO.Socket _socket;
  List<int>? audioChuck;

  AudioRecordingProvider() {
    _initWebSocket();
  }

  String? get recordingPath => _recordingPath;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get recordingDuration => _recordingDuration;
  int get playbackPosition => _playbackPosition;

  void _initWebSocket() {
    _socket = IO.io('wss://demo.carebells.org', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });


    try {
      // Attempt to connect to the WebSocket server
      _socket.connect();
      print('Attempting to connect to WebSocket server...');

      // Handle the connect event
      _socket.onConnect((_) {
        print('Connected to WebSocket server');
      });

      // Handle the disconnect event
      _socket.onDisconnect((_) {
        print('Disconnected from WebSocket server');
      });

    } catch (e) {
      // Handle any errors that occur during connection
      print('Error connecting to WebSocket server: $e');
    }

    // _socket.connect();
    //
    // _socket.onConnect((_) {
    //   print('Connected to WebSocket server');
    // });
    //
    // _socket.onDisconnect((_) {
    //   print('Disconnected from WebSocket server');
    // });



    // _socket.on('audio_data', (data) {
    //   // print("audio chunk --------------> $data['audio_chunk']");
    //   if (data != null && data['audio'] != null) {
    //     _saveAudioLocally(data['audio']);
    //   }
    // });
  }

  Future<void> _sendAudioToWebSocket(String filePath) async {
    File audioFile = File(filePath);
    if (await audioFile.exists()) {
      List<int> audioBytes = await audioFile.readAsBytes();
      _socket.emit('audio', audioBytes);
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
    _socket.on('audio_data', (data) {
      if (data != null && data['audio'] != null) {
          _saveAudioLocally(data['audio']);
      }
    });
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
      final filePath = '${appDocumentsDir.path}/new_audio.mp3';

      // Write audio bytes to file
      await File(filePath).writeAsBytes(audioBytes);

      // Set _recordingPath after saving
      _recordingPath = filePath;

      notifyListeners();
    } catch (e) {
      print('Error saving audio locally: $e');
    }
  }

}

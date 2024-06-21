import 'package:audio_recorder_app/components/loader.dart';
import 'package:audio_recorder_app/pages/home_page.dart';
import 'package:audio_recorder_app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CheckLogin extends StatefulWidget {
  @override
  _CheckLoginState createState() => _CheckLoginState();
}

class _CheckLoginState extends State<CheckLogin> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user_id')) {
      final userId = prefs.getInt('user_id');
      if (await _checkUserValidity(userId)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Invalid user ID, navigate to login page
        prefs.remove('user_id');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } else {
      // No User ID, navigate to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<bool> _checkUserValidity(int? userId) async {
    if (userId == null) return false;
    try {
      final response = await http.get(Uri.parse('https://demo.carebells.org/v1/user/$userId'));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error checking user validity: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: ThreeDotWaveLoadingIndicator()), // Loading indicator while checking
    );
  }
}

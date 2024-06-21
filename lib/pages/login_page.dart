import 'package:audio_recorder_app/components/loader.dart';
import 'package:audio_recorder_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Logo at the center
                Container(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20.0),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 80,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // User ID Input
                SizedBox(
                  width: 350,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                          labelText: 'User ID',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                        border: OutlineInputBorder()
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your user ID';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Login Button
                SizedBox(
                  width: 350,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25.0),
                    child: ElevatedButton(
                        onPressed: _login,
                        child: _isLoading
                            ? ThreeDotWaveLoadingIndicator()
                            : Text('Login'),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Color(0xff1c468c)), // Background color
                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(10.0)),
                          minimumSize: MaterialStateProperty.all<Size>(Size(300, 55)),
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          textStyle: MaterialStateProperty.all<TextStyle>(
                            TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          elevation: MaterialStateProperty.all<double>(1),
                          shadowColor: MaterialStateProperty.all<Color>(Colors.grey.shade100),
                          shape: MaterialStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0))),
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userId = int.tryParse(_userIdController.text);
      if (userId != null) {
        setState(() {
          _isLoading = true; // Start showing loading indicator
        });
        if (await _checkUserValidity(userId)) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          setState(() {
            _isLoading = false; // Stop showing loading indicator
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid User ID or user does not exist')),
          );
        }
      }
    }
  }

  Future<bool> _checkUserValidity(int userId) async {
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
}

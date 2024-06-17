import 'package:flutter/material.dart';
import 'dart:async';  // Add this import

class ThreeDotLoadingIndicator extends StatefulWidget {
  const ThreeDotLoadingIndicator({Key? key}) : super(key: key);

  @override
  State<ThreeDotLoadingIndicator> createState() => _ThreeDotLoadingIndicatorState();
}

class _ThreeDotLoadingIndicatorState extends State<ThreeDotLoadingIndicator> {
  int _dotCount = 1;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount % 3) + 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('. ' * _dotCount, style: TextStyle(fontSize: 36)),
      ],
    );
  }
}

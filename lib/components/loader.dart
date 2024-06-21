import 'package:flutter/material.dart';
import 'dart:async';

class ThreeDotWaveLoadingIndicator extends StatefulWidget {
  const ThreeDotWaveLoadingIndicator({Key? key}) : super(key: key);

  @override
  _ThreeDotWaveLoadingIndicatorState createState() => _ThreeDotWaveLoadingIndicatorState();
}

class _ThreeDotWaveLoadingIndicatorState extends State<ThreeDotWaveLoadingIndicator> {
  int _dotIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Initialize a timer to animate the dots
    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotIndex = (_dotIndex + 1) % 3; // Cycle through dot indices 0, 1, 2
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Dot(index: 0, currentIndex: _dotIndex),
        SizedBox(width: 8), // Adjust spacing between dots
        Dot(index: 1, currentIndex: _dotIndex),
        SizedBox(width: 8), // Adjust spacing between dots
        Dot(index: 2, currentIndex: _dotIndex),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  final int index;
  final int currentIndex;

  const Dot({required this.index, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: currentIndex == index ? Color(0xff1c468c) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: currentIndex == index ? 1.0 : 0.5,
          duration: Duration(milliseconds: 500),
          child: Text(
            '.',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';



class MeditationTimerScreen extends StatefulWidget {
  // Field to accept the duration from the wellness screen
  final int initialDurationInMinutes;

  const MeditationTimerScreen({
    super.key,
    required this.initialDurationInMinutes,
  });

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  late int _initialDuration;
  late int _duration;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    // Initialize the timer with the passed-in duration, converting it to seconds
    _initialDuration = widget.initialDurationInMinutes * 60;
    _duration = _initialDuration;
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is closed to prevent memory leaks
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return; // Don't start if already running

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_duration > 0) {
          _duration--;
        } else {
          _stopTimer();
          // Show a confirmation dialog when the session is complete
           if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Session Complete!'),
                content: const Text('Great job on completing your meditation session.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Okay'),
                  )
                ],
              ),
            );
          }
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

   void _stopTimer() {
    _timer?.cancel();
    setState(() {
      // Reset the timer to the initial user-selected duration
      _duration = _initialDuration;
      _isRunning = false;
    });
  }

  // Helper method to format the remaining seconds into a MM:SS string
  String _formatDuration() {
    final minutes = (_duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Session'),
        backgroundColor: Colors.deepPurple[50],
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              _formatDuration(),
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.deepPurple[800]),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play/Pause Button - changes icon based on state
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  iconSize: 80,
                  color: Colors.deepPurple,
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 20),
                // Stop/Reset Button
                 IconButton(
                  icon: const Icon(Icons.stop_circle),
                  iconSize: 80,
                  color: Colors.grey[600],
                  onPressed: _stopTimer,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


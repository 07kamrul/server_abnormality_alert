import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vibration/vibration.dart';

void main() async {
  runApp(MyApp());
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "checkServer") {
      final response = await http.get(Uri.parse('http://sysadmin-s.colgis.com/api/mail'));
      final int responseValue = int.parse(response.body);

      if (response.statusCode == 200 && responseValue == 0) {
        // Trigger notification or alert
        AudioPlayer().play(AssetSource('assets/Warning-Siren01-1.mp3'));
      }
    }
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MonitoringScreen(),
    );
  }
}

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  // Function to start monitoring asynchronously
  Future<void> _startMonitoring() async {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final response = await http.get(Uri.parse('http://sysadmin-s.colgis.com/api/mail'));
      final int responseValue = int.parse(response.body);

      if (response.statusCode == 200 && responseValue == 0) {
        await _playAlert();
        _showAlertDialog();
        await _startVibration();
      }
    });
  }

  // Asynchronous function to play audio
  Future<void> _playAlert() async {
    await _audioPlayer.play(AssetSource('audio/Warning-Siren01-1.mp3'));
  }

  // Asynchronous function to start vibration
  Future<void> _startVibration() async {
    if (_timer == null && await Vibration.hasVibrator() == true) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        await Vibration.vibrate(duration: 500); // Vibrate repeatedly
      });
    }
  }

  // Asynchronous function to stop vibration
  Future<void> _stopVibration() async {
    _timer?.cancel();
    _timer = null;
    await Vibration.cancel(); // Ensure vibration stops
  }

  // Function to show an alert dialog
  void _showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'システム障害発生',
                style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text("至急、サーバー異常検知メールを確認して、サーバー管理者に電話連絡をして下さい。",
            style: TextStyle(fontSize: 20, color: Colors.blue),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _audioPlayer.stop();
                _stopVibration();
                Navigator.of(context).pop();
              },
              child: const Row(
                children: [
                  Text(
                    "OK ",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    " をクリックして警告音をストップ",
                    style: TextStyle(
                      color: Colors.black, // Add style if required
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Server Monitoring")),
      body: const Center(child: Text("Monitoring server for abnormalities...")),
    );
  }
}

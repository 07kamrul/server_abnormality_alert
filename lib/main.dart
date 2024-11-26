import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  runApp(MyApp());
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "checkServer") {
      final response = await http.get(Uri.parse('http://sysadmin-s.colgis.com/api/mail'));
      final int responseValue = int.parse(response.body);

      if (response.statusCode == 200 && responseValue == 1) {
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MonitoringScreen(),
    );
  }
}

class MonitoringScreen extends StatefulWidget {
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

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final response = await http.get(Uri.parse('http://sysadmin-s.colgis.com/api/mail'));
      final int responseValue = int.parse(response.body);

      if (response.statusCode == 200 && responseValue == 1) {
        _playAlert();
        _showAlertDialog();
      }
    });
  }

  void _playAlert() async {
    await _audioPlayer.play(AssetSource('assets/Warning-Siren01-1.mp3'));
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: const Text("An abnormality has been detected. Please check your email."),
          actions: [
            TextButton(
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
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

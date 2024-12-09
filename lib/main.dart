import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:vibration/vibration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: "server_monitoring_channel",
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

void onStart(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final response = await http.get(Uri.parse('http://sysadmin-s.colgis.com/api/mail'));
    final int responseValue = int.parse(response.body);

    if (response.statusCode == 200 && responseValue == 0) {
      await _playAlert();
      _showAlertDialog(service);
    }
  });
}

Future<void> _playAlert() async {
  final audioPlayer = AudioPlayer();
  await audioPlayer.play(AssetSource('audio/Warning-Siren01-1.mp3'));
  // Dispose the player when done (optional)
  // await audioPlayer.dispose();
}

void _showAlertDialog(ServiceInstance service) {
  // Ensure we use the service to send data and show dialog correctly
  showDialog(
    context: navigatorKey.currentContext!,
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
        content: const Text(
          "至急、サーバー異常検知メールを確認して、サーバー管理者に電話連絡をして下さい。",
          style: TextStyle(fontSize: 20, color: Colors.blue),
        ),
        actions: [
          TextButton(
            onPressed: () {
              navigatorKey.currentState!.pop();
              // Send data to stop alert when OK is pressed using invoke method
              service.invoke("stop_alert");
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
                  "をクリックして警告音をストップ",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

// Global key for accessing the navigator from the service
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text("Server Monitoring")),
        body: const Center(child: Text("Monitoring server for abnormalities...")),
      ),
    );
  }
}

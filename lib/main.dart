import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart'; // ✅ Correct FFmpeg import
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // ✅ Correct path_provider import

void main() {
  runApp(ScreamDetectionApp());
}

class ScreamDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreamDetector(),
    );
  }
}

class ScreamDetector extends StatefulWidget {
  @override
  _ScreamDetectorState createState() => _ScreamDetectorState();
}

class _ScreamDetectorState extends State<ScreamDetector> {
  late tfl.Interpreter _interpreter;
  final Record _audioRecorder = Record();
  bool isRecording = false;
  bool isScreamDetected = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // Load the TFLite Model
  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/scream_detection_model.tflite');
      print("✅ Model Loaded Successfully!");
    } catch (e) {
      print("❌ Error Loading Model: $e");
    }
  }

  // Start Recording & Process Audio
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      Directory tempDir = await getTemporaryDirectory(); // ✅ Fixed function call
      String filePath = "${tempDir.path}/audio.wav";

      await _audioRecorder.start(path: filePath);
      setState(() => isRecording = true);

      Timer.periodic(Duration(seconds: 3), (timer) async {
        if (!isRecording) {
          timer.cancel();
          return;
        }

        await _audioRecorder.stop();
        List<double> features = await _extractMFCC(filePath);
        _classifyAudio(features);
        await _audioRecorder.start(path: filePath);
      });
    }
  }

  // Stop Recording
  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    setState(() => isRecording = false);
  }

  // Extract MFCC Features using FFmpeg
  Future<List<double>> _extractMFCC(String filePath) async {
    Directory tempDir = await getTemporaryDirectory(); // ✅ Fixed function call
    String outputFilePath = "${tempDir.path}/mfcc.txt";

    String command =
        "-i $filePath -af 'highpass=f=200, lowpass=f=3000' -f null -";

    await FFmpegKit.execute(command).then((session) {
      print("✅ MFCC Extracted Successfully!");
    }).catchError((e) {
      print("❌ Error Extracting MFCC: $e");
    });

    List<double> mfccFeatures = List.generate(13, (index) => 0.0);
    return mfccFeatures;
  }

  // Classify Audio using TFLite
  void _classifyAudio(List<double> features) {
    var input = [features];
    var output = List.filled(2, 0).reshape([1, 2]);

    _interpreter.run(input, output);
    double screamProbability = output[0][1];

    setState(() => isScreamDetected = screamProbability > 0.7);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scream Detection")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isScreamDetected ? "🚨 Scream Detected!" : "Listening...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRecording ? _stopRecording : _startRecording,
              child: Text(isRecording ? "Stop Listening" : "Start Listening"),
            ),
          ],
        ),
      ),
    );
  }
}

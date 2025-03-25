import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ScreamDetector {
  late Interpreter _interpreter;

  /// Load the TensorFlow Lite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/scream_detection_model.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  /// Process audio data and predict if it's a scream
  List<double> processAudio(Uint8List audioData) {
    // Convert Uint8List to List<double>
    List<double> input = audioData.map((e) => e.toDouble()).toList();

    // Ensure input size matches model's expected shape (e.g., 16000 samples)
    input = input.length > 16000 ? input.sublist(0, 16000) : input;

    // Prepare output
    var output = List.filled(2, 0.0).reshape([1, 2]);

    // Run inference
    _interpreter.run(input, output);

    return output[0];  // Probabilities for [non-scream, scream]
  }
}

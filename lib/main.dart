import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;

void main() {
  runApp(const CoffeeDiseaseApp());
}

class CoffeeDiseaseApp extends StatelessWidget {
  const CoffeeDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Leaf Disease Detector',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const CoffeeScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CoffeeScannerScreen extends StatefulWidget {
  const CoffeeScannerScreen({super.key});

  @override
  State<CoffeeScannerScreen> createState() => _CoffeeScannerScreenState();
}

class _CoffeeScannerScreenState extends State<CoffeeScannerScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String _predictionResult = '';
  String _confidenceResult = '';
  Interpreter? _interpreter;

  // The 5 disease classes matching your trained model outputs
  final List<String> _classes = ["Cercospora", "Healthy", "Leaf rust", "Miner", "Phoma"];

  @override
  void initState() {
    super.initState();
    _loadOfflineModel(); // Initialize local model weights on startup
  }

  @override
  void dispose() {
    _interpreter?.close(); // Free device execution registers safely
    super.dispose();
  }

  // Load the offline TFLite model from local assets
  Future<void> _loadOfflineModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/coffee_disease_model.tflite');
      if (kDebugMode) print("✅ TFLite Model initialized successfully for Offline use!");
    } catch (e) {
      if (kDebugMode) print("❌ Error initializing offline model: $e");
    }
  }

  // Pick an image asset from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _predictionResult = '';
        _confidenceResult = '';
      });
      await _runOfflineInference(bytes); // Run calculation locally
    }
  }

  // Core offline machine learning engine running completely on-device CPU
  Future<void> _runOfflineInference(Uint8List imageBytes) async {
    if (_interpreter == null) {
      setState(() => _predictionResult = "Error: Offline Model not ready!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Decode source image bytes into an image layout matrix
      img_lib.Image? originalImage = img_lib.decodeImage(imageBytes);
      if (originalImage == null) throw Exception("Decoding failed");

      // Resize layout to match your model's input tensor constraints (128x128)
      img_lib.Image resizedImage = img_lib.copyResize(originalImage, width: 128, height: 128);

      // Structure normalized Float32 values into a 4D tensor matrix array
      var input = List.generate(
        1,
        (i) => List.generate(
          128,
          (y) => List.generate(
            128,
            (x) {
              var pixel = resizedImage.getPixel(x, y);
              // Secure channel extraction matching older and newer image package properties
              double r = (pixel.r as num).toDouble() / 255.0;
              double g = (pixel.g as num).toDouble() / 255.0;
              double b = (pixel.b as num).toDouble() / 255.0;
              return [r, g, b];
            },
          ),
        ),
      );

      // Allocate output buffer data matrix matching configuration bounds
      var output = List.filled(1, List.filled(_classes.length, 0.0));
      
      // Run math calculations directly inside native application boundaries
      _interpreter!.run(input, output);

      // Argmax evaluation to find the category with maximum score probabilities
      List<dynamic> outerList = output[0];
      List<double> finalPredictions = outerList.map((e) => (e as num).toDouble()).toList();
      
      double maxScore = -1.0;
      int bestIndex = 0;

      for (int i = 0; i < finalPredictions.length; i++) {
        if (finalPredictions[i] > maxScore) {
          maxScore = finalPredictions[i];
          bestIndex = i;
        }
      }

      setState(() {
        _predictionResult = _classes[bestIndex];
        _confidenceResult = '${(maxScore * 100).toStringAsFixed(1)}%';
      });
    } catch (e) {
      setState(() {
        _predictionResult = 'Offline Analysis Failed';
        _confidenceResult = '0%';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Leaf Disease Detector'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        // Solid professional color to maintain true offline stability
        color: const Color(0xFFEFEBE9), 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Box Container
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF8D6E63), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.coffee, size: 70, color: Color(0xFF6F4E37)),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Select a coffee leaf image\n(Works Completely Offline!)',
                                style: TextStyle(fontSize: 15, color: Color(0xFF4A3525), fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // UI Entry Buttons layout mapping section
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text('Camera', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      label: const Text('Gallery', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Progress state tracking elements
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF6F4E37)),
                      SizedBox(height: 12),
                      Text(
                        'Predicting Leaf Disease...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A3525)),
                      ),
                    ],
                  ),
                ),

              // Output Predictions results UI block card mapping
              if (_predictionResult.isNotEmpty && !_isLoading)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Analysis Result',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),

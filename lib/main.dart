import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  // Backend API URL (ተስተካክሎ ገብቷል)
  final String apiUrl = 'https://opulent-space-adventure-r4wxjw64599pc5pwr-8000.app.github.dev/predict';

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _predictionResult = '';
        _confidenceResult = '';
      });
      await _sendImageToBackend(bytes, pickedFile.name);
    }
  }

  // Send image to backend and get prediction
  Future<void> _sendImageToBackend(Uint8List bytes, String fileName) async {
    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse(apiUrl);
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: fileName.isNotEmpty ? fileName : 'coffee_leaf.jpg',
        ),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        
        String detectedClass = responseData['class'] ?? responseData['prediction'] ?? 'Not Found';
        
        var confidenceRaw = responseData['confidence'] ?? responseData['probability'] ?? 0.0;
        String confidenceStr = '';
        if (confidenceRaw is double || confidenceRaw is int) {
          double val = confidenceRaw <= 1.0 ? confidenceRaw * 100 : confidenceRaw;
          confidenceStr = '${val.toStringAsFixed(1)}%';
        } else {
          confidenceStr = confidenceRaw.toString();
        }

        setState(() {
          _predictionResult = detectedClass;
          _confidenceResult = confidenceStr;
        });
      } else {
        setState(() {
          _predictionResult = 'Server Error (Status: ${response.statusCode})';
          _confidenceResult = '0%';
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'Connection Error Occurred';
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
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=1000&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview Box
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
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
                                'Take a photo or select a coffee leaf from gallery',
                                style: TextStyle(fontSize: 15, color: Color(0xFF4A3525), fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Camera and Gallery Buttons
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

              // Loading Indicator
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Processing Prediction...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),

              // Result Display Card
              if (_predictionResult.isNotEmpty && !_isLoading)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Diagnosis Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const Divider(thickness: 1.5, color: Color(0xFF8D6E63)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.eco, color: Color(0xFFD32F2F), size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Disease: $_predictionResult',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF1976D2), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: $_confidenceResult',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
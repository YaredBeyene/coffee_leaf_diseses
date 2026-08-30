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
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const CoffeeHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CoffeeHomeScreen extends StatefulWidget {
  const CoffeeHomeScreen({super.key});

  @override
  State<CoffeeHomeScreen> createState() => _CoffeeHomeScreenState();
}

class _CoffeeHomeScreenState extends State<CoffeeHomeScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String _resultText = '';
  String _remedyText = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _resultText = '';
        _remedyText = '';
      });
      _sendImageToBackend(bytes);
    }
  }

  Future<void> _sendImageToBackend(Uint8List bytes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Your backend URL on port 8000
      var uri = Uri.parse('https://opulent-space-adventure-4rwxjw64599pc5pwr-8000.app.github.dev/predict');
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'coffee_leaf.jpg'));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResult = json.decode(responseData);
        setState(() {
          _resultText = "Disease: ${jsonResult['class'] ?? 'Unknown'} (Confidence: ${jsonResult['confidence'] ?? '0%'})";
          _remedyText = jsonResult['remedy'] ?? 'መፍትሄ አልተገኘም';
        });
      } else {
        setState(() {
          _resultText = 'የሰርቨር ስህተት ተፈጥሯል (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _resultText = 'ግንኙነት አልተሳካም: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('የቡና ቅጠል በሽታ መለያ'),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Text(
                        'እባክዎ የቡና ቅጠል ፎቶ ይምረጡ',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('ፎቶ ከጋለሪ ይምረጡ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_resultText.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'የምርመራ ውጤት (Result):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(_resultText, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      const Text(
                        'የሚሰጥ መፍትሄ (Remedy):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      const SizedBox(height: 8),
                      Text(_remedyText, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
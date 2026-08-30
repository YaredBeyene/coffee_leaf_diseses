import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coffee Disease Detection',
      theme: ThemeData(primarySwatch: Colors.green),
      home: CoffeeDiseaseScreen(),
    );
  }
}

class CoffeeDiseaseScreen extends StatefulWidget {
  @override
  _CoffeeDiseaseScreenState createState() => _CoffeeDiseaseScreenState();
}

class _CoffeeDiseaseScreenState extends State<CoffeeDiseaseScreen> {
  File? _image;
  String _result = "";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // 1. Function to pick an image from Camera or Gallery
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = ""; // Clear previous results when a new image is selected
      });
    }
  }

  // 2. Function to send the image to the FastAPI backend server
  Future<void> sendImageToAPI() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    // Your actual GitHub Codespaces Public URL is added here automatically!
    var url = Uri.parse('https://opulent-space-adventure-r4wxjw64599pc5pwr-5000.app.github.dev/predict');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResult = json.decode(responseData);
        
        setState(() {
          _result = "Disease: ${jsonResult['class']}\nConfidence: ${jsonResult['confidence']}%";
        });
      } else {
        setState(() {
          _result = "Error: Failed to get prediction from server.";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error: $e";
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
      appBar: AppBar(title: Text('Coffee Leaf Disease Detection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview selected image or show placeholder text
            _image == null
                ? Text('No image selected.', style: TextStyle(fontSize: 16))
                : Image.file(_image!, height: 200, width: 200, fit: BoxFit.cover),
            
            SizedBox(height: 20),

            // Buttons for Camera and Gallery selection
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image),
                  label: Text('Gallery'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Button to trigger disease prediction
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : sendImageToAPI,
              child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Text('Predict Disease'),
            ),

            SizedBox(height: 30),

            // Display result text
            Text(
              _result,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'form_renderer.dart';

class FormProcessorScreen extends StatefulWidget {
  final File image; // Image received from the main screen

  const FormProcessorScreen({Key? key, required this.image}) : super(key: key);

  @override
  State<FormProcessorScreen> createState() => _FormProcessorScreenState();
}

class _FormProcessorScreenState extends State<FormProcessorScreen> {
  File? _image; // Image to be displayed and processed
  Map<String, dynamic>? _formStructure;
  bool _isProcessing = true;
  String _statusMessage = "Processing image...";

  @override
  void initState() {
    super.initState();
    _image = widget.image; // Assign the received image to the state
    _sendImageToXAI(); // Start processing automatically
  }

  Future<void> _sendImageToXAI() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    const String apiUrl = "https://api.x.ai/v1/chat/completions";
    const String apiKey =
        "xai-Ka81XhLcOHPKYhaPCtcu5uvbadA5Pe9YnbL3dINEB0JjVIMwUC1iVwUSpbMCc0iYlnlSmiKHpIkUTeRt"; // Replace this with your API key.

    try {
      // Encode the image to Base64
      String base64Image = base64Encode(await _image!.readAsBytes());

      // Create the request body
      Map<String, dynamic> requestBody = {
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/png;base64,$base64Image",
                  "detail": "high",
                },
              },
              {
                "type": "text",
                "text": "Analyze the attached image and return a JSON representing the entire form structure. "
                    "The JSON should include the document's title, sections, subtitles, and fields. "
                    "Each field must include its type, label, and additional details. "
                    "For fields like checkboxes, dropdowns, or radio buttons, also include the list of available options. "
                    "The JSON format should be: "
                    "{ "
                    "\"title\": \"Document Title\", "
                    "\"sections\": [ "
                    "{ "
                    "\"title\": \"Section Title\", "
                    "\"subtitle\": \"Optional Section Subtitle\", "
                    "\"fields\": [ "
                    "{ \"type\": \"text\", \"label\": \"Text Field Label\" }, "
                    "{ \"type\": \"number\", \"label\": \"Number Field Label\" }, "
                    "{ \"type\": \"checkbox\", \"label\": \"Checkbox Label\", \"options\": [\"Option 1\", \"Option 2\"] }, "
                    "{ \"type\": \"dropdown\", \"label\": \"Dropdown Label\", \"options\": [\"Option A\", \"Option B\"] } "
                    "] "
                    "} "
                    "] "
                    "}. Ensure the JSON accurately reflects the document's structure and content."
              },
            ],
          },
        ],
        "model": "grok-vision-beta",
        "temperature": 0.2,
      };

      // Send the request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(requestBody),
      );

      // Debugging response
      print("Full API response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Validate if the response contains the expected data
        if (responseData != null &&
            responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          final rawContent = responseData['choices'][0]['message']['content'];

          // Extract JSON from content
          final extractedJson = _extractJsonFromContent(rawContent);

          if (extractedJson != null) {
            setState(() {
              _formStructure = extractedJson;
              _isProcessing = false;
            });

            // Navigate to the form screen
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FormRendererScreen(formStructure: _formStructure!),
                ),
              );
            }
          } else {
            print("Failed to extract JSON from content.");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Failed to extract JSON from content.")),
            );
          }
        } else {
          print("The response does not contain the expected data.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("The API response is invalid.")),
          );
        }
      } else {
        print("Request error: ${response.statusCode} ${response.reasonPhrase}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error: ${response.statusCode} ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print("Error processing the request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing the request: $e")),
      );
    }
  }

  // Method to extract JSON from content
  Map<String, dynamic>? _extractJsonFromContent(String content) {
    try {
      // Find the start and end of the JSON block
      final startIndex = content.indexOf('```json') + 7;
      final endIndex = content.lastIndexOf('```');

      if (startIndex > 6 && endIndex > startIndex) {
        final jsonString = content.substring(startIndex, endIndex).trim();
        return jsonDecode(jsonString);
      } else {
        print("No valid JSON block found.");
        return null;
      }
    } catch (e) {
      print("Error extracting or decoding JSON: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Digitization")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isProcessing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 6.0,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (_image != null) ...[
                    Image.file(
                      _image!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ] else ...[
                    const Text("No image loaded."),
                  ],
                ],
              ),
      ),
    );
  }
}

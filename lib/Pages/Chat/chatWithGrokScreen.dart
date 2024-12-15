import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatWithGrokScreen extends StatefulWidget {
  const ChatWithGrokScreen({Key? key}) : super(key: key);

  @override
  State<ChatWithGrokScreen> createState() => _ChatWithGrokScreenState();
}

class _ChatWithGrokScreenState extends State<ChatWithGrokScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // Updated to Map<String, dynamic>
  File? _selectedImage;
  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startConversationWithGrok();
  }

  void _startConversationWithGrok() {
    setState(() {
      _messages.add({
        "role": "assistant",
        "content":
            "Hi, I’m Grok, your expert in judicial document creation. How can I assist you today?",
      });
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty && _selectedImage == null) return;

    setState(() {
      if (message.isNotEmpty) {
        _messages.add({"role": "user", "content": message});
      }
      if (_selectedImage != null) {
        _messages.add({
          "role": "user",
          "content": {
            "type": "image_url",
            "image_url": {
              "url": _selectedImage!.path,
              "detail": "local",
            },
          },
        });
      }
      _isLoading = true;
    });

    await _sendToGrok(message);
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message["role"] == "user";
    final bool isImage =
        message["content"] is Map && message["content"]["type"] == "image_url";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isImage
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    const Text(
                      "Image Sent",
                      style: TextStyle(
                          color: Colors.white, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  Image.file(
                    File(message["content"]["image_url"]["url"]),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ],
              )
            : Text(
                message["content"] is Map
                    ? message["content"]["text"] ?? "[Invalid Message]"
                    : message["content"]?.toString() ?? "",
                style: const TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  Future<void> _sendToGrok(String message) async {
    try {
      const String apiUrl = "https://api.x.ai/v1/chat/completions";
      const String apiKey =
          "xai-Ka81XhLcOHPKYhaPCtcu5uvbadA5Pe9YnbL3dINEB0JjVIMwUC1iVwUSpbMCc0iYlnlSmiKHpIkUTeRt";

      // Encode the image to Base64 if available
      String? base64Image;
      if (_selectedImage != null) {
        base64Image = base64Encode(await _selectedImage!.readAsBytes());
      }

      // Build the content payload
      List<Map<String, dynamic>> contentPayload = [];

      if (base64Image != null) {
        contentPayload.add({
          "type": "image_url",
          "image_url": {
            "url": "data:image/png;base64,$base64Image",
            "detail": "high",
          },
        });
      }

      if (message.isNotEmpty) {
        contentPayload.add({
          "type": "text",
          "text": message,
        });
      }

      if (contentPayload.isEmpty) {
        _showError("You must provide a message or an image.");
        return;
      }

      Map<String, dynamic> requestBody = {
        "messages": [
          {
            "role": "user",
            "content": contentPayload,
          },
        ],
        "model": "grok-vision-beta",
        "temperature": 0.2,
      };

      // Log request body for debugging
      print("Request Body: ${jsonEncode(requestBody)}");

      // Send the API request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(requestBody),
      );

      // Log the raw response
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty) {
          setState(() {
            _messages.add({
              "role": "assistant",
              "content": responseData['choices'][0]['message']['content'],
            });
          });
        } else {
          _showError("Unexpected response from Grok.");
        }
      } else {
        _showError("Error ${response.statusCode}: ${response.reasonPhrase}");
      }
    } on FormatException catch (e) {
      print("FormatException: $e");
      _showError("Failed to parse the response from Grok.");
    } catch (e, stackTrace) {
      print("Error: $e\nStack Trace: $stackTrace");
      _showError("An unexpected error occurred.");
    } finally {
      setState(() {
        _isLoading = false;
        _selectedImage = null; // Clear the image after sending
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    print(message);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Grok"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image, color: Colors.blue),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                  ),
                  onSubmitted: (value) {
                    _sendMessage(value);
                    _messageController.clear();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                onPressed: () {
                  _sendMessage(_messageController.text);
                  _messageController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DocumentFillScreen extends StatefulWidget {
  const DocumentFillScreen({Key? key}) : super(key: key);

  @override
  State<DocumentFillScreen> createState() => _DocumentFillScreenState();
}

class _DocumentFillScreenState extends State<DocumentFillScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fill Document"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('documents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No documents available to fill."),
            );
          }
          final documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(document['title'] ?? 'Untitled Document'),
                  subtitle: Text(
                      "Created by: ${document['createdBy']['name'] ?? 'Unknown'}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentFormScreen(
                          documentData: document.data() as Map<String, dynamic>,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DocumentFormScreen extends StatefulWidget {
  final Map<String, dynamic> documentData;

  const DocumentFormScreen({Key? key, required this.documentData})
      : super(key: key);

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final Map<String, dynamic> filledData = {};
  final Map<String, List<String>> suggestions = {};
  final Map<String, TextEditingController> controllers = {};
  final Map<String, FocusNode> focusNodes = {};
  bool isLoadingSuggestions = false;
  Timer? _debounce;

  final String apiKey =
      "xai-Ka81XhLcOHPKYhaPCtcu5uvbadA5Pe9YnbL3dINEB0JjVIMwUC1iVwUSpbMCc0iYlnlSmiKHpIkUTeRt";
  final String baseUrl = "https://api.x.ai/v1";

  Future<List<String>> fetchSuggestions(String query, String field) async {
    if (query.isEmpty)
      return ['- Default Suggestion 1', '- Default Suggestion 2'];

    try {
      setState(() {
        isLoadingSuggestions = true;
      });

      final response = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "grok-beta",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are an assistant that helps users autocomplete form fields. Always return only specific suggestions for the current input, formatted as a bulleted list where each line starts with a '-' symbol. Do not provide explanations, instructions, or additional text. For example, if the user inputs 'Jo' for a name field, respond with:\n- John\n- Joanna\n- Joseph\nYour suggestions should directly match or extend the user's input."
            },
            {
              "role": "user",
              "content":
                  "Field: '$field'. Input: '$query'. Provide autocomplete suggestions."
            }
          ],
          "max_tokens": 50,
        }),
      );

      setState(() {
        isLoadingSuggestions = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print(content);
        return extractSuggestions(content);
      } else {
        print("Error: ${response.statusCode}");
        return ['- Default Suggestion 1', '- Default Suggestion 2'];
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
      setState(() {
        isLoadingSuggestions = false;
      });
      return ['- Default Suggestion 1', '- Default Suggestion 2'];
    }
  }

  List<String> extractSuggestions(String content) {
    final suggestions = <String>[];
    final lines = content.split("\n");

    for (final line in lines) {
      if (line.trim().startsWith('-')) {
        final suggestion = line.trim().substring(1).trim();
        if (suggestion.isNotEmpty) {
          suggestions.add(suggestion);
        }
      }
    }
    return suggestions;
  }

  void onFieldChanged(String query, String field) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 1) return;

      final fieldSuggestions = await fetchSuggestions(query, field);
      setState(() {
        suggestions[field] = fieldSuggestions;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controllers.forEach((_, controller) => controller.dispose());
    focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentTitle = widget.documentData['title'] ?? 'Untitled Document';
    final sections = widget.documentData['sections'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(documentTitle),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, sectionIndex) {
            final section = sections[sectionIndex];
            final fields = section['fields'] as List<dynamic>? ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['title'] ?? 'Untitled Section',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...fields.map((field) {
                      final fieldType = field['type'] ?? 'text';
                      final fieldLabel = field['label'] ?? 'Field';

                      controllers.putIfAbsent(
                          fieldLabel, () => TextEditingController());
                      focusNodes.putIfAbsent(fieldLabel, () => FocusNode());

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fieldLabel,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            if (fieldType == 'text' || fieldType == 'textarea')
                              Stack(
                                children: [
                                  TextField(
                                    focusNode: focusNodes[fieldLabel],
                                    controller: controllers[fieldLabel],
                                    onChanged: (value) {
                                      filledData[fieldLabel] = value;
                                      onFieldChanged(value, fieldLabel);
                                    },
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: 'Enter $fieldLabel',
                                    ),
                                  ),
                                  if (isLoadingSuggestions)
                                    const Positioned(
                                      right: 10,
                                      top: 10,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  if (suggestions[fieldLabel]?.isNotEmpty ??
                                      false)
                                    Container(
                                      margin: const EdgeInsets.only(top: 60),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.white,
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            suggestions[fieldLabel]?.length ??
                                                0,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(suggestions[
                                                fieldLabel]![index]),
                                            onTap: () {
                                              setState(() {
                                                controllers[fieldLabel]!.text =
                                                    suggestions[fieldLabel]![
                                                        index];
                                                filledData[fieldLabel] =
                                                    suggestions[fieldLabel]![
                                                        index];
                                                suggestions[fieldLabel] = [];
                                              });
                                              focusNodes[fieldLabel]!
                                                  .requestFocus();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Filled Data: $filledData');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}

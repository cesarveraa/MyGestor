import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormRendererScreen extends StatefulWidget {
  final Map<String, dynamic> formStructure;

  const FormRendererScreen({Key? key, required this.formStructure})
      : super(key: key);

  @override
  State<FormRendererScreen> createState() => _FormRendererScreenState();
}

class _FormRendererScreenState extends State<FormRendererScreen> {
  late Map<String, dynamic> editableFormStructure;
  final TextEditingController _documentTitleController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    editableFormStructure = Map<String, dynamic>.from(widget.formStructure);

    // Ensure 'sections' is a mutable list
    editableFormStructure['sections'] ??= [];
    if (editableFormStructure['sections'] is! List) {
      editableFormStructure['sections'] =
          List.from(editableFormStructure['sections']);
    }

    // Initialize the document title
    _documentTitleController.text =
        editableFormStructure['title'] ?? 'Untitled Document';
  }

  void _addSection() {
    setState(() {
      editableFormStructure['sections'] ??= [];
      (editableFormStructure['sections'] as List)
          .add({'title': 'New Section', 'subtitle': '', 'fields': []});
    });
  }

  void _removeSection(int sectionIndex) {
    setState(() {
      editableFormStructure['sections'].removeAt(sectionIndex);
    });
  }

  void _addField(int sectionIndex) {
    setState(() {
      final section = editableFormStructure['sections'][sectionIndex];
      section['fields'] ??= [];
      section['fields'].add({'type': 'text', 'label': 'New Field'});
    });
  }

  void _removeField(int sectionIndex, int fieldIndex) {
    setState(() {
      final section = editableFormStructure['sections'][sectionIndex];
      section['fields'].removeAt(fieldIndex);
    });
  }

  void _addOptionToField(Map<String, dynamic> field) {
    setState(() {
      field['options'] ??= [];
      field['options'].add("New Option");
    });
  }

  Future<void> _saveToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No user logged in!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Fetch user name from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      editableFormStructure['title'] = _documentTitleController.text;

      // Add user information to the document
      editableFormStructure['createdBy'] = {
        'email': user.email,
        'name': userName,
        'uid': user.uid,
      };

      await FirebaseFirestore.instance
          .collection('documents')
          .add(editableFormStructure);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Document saved successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop(); // Redirect to the previous screen
      Navigator.of(context).pop(); // Redirect to home screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save document: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digitalized Form"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _documentTitleController,
              decoration: const InputDecoration(
                labelText: "Document Title",
                labelStyle: TextStyle(color: Colors.blue, fontSize: 18),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              onChanged: (value) => editableFormStructure['title'] = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _buildFormSections(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addSection,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
            heroTag: "addSection",
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _saveToFirestore,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.save, color: Colors.white),
            heroTag: "saveForm",
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormSections() {
    if (editableFormStructure['sections'] == null ||
        editableFormStructure['sections'] is! List) {
      return [
        const Text("No sections found in the form."),
      ];
    }

    List<Widget> sections = [];
    for (int i = 0; i < editableFormStructure['sections'].length; i++) {
      final section = editableFormStructure['sections'][i];

      sections.add(Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: section['title']),
                      decoration: const InputDecoration(
                        labelText: "Section Title",
                        labelStyle: TextStyle(color: Colors.blue),
                      ),
                      onChanged: (value) => section['title'] = value,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeSection(i),
                  ),
                ],
              ),
              TextField(
                controller: TextEditingController(text: section['subtitle']),
                decoration: const InputDecoration(
                  labelText: "Section Subtitle",
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                onChanged: (value) => section['subtitle'] = value,
              ),
              ..._buildFormFields(section['fields'] ?? [], i),
              TextButton(
                onPressed: () => _addField(i),
                child: const Text("Add Field"),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ));
    }
    return sections;
  }

  List<Widget> _buildFormFields(List<dynamic> fieldsList, int sectionIndex) {
    List<Widget> fields = [];
    for (int i = 0; i < fieldsList.length; i++) {
      final field = fieldsList[i];
      fields.add(Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: field['label']),
                      decoration: const InputDecoration(
                        labelText: "Field Label",
                        labelStyle: TextStyle(color: Colors.blue),
                      ),
                      onChanged: (value) => field['label'] = value,
                    ),
                  ),
                  DropdownButton<String>(
                    value: field['type'],
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'number', child: Text('Number')),
                      DropdownMenuItem(
                          value: 'checkbox', child: Text('Checkbox')),
                      DropdownMenuItem(
                          value: 'dropdown', child: Text('Dropdown')),
                      DropdownMenuItem(value: 'radio', child: Text('Radio')),
                      DropdownMenuItem(
                          value: 'textarea', child: Text('Textarea')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        field['type'] = value;
                        if (value == 'checkbox' ||
                            value == 'dropdown' ||
                            value == 'radio') {
                          field['options'] ??=
                              []; // Inicializa opciones si es necesario
                        } else {
                          field.remove(
                              'options'); // Elimina opciones si no son necesarias
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeField(sectionIndex, i),
                  ),
                ],
              ),
              if (field['options'] != null) ...[
                const SizedBox(height: 8),
                ..._buildFieldOptions(field),
                TextButton(
                  onPressed: () => _addOptionToField(field),
                  child: const Text("Add Option"),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ));
    }
    return fields;
  }

  List<Widget> _buildFieldOptions(Map<String, dynamic> field) {
    final options = field['options'] as List<dynamic>;
    List<Widget> optionWidgets = [];
    for (int i = 0; i < options.length; i++) {
      optionWidgets.add(Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: options[i]),
              decoration: InputDecoration(
                labelText: "Option ${i + 1}",
                labelStyle: const TextStyle(color: Colors.blue),
              ),
              onChanged: (value) {
                setState(() {
                  options[i] = value;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                options.removeAt(i);
              });
            },
          ),
        ],
      ));
    }
    return optionWidgets;
  }
}

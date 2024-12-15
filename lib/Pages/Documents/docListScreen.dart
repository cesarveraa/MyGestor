import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mygestor/Pages/form_process/form_renderer.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({Key? key}) : super(key: key);

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final CollectionReference _documentsRef =
      FirebaseFirestore.instance.collection('documents');

  // Método para eliminar un documento
  Future<void> _deleteDocument(String docId) async {
    await _documentsRef.doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Document deleted successfully!"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Método para redirigir a la pantalla de edición
  void _editDocument(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormRendererScreen(formStructure: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Documents"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _documentsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No documents found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final docData = doc.data() as Map<String, dynamic>;
              final docTitle = docData['title'] ?? 'Untitled Document';

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    docTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: Text(
                    "Last updated: ${doc.metadata.hasPendingWrites ? 'Now' : 'Synced'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editDocument(doc.id, docData),
                        tooltip: "Edit Document",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteDocument(doc.id),
                        tooltip: "Delete Document",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

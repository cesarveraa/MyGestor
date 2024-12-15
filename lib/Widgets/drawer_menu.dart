import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mygestor/Pages/Chat/chatWithGrokScreen.dart';
import 'package:mygestor/Pages/Documents/docListScreen.dart';
import 'package:mygestor/Pages/form_process/form_renderer.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey[800],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey[700],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[400],
                    backgroundImage: userData?['profileImage'] != null
                        ? NetworkImage(userData!['profileImage'])
                        : null,
                    child: userData?['profileImage'] == null
                        ? const Icon(Icons.person,
                            size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData?['name'] ?? 'Name unavailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData?['email'] ?? 'Email unavailable',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text(
                'New',
                style: TextStyle(color: Colors.white),
              ),
              tileColor: Colors.grey[900],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormRendererScreen(
                      formStructure: {
                        'sections': <Map<String,
                            dynamic>>[], // Ensure it's a mutable list
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Documents',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DocumentListScreen()),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Chat',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatWithGrokScreen()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

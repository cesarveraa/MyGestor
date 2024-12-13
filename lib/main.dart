import 'package:mygestor/Pages/Auth/login.dart';
import 'package:mygestor/Pages/Auth/signup.dart';
import 'package:mygestor/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mygestor/pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _checkAndRequestCameraPermission();

  runApp(const MyApp());
}

Future<void> _checkAndRequestCameraPermission() async {
  // Verificar si el permiso de cámara está otorgado
  if (await Permission.camera.isDenied) {
    // Solicitar el permiso
    PermissionStatus status = await Permission.camera.request();

    // Verificar si el permiso fue otorgado
    if (!status.isGranted) {
      throw Exception('Permiso de cámara denegado.');
    }
  } else if (await Permission.camera.isPermanentlyDenied) {
    // Abrir la configuración para habilitar manualmente
    throw Exception('Permiso de cámara permanentemente denegado. Por favor, habilítalo desde la configuración de tu dispositivo.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenfield',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Determinar la pantalla inicial
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificar si hay un usuario autenticado
    final user = FirebaseAuth.instance.currentUser;

    // Si el usuario está autenticado, redirigir a HomePage; de lo contrario, a LoginView
    if (user != null) {
      return const HomePage();
    } else {
      return const LoginView();
    }
  }
}
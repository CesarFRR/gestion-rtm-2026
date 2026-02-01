import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante
import 'firebase_options.dart';
import 'services/auth_service.dart'; // Importante
import 'pages/dashboard_page.dart';
import 'pages/auth_page.dart'; // Tu página de Login

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión RTM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // Definimos rutas para poder navegar fácilmente al inicio
      initialRoute: '/',
      routes: {'/': (context) => const AuthGate()},
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // 1. Esperando conexión (opcional: mostrar loader)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Si hay datos (usuario logueado), vamos al Dashboard
        if (snapshot.hasData) {
          return const DashboardPage();
        }

        // 3. Si no hay datos (no logueado), vamos al Login
        return const AuthPage();
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Stream para escuchar cambios en la autenticación (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  get currentUser => _auth.currentUser;

  // 1. Método para verificar si el correo está en la lista de permitidos
  Future<bool> verificarAcceso(String? email) async {
    if (email == null) return false;
    try {
      final doc = await _db.collection('usuarios_autorizados').doc(email).get();
      return doc.exists;
    } catch (e) {
      // ignore: avoid_print
      print("Error en Whitelist: $e");
      return false;
    }
  }

  // 2. Iniciar Sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      // CORREGIDO: usa .signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado GoogleAuth: $e');
    }
  }

  // 3. Registrar con Email
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error al registrar: ${e.message}');
    }
  }

  // 4. Iniciar sesión con Email
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Error de inicio de sesión: ${e.message}');
    }
  }

  // 5. Cerrar Sesión
  Future<void> signOut() async {
    try {
      // Verificamos si el usuario actual usó Google antes de desloguear de Firebase
      final user = _auth.currentUser;
      final isGoogleUser =
          user?.providerData.any((info) => info.providerId == 'google.com') ??
          false;

      await _auth.signOut();

      // Solo intentamos cerrar sesión en Google si el proveedor era google.com
      if (isGoogleUser) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error al cerrar sesión: $e");
    }
  }
}

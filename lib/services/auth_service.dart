import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Instancias de Firebase Auth y Google Sign In
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Método para iniciar sesión con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de inicio de sesión de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // 2. Obtener los detalles de autenticación (tokens)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear una Credencial de Firebase usando los tokens de Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con la credencial
      return await _auth.signInWithCredential(credential);

    } catch (e) {
      print("Error durante Google Sign-In: $e");
      return null;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
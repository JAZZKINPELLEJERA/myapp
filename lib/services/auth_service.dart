
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn(String email, String password) async {
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signUp(
    String email,
    String password,
    String storeName,
    String ownerName,
  ) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // TODO: Save storeName and ownerName to Firestore
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

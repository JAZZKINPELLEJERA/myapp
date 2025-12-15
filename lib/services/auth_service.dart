
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    // 1. Create the user with Firebase Auth
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User? user = result.user;

    // 2. Save the additional user info to Firestore
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'storeName': storeName,
        'ownerName': ownerName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Re-authenticate the user before changing the password
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // If re-authentication is successful, update the password
      await user.updatePassword(newPassword);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // It's good practice to delete user data from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      // Then delete the auth user
      await user.delete();
    }
  }
}

import 'package:chatapp/service/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;

  Future googleLogin() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      _user = googleUser;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      User user =
          (await FirebaseAuth.instance.signInWithCredential(credential)).user!;
      if (user != null) {
        String fullName = user.displayName.toString();
        String email = user.email.toString();
        await DatabaseService(uid: user.uid).savingUserData(fullName, email);
        return true;
      }
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}

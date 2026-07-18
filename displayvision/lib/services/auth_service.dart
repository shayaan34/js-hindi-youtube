import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/models.dart';

/// Authentication facade. [MockAuthService] powers demo mode;
/// [FirebaseAuthService] is used when AppConfig.useFirebase is true.
abstract class AuthService {
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register(String name, String company, String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (password.length < 6) {
      throw Exception('Invalid credentials. Password must be 6+ characters.');
    }
    return AppUser(
      uid: 'demo-user',
      name: email.split('@').first,
      email: email,
      company: 'DisplayVision Demo Co.',
    );
  }

  @override
  Future<AppUser> register(
      String name, String company, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return AppUser(uid: 'demo-user', name: name, email: email, company: company);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const AppUser(
      uid: 'demo-google-user',
      name: 'Demo Sales Rep',
      email: 'rep@displayvision.demo',
      company: 'DisplayVision Demo Co.',
    );
  }

  @override
  Future<void> signOut() async {}
}

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AppUser _map(fb.User user, {String? name, String? company}) => AppUser(
        uid: user.uid,
        name: name ?? user.displayName ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        company: company ?? '',
        photoUrl: user.photoURL,
      );

  @override
  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _map(cred.user!);
  }

  @override
  Future<AppUser> register(
      String name, String company, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);
    return _map(cred.user!, name: name, company: company);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _map(cred.user!);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

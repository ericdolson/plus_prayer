import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plusprayer/models/user.dart';
import 'package:plusprayer/services/firebase.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum LoggingInWith {
  anonymous('Signing in as guest'),
  apple('Signing in with Apple'),
  google('Signing in with Google');

  final String label;

  const LoggingInWith(this.label);
}

AuthState useAuth() {
  useListenable(authState);
  return authState;
}

class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoggingIn = false;
  LoggingInWith? _loggingInWith;

  bool get isLoggedIn {
    return _isLoggedIn;
  }

  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  bool get isLoggingIn {
    return _isLoggingIn;
  }

  set isLoggingIn(bool value) {
    _isLoggingIn = value;
    notifyListeners();
  }

  LoggingInWith? get loggingInWith {
    return _loggingInWith;
  }

  set loggingInWith(LoggingInWith? value) {
    _loggingInWith = value;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    isLoggingIn = false;

    // Remove the FCM token to stop receiving notifications
    // Only wait up to one second to avoid blocking the UI
    PPFirebase.removeCurrentFCMToken().timeout(1.seconds).then((_) {
      FirebaseAuth.instance.signOut();
    });
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      loggingInWith = LoggingInWith.google;

      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // If user cancels the sign-in flow
      if (googleUser == null) {
        isLoggingIn = false;
        return AuthResult(success: false, errorMessage: 'User cancelled sign-in');
      }

      isLoggingIn = true;

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final signInResult = await FirebaseAuth.instance.signInWithCredential(credential);

      // signInResult.additionalUserInfo?.profile?.forEach((key, value) {
      //   print('$key: $value');
      // });

      if (signInResult.additionalUserInfo?.isNewUser ?? false) {
        final newUserData = NewUserData(
          givenName: signInResult.additionalUserInfo?.profile?['given_name'],
          familyName: signInResult.additionalUserInfo?.profile?['family_name'],
          email: signInResult.additionalUserInfo?.profile?['email'],
        );

        await PPFirebase.createUserNode(newUserData: newUserData, authUser: signInResult.user!);
      }

      isLoggedIn = true;
      return AuthResult(success: true);
    } catch (e) {
      isLoggingIn = false;
      return AuthResult(success: false, errorMessage: 'Google sign-in failed: ${e.toString()}');
    }
  }

  Future<AuthResult> signInWithApple() async {
    try {
      loggingInWith = LoggingInWith.apple;

      // Get Apple sign-in credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      isLoggingIn = true;

      if (appleCredential.identityToken == null) {
        isLoggingIn = false;
        return AuthResult(
            success: false, errorMessage: 'Apple sign-in failed - no identity token returned');
      }

      // Create OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
      );

      final signInResult = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // signInResult.additionalUserInfo?.profile?.forEach((key, value) {
      //   print('$key: $value');
      // });

      if (signInResult.additionalUserInfo?.isNewUser ?? false) {
        final newUserData = NewUserData(
          givenName: appleCredential.givenName,
          familyName: appleCredential.familyName,
          email: appleCredential.email,
        );

        await PPFirebase.createUserNode(newUserData: newUserData, authUser: signInResult.user!);
      }

      isLoggedIn = true;
      return AuthResult(success: true);
    } catch (e) {
      isLoggingIn = false;
      return AuthResult(success: false, errorMessage: 'Apple sign-in failed: ${e.toString()}');
    }
  }

  Future<AuthResult> signInAnonymously() async {
    try {
      loggingInWith = LoggingInWith.anonymous;
      isLoggingIn = true;
      final signInResult = await FirebaseAuth.instance.signInAnonymously();
      await PPFirebase.createUserNode(authUser: signInResult.user!, newUserData: NewUserData());
      isLoggedIn = true;
      return AuthResult(success: true);
    } catch (e) {
      isLoggingIn = false;
      return AuthResult(success: false, errorMessage: 'Anonymous sign-in failed: ${e.toString()}');
    }
  }
}

final authState = AuthState();

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult({required this.success, this.errorMessage});
}

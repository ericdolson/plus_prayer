import 'package:firebase_auth/firebase_auth.dart';
import 'package:plusprayer/utils/const.dart';

class PPUser {
  final User? authUser;
  final String? email;
  final String? familyName;
  final String? givenName;
  final bool isPremium;
  final int v;

  PPUser({
    this.authUser,
    this.email,
    this.familyName,
    this.givenName,
    this.isPremium = false,
    this.v = currentUserVersion,
  });

  String? get emailFromDataOrUser {
    return email ?? authUser?.email;
  }

  get hasGivenName => givenName != null;

  get hasFamilyName => familyName != null;

  get hasEmail => email != null;

  get isAnonymous => authUser?.isAnonymous ?? true;

  get isLoggedIn => authUser != null;
}

class NewUserData {
  final String? givenName;
  final String? familyName;
  final String? email;

  NewUserData({
    this.givenName,
    this.familyName,
    this.email,
  });

  @override
  String toString() {
    return 'NewUserData(givenName: $givenName, familyName: $familyName, email: $email)';
  }
}

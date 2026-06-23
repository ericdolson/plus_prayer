import 'package:firebase_auth/firebase_auth.dart';


class _Auth {
  bool _isInitting = false;

  init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        print('User is currently signed out!');
        // FirebaseAuth.instance.signInAnonymously();
      } else {
        FirebaseAuth.instance.signOut();
        // var {  } = user;
        print('User is signed in! ${user.uid} ${user.isAnonymous}');

        // FirebaseDatabase database = FirebaseDatabase.instance;
        // var exercisesSnapshot = await database.ref('exercises').get();
        // print(exercisesSnapshot.value);
      }
    });
  }

  _init() async {
    if (_isInitting) {
      print('Already initting');
      return;
    }

    _isInitting = true;

    if (FirebaseAuth.instance.currentUser == null) {
      try {
        print('AUTH: singing in anonymously');
        await FirebaseAuth.instance.signInAnonymously();
        // await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'olson.ericd@gmail.com', password: 'raraHammock&\$1');
        print('Now logged in userId ${FirebaseAuth.instance.currentUser!.uid} and ${FirebaseAuth.instance.currentUser!.isAnonymous ? 'is' : 'is not'} anonymous');
      } catch (e) {
        print('AUTH: error while singing in anonymously: $e');
      }
    } else {
      print('Already logged in userId ${FirebaseAuth.instance.currentUser!.uid} and ${FirebaseAuth.instance.currentUser!.isAnonymous ? 'is' : 'is not'} anonymous');
    }

    _isInitting = false;
  }

  // init2() async {
  //     await _init();
  //
  //     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
  //       print('result ${result.toString()}');
  //
  //       if (result == ConnectivityResult.none) {
  //         print('NOT CONNECTED');
  //       } else {
  //         print('CONNECTED');
  //         _init();
  //       }
  //     });
  // }

  signOut() async {
    await FirebaseAuth.instance.signOut();
    print('Signed out');
  }
}

final zerosAuth = _Auth();

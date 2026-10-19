import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/widgets/auth/auth_buttons.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/screens/auth/anonymous_login_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends HookWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = useRef(GoRouter.of(context));
    final auth = useAuth();

    useEffect(() {
      if (auth.isLoggedIn) {
        if (FirebaseAuth.instance.currentUser == null) {
          auth.isLoggedIn = false;
          auth.isLoggingIn = false;
          return;
        }
        // Navigate after successful login
        Future.delayed(const Duration(milliseconds: 1000), () async {
          final preferencesStore = await SharedPreferences.getInstance();
          final hadFirstRun = preferencesStore.getBool('hadFirstRun') ?? false;

          if (!hadFirstRun) {
            print('not had first run');
            preferencesStore.setBool('hadFirstRun', true);
            navigator.value.go('/firstRun');
            return;
          }

          navigator.value.go('/names');
        });
      }

      return null;
    }, [auth.isLoggedIn]);

    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: remoteAppImgProvider(AppImageType.loginBg),
              fit: BoxFit.cover, // Or BoxFit.fill / contain / fitHeight, etc.
              alignment: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    child: Opacity(
                        opacity: auth.isLoggingIn ? 0 : 1,
                        child: IconButton.filled(
                            onPressed: auth.isLoggingIn
                                ? null
                                : () async {
                                    HapticFeedback.selectionClick();
                                    showAnonymousLoginSheet(context);
                                    // await auth.signInAnonymously();
                                  },
                            icon: Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: .22),
                              foregroundColor: Colors.black.withValues(alpha: .22),
                            )))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: SvgPicture.asset(
                      'assets/img/+_prayer.svg',
                      height: 36,
                      colorFilter: ColorFilter.mode(
                          lightTheme3.primaryColor.withValues(alpha: 1), BlendMode.srcIn),
                    ))),
                Expanded(
                    flex: 1,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (auth.isLoggingIn) CircularProgressIndicator(),
                          if (auth.isLoggingIn) SizedBox(height: 4),
                          if (auth.isLoggingIn && auth.loggingInWith != null)
                            Text(auth.loggingInWith!.label,
                                style: TextStyle(color: Colors.white.withValues(alpha: .5))),
                          if (!auth.isLoggingIn) AuthButtons(),
                          SizedBox(height: 10), // Add some space off the bottom
                        ]))),
              ],
            ),
          )),
    );
  }
}

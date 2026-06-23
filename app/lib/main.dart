import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/screens/auth/login_page.dart';
import 'package:plusprayer/widgets/screens/firstRun/first_run_screen.dart';
import 'package:plusprayer/widgets/screens/history/history_screen.dart';
import 'package:plusprayer/widgets/screens/home/home_v2.dart';
import 'package:plusprayer/widgets/screens/name/name_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/services/firebase.dart';
import 'package:plusprayer/widgets/screens/home/home.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'hooks/use_user_settings.dart';

final messaging = FirebaseMessaging.instance;

getRouter() => GoRouter(
      observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
      refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      initialLocation: '/',
      redirect: (state, context) async {
        if (FirebaseAuth.instance.currentUser == null) {
          return '/login';
        }

        return null;
      },
      // redirect: (context, state) {
      //   final user = FirebaseAuth.instance.currentUser;
      //   final loggingIn = state.location == '/login';
      //
      //   if (user == null && !loggingIn) {
      //     return '/login';
      //   }
      //   if (user != null && loggingIn) {
      //     return '/';
      //   }
      //
      //   return null;
      // },
      routes: [
        GoRoute(
            path: '/',
            redirect: (state, context) async {
              // Check current user before running app
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                // FlutterNativeSplash.remove();
                return '/login';
              }

              print('going to names');

              return '/names';
            }),
        GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          name: 'home',
          path: '/home',
          redirect: (state, context) => '/names',
          // builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: 'firstRun',
          path: '/firstRun',
          builder: (context, state) => const FirstRunScreen(),
        ),
        GoRoute(
          name: 'names',
          path: '/names',
          builder: (context, state) => const HomeScreen2(),
          // pageBuilder: _fadeTransition(const HabitsScreen()),
          routes: [
            GoRoute(
              name: 'namesAdd',
              path: 'add',
              builder: (context, state) {
                return NameScreen(key: state.pageKey, nameId: 'add');
              },
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;

                return NameScreen(nameId: id);
              },
            ),
          ],
        ),
        GoRoute(
          name: 'prayers',
          path: '/prayers',
          builder: (context, state) => const HistoryScreen(),
          // pageBuilder: _fadeTransition(const HabitsScreen()),
          routes: [
            // GoRoute(
            //   name: 'namesAdd',
            //   path: 'add',
            //   builder: (context, state) {
            //     return NameScreen(key: state.pageKey, nameId: 'add');
            //   },
            // ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;

                return NameScreen(nameId: id);
              },
            ),
          ],
        ),
// GoRoute(
//       name: 'habits',
//       path: '/habits',
//       builder: (context, state) => const HabitsScreen(),
//       // pageBuilder: _fadeTransition(const HabitsScreen()),
//       routes: [
//         GoRoute(
//           name: 'habitsAdd',
//           path: 'add',
//           builder: (context, state) {
//             return Scaffold(
//                 body: Column(children: [
//                   Text('Habit create'),
//                   TextButton(onPressed: () => context.pop(), child: Text('Back'))
//                 ]));
//           },
//         ),
//         GoRoute(
//           path: ':id',
//           builder: (context, state) {
//             final id = state.pathParameters['id'];
//
//             return Scaffold(
//                 body: Column(children: [
//                   Text('Habit $id'),
//                   TextButton(onPressed: () => context.pop(), child: Text('Back')),
//                   TextFormField(
//                       keyboardType: TextInputType.numberWithOptions(decimal: false),
//                       inputFormatters: <TextInputFormatter>[
//                         // for below version 2 use this
//                         FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
// // for version 2 and greater youcan also use this
//                         FilteringTextInputFormatter.digitsOnly
//
//                       ],
//                       decoration: InputDecoration(
//                           labelText: "whatever you want",
//                           hintText: "whatever you want",
//                           icon: Icon(Icons.phone_iphone)
//                       )
//                   )
//                 ]));
//           },
//         ),
//       ],
//     ),
      ],
    );

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize timezone database
  tz.initializeTimeZones();

  // // Get image urls ready for use
  // await appImageUrls.prefetchAll();

  await Future.wait([
    userSettingsState.init(),
    PPFirebase.init(),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    Future(() async {
      var timezone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezone);
      tz.setLocalLocation(location);
    }),
  ]);

  // Automatically catch all errors that are thrown within the Flutter framework
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch asynchronous errors that aren't handled by the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MainApp());
}

class MainApp extends HookWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useState(true);
    final router = useRef(getRouter());
    final userSettings = useUserSettings();
    final themeMode = userSettings.mode;

    useEffect(() {
      // Use a microtask to ensure we're not accessing context during initState
      Future.microtask(() async {
        if (context.mounted) {
          try {
            await loadImportantImages(context, themeMode).timeout(
              5.seconds,
              onTimeout: () => {
                // Handle timeout
                print('Timeout loading important images'),
              },
            );
          } catch (e) {
            print('Error loading important images');
            print(e);
            // Log error or handle offline
          } finally {
            loading.value = false;
            FlutterNativeSplash.remove();
          }
        }
      });

      return null;
    }, [themeMode]);

    if (loading.value) {
      return Container();
    }

    return MaterialApp.router(
      routerConfig: router.value,
      themeMode: themeMode,
      themeAnimationDuration: 200.ms,
      theme: lightTheme3,
      darkTheme: darkTheme4,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

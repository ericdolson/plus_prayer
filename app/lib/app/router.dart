// Navigation (screens.md): Home is the only screen with the floating bar; every
// other screen pushes with a back arrow. Prayer mode is a state of Home, not
// a route. You is a full-height sheet over Home (features/you), as in the POC.

import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/placeholder/placeholder_screen.dart';

abstract final class Routes {
  static const home = '/';
  static String subject(String id) => '/subject/$id';
  static const todaysList = '/list';
  static const history = '/history';
  static const portion = '/portion';
}

GoRouter buildRouter() => GoRouter(
      initialLocation: Routes.home,
      // Build step 3: redirect to onboarding while the user has no self name
      // (state-based resume, auth-onboarding.md).
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomeScreen(),
          routes: [
            // Build step 5: name / intention detail (bead strand).
            GoRoute(
              path: 'subject/:id',
              builder: (context, state) => PlaceholderScreen.subject(state.pathParameters['id']!),
            ),
            // Build step 5: Today's list (seal, video, counts).
            GoRoute(path: 'list', builder: (context, state) => const PlaceholderScreen.todaysList()),
            // Build step 5.
            GoRoute(path: 'history', builder: (context, state) => const PlaceholderScreen.history()),
            // Build step 6: Your portion (who's carried, plan limits).
            GoRoute(path: 'portion', builder: (context, state) => const PlaceholderScreen.portion()),
          ],
        ),
      ],
    );

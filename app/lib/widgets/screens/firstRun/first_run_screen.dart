import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/hooks/use_user.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';

class FirstRunScreen extends HookWidget {
  const FirstRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a page controller using hooks
    final pageController = usePageController();
    final screenSize = useScreenSize();
    final previousPage = useRef<int?>(null);
    final user = useUser();
    final auth = useAuth();

    useEffect(() {
      void listener() {
        final currentPage = pageController.page?.round();
        if (currentPage != null && currentPage != previousPage.value) {
          previousPage.value = currentPage;

          // 👉 Trigger your function here
          print("Page changed to: $currentPage");
          // doSomethingOnPageChange(currentPage);
        }
      }

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swiping
        children: [
          // Welcome page 2
          Container(
              decoration: BoxDecoration(
                color: Color(0xFF21739D),
                // image: DecorationImage(
                //   image: AssetImage('assets/img/clear_skies.png'),
                //   fit: BoxFit.cover, // Or BoxFit.fill / contain / fitHeight, etc.
                //   alignment: Alignment.bottomCenter,
                // ),
              ),
              child: SafeArea(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        alignment: Alignment.centerRight,
                        child: IconButton.filled(
                            onPressed: () {
                              auth.logout();
                              context.go('/login');
                              // pageController.animateToPage(
                              //   0,
                              //   duration: const Duration(milliseconds: 300),
                              //   curve: Curves.easeInOut,
                              // );
                            },
                            icon: Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha:.3),
                              foregroundColor: Colors.white.withValues(alpha:.2),
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                            ))),
                    Expanded(
                        flex: 1,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          // Icon(PlusPrayer.plus_dots_list, size: 100, color: Color(0xFF39416D)),
                          SizedBox(height: 20),
                          FancyText(
                            user.hasGivenName ? 'Welcome, ${user.givenName}!' : 'Welcome!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 36, color: Color(0xFF39416D)),
                          ),
                          SizedBox(height: 30),
                          Text('Your prayers are beautiful here',
                              style: TextStyle(fontSize: 16, color: Color(0xFF39416D))),
                        ])),
                    Expanded(flex: 1, child: SizedBox.shrink())
                  ],
                ),
              ))),

          // Welcome page
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                  flex: 1,
                  child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(
                          PlusPrayer.plus_dots,
                          size: 60,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.2),
                        ),
                        const SizedBox(height: 60),
                        const FancyText(
                          'Welcome!',
                          style: TextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ), // Placeholder for welcome content
                        const SizedBox(height: 20),
                        Text(
                          'The +Prayer community is here for you! Let\'s set up your app in a few simple steps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.8)),
                        ),
                        const SizedBox(height: 60),
                        FilledButton(
                          onPressed: () {
                            pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Get Started'),
                        ),
                        TextButton(
                          onPressed: () {
                            pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Back'),
                        ),
                      ]))),
              Image(
                image: remoteAppImgProvider(AppImageType.hands),
                // userSettings.isLightMode ? 'assets/img/path_light.png' : 'assets/img/path_dark.png',
                width: screenSize.width,
              ),
              // SvgPicture.asset(
              //   'assets/img/journey.svg',
              //   width: min(300, screenSize.width),
              //   colorFilter: ColorFilter.mode(
              //       Theme.of(context).colorScheme.onSurface.withValues(alpha:.5), BlendMode.srcIn),
              // ),
            ]),
          ),
        ],
      ),
    );
  }
}

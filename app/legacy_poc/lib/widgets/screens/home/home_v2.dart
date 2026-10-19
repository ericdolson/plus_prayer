import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_current_date.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/hooks/use_user_settings.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/widgets/animations/SiriHalo.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/names/name_list.dart';
import 'package:plusprayer/widgets/names/name_prayed_status.dart';
import 'package:plusprayer/widgets/prayers/in_prayer_bg.dart';
import 'package:plusprayer/widgets/screens/home/home_community.dart';
import 'package:plusprayer/widgets/screens/home/home_groups.dart';
import 'package:plusprayer/widgets/screens/home/home_intentions.dart';
import 'package:plusprayer/widgets/screens/home/home_names.dart';

import '../../../hooks/use_currentMetrics.dart';
import '../../../hooks/use_in_prayer.dart';
import '../../../hooks/use_names.dart';
import '../../../hooks/use_prayed_for_current_roll.dart';
import '../../../models/name.dart';
import '../../animations/in_prayer_praying_hands.dart';
import '../../framework/controls/unprayed_filter_switch.dart';
import '../../prayers/prayer_modal.dart';
import '../name/name_screen_create_update_name.dart';
import '../settings/settings_screen.dart';
import 'home_community_v2.dart';

final random = Random();

final subtitleOpacity = .5;

class HomeScreen2 extends HookWidget {
  const HomeScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    // imageCache.clear();
    final currentDateKey = useCurrentDateKey();
    final currentMetrics = useCurrentMetrics();
    final filterUnprayed = useState(false);
    final hideBottomNavigationController = useAnimationController(duration: 500.ms);
    final inPrayer = useInPrayer();
    final List<Name> names = useNames();
    final prayedForCurrentRoll = usePrayedForCurrentRoll();
    final reactions = useState<List<Widget>>([]);
    final screenSize = useScreenSize();
    // final tabController = useTabController(initialLength: 3);
    final userSettings = useUserSettings();
    final userCommunityPrayerDelta = useState(0);
    final selectedTabIndex = useState(0);
    final pageController = usePageController();
    final totalApproximateBottomPadding = useMemoized(() {
      final bottomInset = MediaQuery.of(context).viewPadding.bottom;
      final totalBottomPadding = 100 + bottomInset;
      return totalBottomPadding;
    });

    final pageTabs = useMemoized(() {
      final hasUnprayedNames = names.any((name) => name.lastPrayerDate != currentDateKey);

      final result = [
        _PageTab(
            type: HomeCommunity,
            label: 'Community',
            unprayed: !prayedForCurrentRoll,
            visible: true),
        _PageTab(
            type: HomeNames,
            label: 'Names',
            unprayed: names.any((name) => name.lastPrayerDate != currentDateKey),
            visible: true),
        _PageTab(type: HomeIntentions, label: 'Intentions', unprayed: false, visible: true),
        _PageTab(type: HomeGroups, label: 'Groups', unprayed: false, visible: true)
      ];

      if (!result[selectedTabIndex.value].visible) {
        selectedTabIndex.value = result.indexWhere((e) => e.visible);
      }

      return result.where((e) => e.visible).toList(growable: false);
    }, [currentDateKey, filterUnprayed.value, prayedForCurrentRoll, selectedTabIndex, names, 3]);

    var liveReaction = useCallback(() {
      if (userSettings.showLivePrayers) {
        var widget = Positioned(
          key: UniqueKey(),
          bottom: 50, // Move the icon upwards
          left: Random().nextDouble() * (screenSize.width - 100) + 35, // Random horizontal position
          child:
              _LiveReactionAnimation(moveDistance: screenSize.height / 2), // Start from the bottom
        );

        reactions.value = [...reactions.value, widget];

        Future.delayed(2.5.seconds, () {
          reactions.value = [...reactions.value..remove(widget)];
        });
      }
    }, [3]);

    useEffect(() {
      liveReaction();
      userSettingsState.haptic(HapticFeedback.selectionClick);
    }, [currentMetrics.prayerCount]);

    useEffect(() {
      if (pageController.hasClients) {
        pageController.jumpToPage(selectedTabIndex.value);
        pageController.animateToPage(
          selectedTabIndex.value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }, [selectedTabIndex.value]);

    return Stack(children: [
      Scaffold(
        extendBodyBehindAppBar: selectedTabIndex.value == 0,
        appBar: AppBar(
          backgroundColor: selectedTabIndex.value == 0
              ? Colors.transparent
              : Theme.of(context).scaffoldBackgroundColor,
          scrolledUnderElevation: 0,
          elevation: 0,
          // toolbarHeight: 70,
          titleSpacing: 4,
          title: !inPrayer.isInPrayer
              ? null
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  InPrayerPrayingHandsAnimation2(
                    size: 44,
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Text(
                    'In prayer',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.amber),
                  ),
                ]).animate(delay: 200.ms).fadeIn(duration: 700.ms).moveY(
                    begin: 4,
                    end: 0,
                    duration: 700.ms,
                  ),
          leading: inPrayer.isInPrayer
              ? null
              : IconButton(
                  onPressed: () {
                    showSettingsBottomSheet(context);
                  },
                  icon: Badge(
                      isLabelVisible: false,
                      child: Icon(Icons.short_text_rounded,
                          size: 26, color: Theme.of(context).colorScheme.onSurface)),
                ).animate().fadeIn(duration: 400.ms),
          // actions: [
          //   Padding(
          //       padding: EdgeInsets.only(right: 12),
          //       child: UnprayedFilterSwitch(
          //         value: filterUnprayed.value,
          //         onChanged: (bool value) {
          //           filterUnprayed.value = value;
          //         },
          //       ))
          // ],
          // bottom: _ScrollableButtonTabsAppBarBottom(
          //   width: screenSize.width,
          //   selectedIndex: selectedTabIndex,
          //   tabs: pageTabs,
          // ),
        ),
        body:
            // TabBarView(controller: tabController, children: [
            Stack(children: [
          PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(), // Prevent swiping
            itemBuilder: (_, index) {
              if (pageTabs[index].type == HomeCommunity) {
                return HomeCommunity2(
                    bottomPadding: totalApproximateBottomPadding,
                    filterUnprayed: filterUnprayed.value);
              }
              if (pageTabs[index].type == HomeNames) {
                return HomeNames(
                  bottomPadding: totalApproximateBottomPadding,
                  filterUnprayed: filterUnprayed.value,
                );
              }
              if (pageTabs[index].type == HomeIntentions) {
                return HomeIntentions(
                    bottomPadding: totalApproximateBottomPadding,
                    filterUnprayed: filterUnprayed.value);
              }
              // if (pageTabs[index].type == HomeGroups) {
              return HomeGroups(
                  bottomPadding: totalApproximateBottomPadding,
                  filterUnprayed: filterUnprayed.value);
              // }
            },
            itemCount: pageTabs.length,
          ),
          // if (!inPrayer.isInPrayer && names.isEmpty && !filterUnprayed.value)
          //   Column(children: [
          //     Expanded(
          //         flex: 5,
          //         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          //           Padding(
          //               padding: EdgeInsets.only(bottom: 30),
          //               child: Text('Nurture through prayer',
          //                   textAlign: TextAlign.center,
          //                   style: TextStyle(
          //                     fontSize: 16,
          //                     fontWeight: FontWeight.w700,
          //                     color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .8),
          //                   ))),
          //           ...[
          //             TextButton.icon(
          //                 icon: Icon(
          //                   Icons.add_rounded,
          //                   size: 18,
          //                 ),
          //                 label: Text(
          //                   'Add someone to pray for',
          //                   textAlign: TextAlign.center,
          //                 ),
          //                 onPressed: () {
          //                   const SnackBar(content: Text("Copied to clipboard"));
          //                   // showCreateUpdateName(context: context);
          //                 }),
          //           ]
          //               .animate(delay: 1000.ms, interval: 600.ms)
          //               .fadeIn(duration: 600.ms)
          //               .moveY(begin: 4),
          //         ])),
          //     Image(
          //       image: userSettings.isDarkMode
          //           ? remoteAppImgProvider(AppImageType.addNameDark)
          //           : remoteAppImgProvider(AppImageType.addNameLight),
          //       width: screenSize.width,
          //     ),
          //     Expanded(
          //         flex: 2,
          //         child: Container(
          //           color: userSettings.isDarkMode ? Color(0xFF364356) : Color(0xFFdaf08a),
          //         )),
          //   ]).animate().fadeIn(),
          ...reactions.value,
        ]),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton:
            // filteredNames.isEmpty && prayedForCurrentRoll && filterUnprayed.value ? null :
            inPrayer.isInPrayer
                ? null
                : AnimatedContainer(
                    duration: 200.ms,
                    width: 85,
                    height: 85,
                    child: FloatingActionButton(
                        backgroundColor: Colors.blue,
                        elevation: 3,
                        shape: const CircleBorder(),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          inPrayer.startPrayer();
                          // userCommunityPrayerDelta.value++;
                          // Prayer.logCommunityPrayer(currentMetrics.currentRoll);
                          // showPrayerModal(
                          //     context: context,
                          //     onPrayerAdded: () {
                          //       userSettingsState.haptic(HapticFeedback.lightImpact);
                          //       liveReaction();
                          //     });
                        },
                        // child: Icon(PlusPrayer.pray, size: 24),
                        child: Icon(
                          PlusPrayer.praying_hands,
                          size: 28,
                          color: Colors.white,
                          // color: Theme.of(context).colorScheme.surfaceTint,
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: .2), blurRadius: 20)
                          ],
                        ))),
        extendBody: true,
        bottomNavigationBar: true && inPrayer.isInPrayer ? AnimatedBottomNavigationBar.builder(
            hideAnimationController: hideBottomNavigationController,
            itemCount: 2,
            // height: 100,
            tabBuilder: (int index, bool isActive) {
              switch (index) {
                case 0:
                  return inPrayer.isInPrayer
                      ? const _BottomNavigationActionButton(
                          icon: Icons.close_rounded,
                          color: Colors.red,
                          label: 'Cancel',
                        )
                      : const _BottomNavigationActionButton(
                          icon: Icons.history_rounded,
                        );
                  return Icon(
                    Icons.history_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                  );
                case 1:
                  return inPrayer.isInPrayer
                      ? const _BottomNavigationActionButton(
                          icon: Icons.check_circle_rounded,
                          color: Colors.green,
                          label: 'Complete',
                        )
                      : const _BottomNavigationActionButton(icon: Icons.add_rounded);
              }
              return Icon(
                index == 0 ? Icons.history_rounded : Icons.add_rounded,
                size: 30,
                color: Theme.of(context).colorScheme.onSurface,
              );
            },
            // icons: const [
            //   Icons.history_rounded,
            //   // PlusPrayer.edit_prayer_list_2,
            //   // Icons.filter_list_rounded,
            //   Icons.add_rounded,
            // ],
            blurEffect: true,
            // height: inPrayer.isInPrayer ? 200 : null,
            // iconSize: 30,
            activeIndex: -1,
            backgroundColor: Theme.of(context).colorScheme.surface,
            gapLocation: GapLocation.center,
            elevation: 0,
            // activeColor: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5),
            // inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5),
            leftCornerRadius: 16,
            rightCornerRadius: 16,
            notchSmoothness: NotchSmoothness.softEdge,
            onTap: (index) {
              userSettingsState.haptic(HapticFeedback.lightImpact);

              if (inPrayer.isInPrayer) {
                switch (index) {
                  case 0:
                    inPrayer.endPrayer();
                    break;
                  case 1:
                    inPrayer.completePrayer();
                    break;
                }
              } else {
                switch (index) {
                  case 0:
                    // context.pushNamed('prayers');
                    context.pushNamed('firstRun');
                    break;
                  case 1:
                    showCreateUpdateName(context: context);
                    break;
                }
              }
            }) : null,
      ),
      AnimatedSwitcher(
          duration: 1.seconds,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: inPrayer.isInPrayer
              ? SiriHalo(
                  child: SizedBox(
                  height: screenSize.height,
                  width: screenSize.width,
                ))
              : SizedBox.shrink()),
    ]);
  }
}

class _PageTab {
  final String label;
  final Type type;
  final bool unprayed;
  final bool visible;

  _PageTab({required this.label, required this.type, required this.unprayed, this.visible = true});
}

class _LiveReactionAnimation extends StatelessWidget {
  final double moveDistance;

  const _LiveReactionAnimation({required this.moveDistance});

  @override
  Widget build(BuildContext context) {
    return Icon(
      PlusPrayer.praying_hands,
      color: Colors.amber.withValues(alpha: .6),
      // color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.25),
      size: 26,
    )
        .animate()
        .moveY(end: -moveDistance, duration: 2.seconds)
        .fadeOut(begin: 1, delay: 1.seconds, duration: 1.seconds);
  }
}

class _BottomNavigationActionButton extends StatelessWidget {
  final Color? color;
  final IconData icon;
  final String? label;

  const _BottomNavigationActionButton({super.key, this.color, required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface, size: 30),
      if (label != null)
        Text(label!,
            style: TextStyle(fontSize: 12, color: color ?? Theme.of(context).colorScheme.onSurface))
    ]);
  }
}

class _ScrollableButtonTabs extends HookWidget {
  final ValueNotifier<int> selectedIndex;
  final List<String> tabs;

  const _ScrollableButtonTabs({
    Key? key,
    required this.selectedIndex,
    required this.tabs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: .3)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                  foregroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: isSelected ? 1 : .9),
                  side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: .3)
                          : Colors.transparent,
                      width: 1),
                  // padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  // textStyle: TextStyle(
                  //   fontSize: 12,
                  //   fontWeight: FontWeight.w500,
                  // ),
                  visualDensity: VisualDensity.compact),
              onPressed: () {
                HapticFeedback.lightImpact();
                selectedIndex.value = index;
              },
              child: Text(tabs[index]),
            ),
          );
        }),
      ),
    );
  }
}

// Wrap it in a PreferredSizeWidget so it can be used in AppBar.bottom
class _ScrollableButtonTabsAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final ValueNotifier<int> selectedIndex;
  final List<_PageTab> tabs;
  final double width;

  const _ScrollableButtonTabsAppBarBottom({
    Key? key,
    required this.selectedIndex,
    required this.tabs,
    required this.width,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kBottomNavigationBarHeight - 16);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: width,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == selectedIndex.value;
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(children: [
                    FilledButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 1)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1),
                          // : Colors.transparent,
                          foregroundColor: isSelected
                              ? Theme.of(context).colorScheme.surfaceTint
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: isSelected ? 1 : .9),
                          // side: BorderSide(
                          //     color: isSelected
                          //         ? Theme.of(context).colorScheme.primary.withValues(alpha:.3)
                          //         : Colors.transparent,
                          //     // : Theme.of(context).colorScheme.primary,
                          //     width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          // textStyle: TextStyle(
                          //   fontSize: 12,
                          //   fontWeight: FontWeight.w500,
                          // ),
                          // visualDensity: VisualDensity.compact
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          selectedIndex.value = index;
                        },
                        child: Text(tab.label)),
                    if (tab.unprayed)
                      Positioned(top: 0, right: -1, child: UnprayedDot(size: 10, borderSize: 3))
                  ]));
            }),
          ),
        ));
  }
}

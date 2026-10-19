import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/hooks/use_user_settings.dart';
import 'package:plusprayer/models/prayer.dart';
import 'package:plusprayer/presentation/logo.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/screens/name/name_screen_create_update_name.dart';

import '../../hooks/use_currentMetrics.dart';
import '../../hooks/use_in_prayer.dart';
import '../../hooks/use_prayed_for_current_roll.dart';
import '../../models/name.dart';
import '../../presentation/plus_prayer_icons.dart';
import '../../services/firebase.dart';
import '../framework/two_tone_pray_icon.dart';
import 'name_list_tile.dart';
import 'name_prayed_status.dart';

class NameList extends HookWidget {
  static void _defaultCallback() {}

  final double bottomPadding;
  final bool filterUnprayed;
  final List<Name> names;
  final VoidCallback onClearUnprayedFilter;
  final int userCommunityPrayerDelta;

  const NameList({
    super.key,
    this.bottomPadding = 0,
    this.filterUnprayed = false,
    required this.names,
    this.onClearUnprayedFilter = _defaultCallback,
    this.userCommunityPrayerDelta = 0,
  });

  @override
  Widget build(BuildContext context) {
    // imageCache.clear();
    final extraHeight = useState(0.0); // To track how much extra height we add when pulling down
    final currentMetrics = useCurrentMetrics();
    final inPrayer = useInPrayer();
    final prayedForCurrentRoll = usePrayedForCurrentRoll();
    final screenSize = useScreenSize();
    final scrollController = useScrollController();
    final userCommunityPrayers = useState(0);
    final userSettings = useUserSettings();

    final hidePrayerRollTile = filterUnprayed && prayedForCurrentRoll;

    useEffect(() {
      (() async {
        fetchPrayerCount(currentMetrics.date).then((value) {
          userCommunityPrayers.value = value;
        });
      })();
    }, [currentMetrics.date]);

    if (names.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo(),
          // FancyText(
          //   'No names added yet',
          //   style: TextStyle(fontSize: 18),
          // ),
          Expanded(
              flex: 3,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Text('Your `Unprayed` list is empty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .8),
                        ))),
                ...[
                  TextButton.icon(
                      icon: Icon(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Add someone to pray for',
                        textAlign: TextAlign.center,
                      ),
                      onPressed: () {
                        showCreateUpdateName(context: context);
                      }),
                  TextButton.icon(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Clear filter',
                        textAlign: TextAlign.center,
                      ),
                      onPressed: () {
                        onClearUnprayedFilter();
                      })
                ]
                    .animate(delay: 2000.ms, interval: 600.ms)
                    .fadeIn(duration: 600.ms)
                    .moveY(begin: 4),
              ])),
          Image(
            image: userSettings.isDarkMode
                ? remoteAppImgProvider(AppImageType.unprayedEmptyDark)
                : remoteAppImgProvider(AppImageType.unprayedEmptyLight),
            width: screenSize.width,
          ),
          Expanded(
              flex: 2,
              child: Container(
                color: userSettings.isDarkMode ? Color(0xFF364356) : Color(0xFFdaf08a),
              )),
        ],
      ).animate().fadeIn();
    }

    return ReorderableListView.builder(
      // Disable reordering when in prayer
      buildDefaultDragHandles: !inPrayerState.isInPrayer,
      onReorderStart: (index) {
        // Optional: provide haptic feedback or visual indication
        HapticFeedback.lightImpact();
      },
      onReorderEnd: (index) {
        // Optional: provide haptic feedback or visual indication
        Future.delayed(300.ms, () {
          HapticFeedback.lightImpact();
        });
      },
      scrollController: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        return Column(
          key: Key(name.id!),
          mainAxisSize: MainAxisSize.min,
          children: [
            NameListTile(index: index, name: name),
            if (index < names.length - 1)
              Divider(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .1),
                  height: .5,
                  thickness: .5),
          ],
        );
      },
      onReorder: (oldIndex, newIndex) {
        // Handle reordering here
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final name = names.removeAt(oldIndex);
        names.insert(newIndex, name);

        // Update positions in database or state management
        // This depends on how you're managing state in your app
      },
      proxyDecorator: (child, index, animation) {
        // Customize the appearance of the dragged item
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final name = names[index];
            return Material(
              // elevation: 4.0 * animation.value,
              // color: Colors.transparent,
              color: Theme
                  .of(context)
                  .colorScheme
                  .surfaceTint,
              shadowColor: Theme
                  .of(context)
                  .colorScheme
                  .surfaceTint,
              child: NameListTile(index: index, name: name),
            ).animate().scale(begin: Offset(1, 1), end: Offset(1.03, 1.03), duration: 100.ms);
          },
          child: child,
        );
      },
    );
  }
}

class ShrinkingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extraHeight;
  final double minExtentHeight = 199.0;
  double maxExtentHeight = 200.0;
  final int prayers;
  final int userPrayers;

  ShrinkingHeaderDelegate({this.extraHeight = 0, this.prayers = 123456, this.userPrayers = 0});

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight + extraHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // print(overlapsContent);
    final shrinkPercentage = (shrinkOffset / (maxExtent - minExtent)).clamp(0, 1);

    // The content that shrinks and fades out
    final mainContent = Opacity(
        opacity: 1.0 - shrinkPercentage,
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.groups_rounded,
                        size: 20.0 * (1 - (shrinkPercentage)),
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .5)),
                    SizedBox(width: 8),
                    Text(
                      'Community prayers today',
                      style: TextStyle(
                        fontSize: 14.0 * (1 - (shrinkPercentage)), // Shrink text size
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .5),
                        // color: Colors.black.withValues(alpha:1.0 - shrinkPercentage), // Fade out
                      ),
                    )
                  ]),
                  Transform.scale(scale: 1.0 - shrinkPercentage, child: _Metrics(value: prayers)),
                ],
              )),
          Row(children: [
            Icon(Icons.person_rounded,
                size: 14.0 * (1 - (shrinkPercentage)),
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .5)),
            SizedBox(width: 4),
            Text(
              'You contributed $userPrayers times',
              style: TextStyle(
                fontSize: 13.0 * (1 - (shrinkPercentage)), // Shrink text size
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .5),
              ),
            )
          ]),
        ]));

    // The content that fades in after 50% shrinkage
    final collapsedContent = Opacity(
      opacity: shrinkPercentage > 0.5 ? (shrinkPercentage - 0.5) * 2 : 0, // Fade in after 50%
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_Metrics(value: overlapsContent ? 0 : prayers)]),
    );

    return Stack(
      children: [
        Container(
          height: maxExtent < maxExtentHeight - 50 ? 0 : maxExtent,
          // color: Theme.of(context).scaffoldBackgroundColor,
          // color: Theme.of(context).colorScheme.surface,
          // color: Color.fromRGBO(225, 231, 243, 1),
          color: Theme
              .of(context)
              .colorScheme
              .surfaceTint,
          child: Container(
            // color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.05),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      mainContent,
                      collapsedContent,
                    ],
                  ),
                ),
              )),
        ),
        // AnimatedContainer(
        //   duration: 100.ms,
        //   // height: maxExtent,
        //   // color: Theme.of(context).scaffoldBackgroundColor,
        //   color: extraHeight >= 50 ? Colors.red : Colors.transparent,
        // ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _Metrics extends StatelessWidget {
  final int value;

  const _Metrics({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          AnimatedFlipCounter(
            thousandSeparator: ',',
            textStyle: TextStyle(fontFamily: 'Roca', fontSize: 28, fontWeight: FontWeight.w800),
            duration: 200.ms,
            value: value, // pass in a value like 2014
          ),
        ],
      ),
    );
  }
}

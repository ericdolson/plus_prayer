import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_currentMetrics.dart';
import 'package:plusprayer/hooks/use_current_date.dart';
import 'package:plusprayer/hooks/use_delayed.dart';
import 'package:plusprayer/hooks/use_historicalMetrics.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';
import 'package:plusprayer/hooks/use_prayed_for_current_roll.dart';
import 'package:plusprayer/hooks/use_prayed_for_name_today.dart';
import 'package:plusprayer/models/name.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/utils/number_utils.dart';
import 'package:plusprayer/widgets/framework/PPAvatar.dart';

import 'name_prayed_status.dart';

const listTileHorizontalPadding = 16.0;
const listTileVerticalPadding = 5.0;
const subtitleOpacity = .5;

class NameListTile extends HookWidget {
  final int index;
  final Name name;

  NameListTile({super.key, required this.index, required this.name});

  @override
  Widget build(BuildContext context) {
    final currentMetrics = useCurrentMetrics();
    final dateKey = useCurrentDateKey();
    final historicalMetrics = useHistoricalMetrics();
    final didUserPrayForCurrentRoll = usePrayedForCurrentRoll();
    final didPrayToday = usePrayedForNameToday(name);
    final inPrayer = useInPrayer();
    final [isInPrayerDelayed as bool, didUserPrayForCurrentRollDelayed as bool] = useDelayed(
        values: [inPrayer.isInPrayer, didUserPrayForCurrentRoll], delay: (index * 25).ms);

    final onCurrentPrayerRoll = useMemoized(() {
      return name.onRoll.contains(currentMetrics.currentRollId);
    }, [currentMetrics.currentRollId, name.onRoll]);

    final removingFromPrayerRoll = useMemoized(() {
      return onCurrentPrayerRoll && !name.selected;
    }, [name.selected, onCurrentPrayerRoll]);

    return ListTile(
      onTap: () {
        if (inPrayer.isInPrayer) {
          HapticFeedback.selectionClick();
          inPrayer.togglePrayedFor(name.id!);
          return;
        }

        HapticFeedback.lightImpact();
        context.go('/names/${name.id}');
      },
      // tileColor: onCurrentPrayerRoll ? Theme.of(context).colorScheme.secondary.withValues(alpha:.1) : null,
      contentPadding: EdgeInsets.only(
          top: listTileVerticalPadding,
          right: listTileHorizontalPadding,
          bottom: listTileVerticalPadding,
          left: 0),
      splashColor: Theme.of(context).colorScheme.surfaceTint,
      // tileColor: Colors.blue,
      shape: RoundedRectangleBorder(),
      leading: SizedBox(
          width: 48 + listTileHorizontalPadding,
          child: Row(children: [
            NameListTilePrayedStatus(prayed: didPrayToday, width: listTileHorizontalPadding),
            Stack(children: [
              index == -1
                  ? CircleAvatar(
                      radius: 24,
                      // backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha:.1),

                      foregroundColor: Colors.red,
                      child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.1),
                                  width: 1)),
                          child: Center(
                              child: Text('🌹',
                                  style: TextStyle(
                                      fontSize: 36, fontWeight: FontWeight.w500, height: 0)))),
                    )
                  // Container(
                  //         width: 48,
                  //         child: Center(
                  //             child: Text('🌹',
                  //                 style:
                  //                     TextStyle(fontSize: 32, fontWeight: FontWeight.w500, height: 0))))
                  : PPAvatar.fromName(
                      name: name,
                      radius: 24,
                    ),
              Positioned(
                  bottom: -3,
                  right: -3,
                  child: AnimatedScale(
                      scale: onCurrentPrayerRoll ? 1 : 0,
                      duration: 200.ms,
                      child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).scaffoldBackgroundColor),
                          child: Center(
                              child: Icon(
                            PlusPrayer.plus_dots_list,
                            // Icons.verified_rounded,
                            size: 13,
                            // color: Colors.lightGreen,
                            color: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor,
                            // color: Colors.lightGreen,
                          ))))),
            ])
          ])),
      title: FancyText(
        name.alias ?? name.name,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      subtitle: Column(children: [
        // SizedBox(height: 60),
        if (onCurrentPrayerRoll && false)
          Row(children: [
            Icon(
              // PlusPrayer.plus_dots,
              Icons.verified_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
              // color: Colors.lightGreen,
            ),
            SizedBox(width: 4),
            _SubtitleText('On current roll'),
          ]),
        if (name.intention != null) _SubtitleText(name.intention!),
        IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // _ScheduledPrayerRoll(isActive: name.selected),
          // if (removingFromPrayerRoll) _ScheduledPrayerRoll(isCancelled: true),
          // if (name.id == 'c2QAhJ1dLws4RSVZq3FY') _ScheduledPrayerRoll(isCancelled: false),

          // Opacity(opacity: subtitleOpacity, child: Icon(Icons.groups_rounded, size: 18)),
          // SizedBox(width: 4),
          // _SubtitleNumber(historicalMetrics.totalPrayersByRolls(name.onRoll) +
          //     (onCurrentPrayerRoll ? currentMetrics.prayerCount : 0)),

          // _SubtitleDivider(),

          //
          // Opacity(
          //     opacity: subtitleOpacity,
          //     child: Icon(true ? Icons.person_rounded : Icons.how_to_reg_rounded, size: 14)),
          // SizedBox(width: 4),
          // _SubtitleNumber(name.totalPPCount),

          _ScheduledPrayerRoll2(isActive: name.selected),

          Opacity(
              opacity: subtitleOpacity, child: Icon(Icons.local_fire_department_rounded, size: 14)),
          SizedBox(width: 4),
          _SubtitleNumber(3),

          _SubtitleDivider(),

          Opacity(opacity: subtitleOpacity, child: Icon(PlusPrayer.praying_hands, size: 14)),
          SizedBox(width: 4),
          _SubtitleNumber(name.ppCounts[dateKey] ?? 0),
          // historicalMetrics.totalPrayersByRolls(name.onRoll) +
        ])),
        // AnimatedContainer(
        //     duration: 5000.ms,
        //     height: 0,
        //     color: Colors.red)
      ]),
      // trailing: Stack(alignment: AlignmentDirectional.centerEnd, children: [
      //   AnimatedScale(
      //       scale: isInPrayerDelayed ? 0 : 1,
      //       duration: 700.ms,
      //       curve: inPrayer.isInPrayer ? Curves.elasticOut : Curves.elasticIn,
      //       child: Icon(Icons.chevron_right_rounded,
      //           // size: 22,
      //           color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3))),
      //   AnimatedScale(
      //       scale: isInPrayerDelayed ? 1 : 0,
      //       duration: 700.ms,
      //       curve: inPrayer.isInPrayer ? Curves.elasticOut : Curves.elasticIn,
      //       child: Icon(
      //         Icons.circle_outlined,
      //         // size: 22,
      //         color: Theme.of(context).colorScheme.primary,
      //       )),
      // ]),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedSwitcher(
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.elasticIn,
            reverseDuration: 0.ms,
            duration: inPrayer.isInPrayer ? 700.ms : 0.ms,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isInPrayerDelayed
                ? Icon(
                    inPrayer.hasPrayedFor(name.id!)
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    // key: ValueKey<bool>(inPrayer.isInPrayer),
                    // immediate change to/from checked
                    key: ValueKey<bool>(inPrayer.hasPrayedFor(name.id!)), // bounce change to/from checked
                    // size: 22,
                    color: Theme.of(context).colorScheme.primary)
                : Icon(Icons.chevron_right_rounded,
                    key: ValueKey<IconData>(Icons.chevron_right_rounded),
                    // size: 22,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3)))
      ]),
      titleAlignment: ListTileTitleAlignment.titleHeight,
    );
  }
}

class _SubtitleText extends StatelessWidget {
  final String text;

  const _SubtitleText(this.text);

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: subtitleOpacity,
        child: Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          maxLines: 1,
        ));
  }
}

class _SubtitleNumber extends StatelessWidget {
  final int number;

  const _SubtitleNumber(this.number);

  @override
  Widget build(BuildContext context) {
    return _SubtitleText(abbreviatedNumber(number));
  }
}

class _ScheduledPrayerRoll extends StatelessWidget {
  final bool isActive;

  const _ScheduledPrayerRoll({this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Opacity(
            opacity: subtitleOpacity,
            child: AnimatedSwitcher(
                duration: 100.ms,
                child: Icon(
                  key: isActive
                      ? ValueKey<IconData>(Icons.toggle_on)
                      : ValueKey<IconData>(Icons.toggle_off_outlined),
                  isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                  // isCancelled ? Icons.event_busy_rounded : Icons.event_repeat_rounded,
                  size: 16,
                  // color: Theme.of(context).colorScheme.secondary,
                  // color: Color.fromRGBO(171, 83, 83, 1),
                  // color: Colors.deepPurpleAccent,
                ))),
        _SubtitleDivider(),
      ],
    );
  }
}

class _ScheduledPrayerRoll2 extends StatelessWidget {
  final bool isActive;

  const _ScheduledPrayerRoll2({this.isActive = false});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return SizedBox(width: 0, height: 0);

    return Row(
      children: [
        // _SubtitleDivider(),
        Icon(PlusPrayer.plus_dots_list,
            size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
        _SubtitleDivider(),
        // Opacity(
        //     opacity: subtitleOpacity,
        //     child: AnimatedSwitcher(
        //         duration: 100.ms,
        //         child: Icon(
        //           key: isActive
        //               ? ValueKey<IconData>(Icons.toggle_on)
        //               : ValueKey<IconData>(Icons.toggle_off_outlined),
        //           isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
        //           // isCancelled ? Icons.event_busy_rounded : Icons.event_repeat_rounded,
        //           size: 16,
        //           // color: Theme.of(context).colorScheme.secondary,
        //           // color: Color.fromRGBO(171, 83, 83, 1),
        //           // color: Colors.deepPurpleAccent,
        //         ))),
      ],
    );
  }
}

class _SubtitleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3),
      thickness: .5,
      indent: 7,
      endIndent: 4,
      width: 24,
    );
  }
}

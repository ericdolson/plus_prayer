import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_name.dart';
import 'package:plusprayer/hooks/use_names.dart';
import 'package:plusprayer/hooks/use_screen_size.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/widgets/framework/PPAvatar.dart';
import 'package:plusprayer/widgets/framework/card_group.dart';
import 'package:plusprayer/widgets/framework/controls/action_switch.dart';
import 'package:plusprayer/widgets/framework/two_tone_pray_icon.dart';

import '../../../hooks/use_currentMetrics.dart';
import '../../../hooks/use_current_date.dart';
import '../../../hooks/use_historicalMetrics.dart';
import '../../../hooks/use_prayed_for_current_roll.dart';
import '../../../hooks/use_prayed_for_name_today.dart';
import '../../../hooks/use_userLastCommunityPrayer.dart';
import '../../../models/name.dart';
import '../../../presentation/themes.dart';
import '../../framework/surface_card.dart';
import '../../names/name_cannot_pray_dialog.dart';
import '../../names/name_prayed_status.dart';
import 'name_screen_create_update_name.dart';

class NameScreen extends HookWidget {
  final String nameId;

  const NameScreen({super.key, required this.nameId});

  @override
  Widget build(BuildContext context) {
    // get the :id from the route from GoRouter
    // final id = use

    final useNameData = useName(nameId);

    if (useNameData.loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentDate = useCurrentDateKey();
    final name = useMemoized(() => useNameData.name!, [useNameData]);
    final currentMetrics = useCurrentMetrics();
    final historicalMetrics = useHistoricalMetrics();
    final didPrayForCurrentRoll = usePrayedForCurrentRoll();
    final ppCountToday = useMemoized(() => name.ppCounts[currentDate] ?? 0, [name, currentDate]);

    final onCurrentPrayerRoll = useMemoized(
        () => name.onRoll.contains(currentMetrics.currentRollId), [name, currentMetrics.date]);

    final totalCommunityPrayers = useMemoized(
        () =>
            historicalMetrics.totalPrayersByRolls(name.onRoll) +
            (name.isOnRoll ? currentMetrics.prayerCount : 0),
        [name, historicalMetrics, currentMetrics]);

    return Scaffold(
      appBar: AppBar(
        // title: Text('Name is ${name.alias ?? name.name}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        actionsIconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.delete_rounded),
          //   onPressed: () {
          //     name.delete();
          //     context.pop();
          //   },
          // ),
          // ActionSwitch(
          //     onChanged: (value) {
          //       name.setSelected(value);
          //     },
          //     value: name.selected,
          //     label: 'Place on prayer list'),
          // IconButton(
          //   icon: Icon(Icons.ios_share_rounded),
          //   onPressed: () {
          //     // name.delete();
          //     // Navigator.pop(context);
          //   },
          // ),
          Padding(
              padding: EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Icon(Icons.edit_rounded),
                onPressed: () {
                  showCreateUpdateName(
                      context: context,
                      name: name,
                      onDelete: () {
                        name.delete();
                        context.pop();
                      });
                },
              ))
        ],
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
          width: 70,
          height: 70,
          child: FloatingActionButton(
              foregroundColor: Colors.white,
              elevation: 3,
              shape: CircleBorder(),
              onPressed: () {
                if (didPrayForCurrentRoll) {
                  name.incrementPPCount();
                  // showPrayerModal(
                  //     context: context,
                  //     onPrayerAdded: () {
                  //       userSettingsState.haptic(HapticFeedback.lightImpact);
                  //       liveReaction();
                  //     });
                } else {
                  showCannotPrayDialog(context);
                }
                // userCommunityPrayerDelta.value++;
                // Prayer.logCommunityPrayer();
                // showPrayerModal(
                //     context: context,
                //     onPrayerAdded: () {
                //       userSettingsState.haptic(HapticFeedback.lightImpact);
                //       liveReaction();
                //     });
              },
              child: Icon(PlusPrayer.praying_hands, size: 24),
              // child: didPrayForCurrentRoll
              //     ? TwoTonePrayIcon(color: Colors.white, selected: ppCountToday > 0, size: 26)
              //     : Icon(
              //         PlusPrayer.praying_hands_locked,
              //         size: 26,
              //         color: Color.fromRGBO(150, 150, 150, 1),
              //       ),
              backgroundColor: true || didPrayForCurrentRoll
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceTint)),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
            left: 22, right: 22, bottom: MediaQuery.of(context).padding.bottom + 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Center(
              child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PPAvatar.fromName(
              name: name,
              radius: 48,
            ),
          )),
          SizedBox(height: 20),

          // Alias ?? Name
          Center(
              child: FittedBox(
            fit: BoxFit.scaleDown,
            child: FancyText(name.alias ?? name.name, style: TextStyle(fontSize: 32)),
          )),

          // Name if we have an alias
          if ((name.alias ?? '').isNotEmpty)
            Center(
                child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(name.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
            )),

          // On current prayer roll
          if (onCurrentPrayerRoll) SizedBox(height: 8),
          if (onCurrentPrayerRoll)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  // Icons.verified_rounded,
                  PlusPrayer.plus_dots_list,
                  color: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text('On current prayer list',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor)),
              ],
            ),

          // Prayed today status
          SizedBox(height: 8),
          NameScreenPrayedStatus(prayerCount: ppCountToday),

          // Intention
          if (name.intention != null) SizedBox(height: 14),
          if (name.intention != null)
            SurfaceCard.tinted(
                child: Text(
              name.intention!,
              style: fancyTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),

          // Settings
          CardGroup(title: 'Settings', children: [
            CardGroupListTile(
              leading: Icon(
                PlusPrayer.plus_dots_list,
                size: 22,
              ),
              title: Text('Community prayer list'),
              subtitle: Text('Will be placed when eligable'),
              trailing: Switch(
                  // applyTheme: true,
                  value: name.selected,
                  onChanged: (value) {
                    name.setSelected(value);
                  }),
            ),
            CardGroupDivider(),
            CardGroupListTile(
              leading: Icon(Icons.schedule_rounded),
              title: Text('Reminders'),
              subtitle: Text('No reminders scheduled'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
            // CardGroupDivider(),
            // CardGroupListTile(
            //   leading: Icon(
            //     Icons.local_fire_department_rounded,
            //     color: Colors.orangeAccent,
            //   ),
            //   title: Text('4 days', style: TextStyle(fontWeight: FontWeight.w500)),
            //   subtitle: Text('Current personal prayer streak'),
            // ),
          ]),

          // Prayer stats
          CardGroup(
            title: 'PRAYER STATS',
            color: Theme.of(context).colorScheme.surface,
            children: [
              // CardGroupListTile(
              //   leading: Icon(
              //     Icons.local_fire_department_rounded,
              //     color: Colors.orangeAccent,
              //   ),
              //   title: Text('${name.totalPPCount} day streak!', style: TextStyle(fontWeight: FontWeight.w600)),
              //   subtitle: Text('Best: 32 days'),
              //   trailing: Icon(Icons.chevron_right_rounded),
              // ),
              // CardGroupDivider(),
              CardGroupListTile(
                leading: Icon(
                  Icons.person_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text('${name.totalPPCount}', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Personal prayers'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              CardGroupDivider(),
              CardGroupListTile(
                leading: Icon(
                  Icons.groups_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title:
                    Text('$totalCommunityPrayers', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Community prayers'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              CardGroupDivider(),
              CardGroupDivider(),
              CardGroupListTile(
                leading: Opacity(opacity: 0, child: Icon(Icons.functions_rounded)),
                title: Text(
                  'Total prayers',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: FancyText('${name.totalPPCount + totalCommunityPrayers}',
                    style: TextStyle(fontSize: 18)),
              ),
            ],
          ),

          // SizedBox(height: 24),
          // Container(
          //   height: 100,
          //   child:Center(child: OutlinedButton.icon(
          //     style: OutlinedButton.styleFrom(
          //       iconColor: Colors.redAccent,
          //       foregroundColor: Colors.blue,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(24),
          //         side: BorderSide(color: Colors.redAccent, width: 1)
          //       ),
          //     ),
          //     onPressed: () {
          //       name.delete();
          //       context.pop();
          //     },
          //     icon: const Icon(Icons.light),
          //     label: const Text('OutlinedButton'),
          //     iconAlignment: IconAlignment.start,
          //   ),)
          // )
        ]),
      ),
    );
  }
}

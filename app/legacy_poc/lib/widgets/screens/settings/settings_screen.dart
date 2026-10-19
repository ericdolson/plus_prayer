import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:plusprayer/hooks/use_user.dart';
import 'package:plusprayer/hooks/use_user_settings.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/framework/card_group.dart';
import 'package:plusprayer/widgets/screens/settings/anonymous_logout_modal.dart';

void showSettingsBottomSheet(BuildContext context) {
  userSettingsState.haptic(HapticFeedback.selectionClick);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    elevation: 0,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    builder: (BuildContext context) {
      return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            if (notification.extent - .0000001 < notification.minExtent) {
              Navigator.pop(context);
            }
            return true;
          },
          child: DraggableScrollableSheet(
              expand: false,
              snap: true,
              shouldCloseOnMinExtent: true,
              initialChildSize: 1,
              minChildSize: .001,
              controller: DraggableScrollableController(),
              builder: (context, scrollController) {
                return SettingsScreen(scrollController: scrollController);
              }));
    },
  );
}

class ColorSchemeData {
  final String label;
  final IconData icon;

  const ColorSchemeData(this.label, this.icon);
}

enum ColorScheme {
  dark(ColorSchemeData('Dark', Icons.dark_mode_rounded)),
  light(ColorSchemeData('Light', Icons.light_mode_outlined)),
  system(ColorSchemeData('System', Icons.brightness_4_outlined));

  final ColorSchemeData meta;

  const ColorScheme(this.meta);
}

class SettingsScreen extends HookWidget {
  ScrollController scrollController;

  SettingsScreen({super.key, required this.scrollController});

  // const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userSettings = useUserSettings();
    final packageVersion = useState<String?>(null);
    final user = useUser();
    final auth = useAuth();
    final colorScheme = useMemoized(() {
      if (userSettings.isSystemMode) {
        return ColorScheme.system;
      } else if (userSettings.isLightMode) {
        return ColorScheme.light;
      } else {
        return ColorScheme.dark;
      }
    }, [userSettings.mode, userSettings.isSystemMode]);
    ;

    // Effect that can await async functions
    useEffect(() {
      void getPackageInfo() async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        packageVersion.value = '${packageInfo.version}+${packageInfo.buildNumber}';
      }

      getPackageInfo();
    }, [2]);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 16),
              child: Opacity(
                  opacity: .5,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      context.pop();
                    },
                  )))
        ],
        // backgroundColor: Colors.red,
        scrolledUnderElevation: 0,
        // toolbarHeight: 60,
        title: Container(
            // height: 60,
            padding: EdgeInsets.symmetric(vertical: 15),
            // child: PlusPrayerLogoText(fontSize: 32,)),
            child: SvgPicture.asset(
              'assets/img/+_prayer.svg',
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface.withValues(alpha:.8), BlendMode.srcIn),
              // width: 48,
              // color: Colors.blue, // optional, if you want to tint it
            )),
      ),
      body: ListView(
          controller: scrollController,
          padding: EdgeInsets.symmetric(horizontal: 20),
          physics: RangeMaintainingScrollPhysics(),
          children: [
            CardGroup(title: 'Account', children: [
              const CardGroupListTile(
                leading: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                ),
                title: Text('Go PLUS'),
                subtitle: Text('Only \$2.99/month'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              CardGroupDivider(),
              // Opacity(opacity: .1, child: Divider()),
              if (user.isAnonymous)
                CardGroupListTile(
                  leading: Icon(Icons.cloud_upload_outlined),
                  title: Text('Free cloud backup'),
                  subtitle: Text('Sign in with an account'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              if (user.isAnonymous) CardGroupDivider(),
              if (user.isLoggedIn)
                CardGroupListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Sign out'),
                  subtitle: user.isAnonymous
                      ? Text('Using as guest')
                      : Text('${user.emailFromDataOrUser}'),
                  onTap: () {
                    userSettings.haptic(HapticFeedback.selectionClick);

                    if (user.isAnonymous) {
                      showAnonymousLogoutSheet(context);
                    } else {
                      context.go('/login');
                      auth.logout();
                    }
                  },
                ),
            ]),
            CardGroup(
              title: 'Experience',
              children: [
                CardGroupListTile(
                  title: Row(children: [
                    Text('Color Scheme'),
                    Expanded(flex: 1, child: SizedBox.shrink()),
                    Text(colorScheme.meta.label,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.6))),
                    SizedBox(width: 10),
                    Icon(Icons.unfold_more_rounded)
                  ]),
                  leading: Icon(colorScheme.meta.icon),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      enableDrag: true,
                      isDismissible: true,
                      showDragHandle: true,
                      builder: (BuildContext context) {
                        return SafeArea(
                            child: Wrap(
                          spacing: 10,
                          children: [
                            ListTile(
                              title: _ColorSchemeOption(
                                  label: ColorScheme.light.meta.label,
                                  icon: ColorScheme.light.meta.icon,
                                  selected: colorScheme == ColorScheme.light),
                              onTap: () {
                                userSettings.isLightMode = true;
                                Navigator.pop(context);
                              },
                            ),
                            _BottomSheetDivider(),
                            ListTile(
                              title: _ColorSchemeOption(
                                  label: ColorScheme.dark.meta.label,
                                  icon: ColorScheme.dark.meta.icon,
                                  selected: colorScheme == ColorScheme.dark),
                              onTap: () {
                                userSettings.isDarkMode = true;
                                Navigator.pop(context);
                              },
                            ),
                            _BottomSheetDivider(),
                            ListTile(
                              title: _ColorSchemeOption(
                                  label: ColorScheme.system.meta.label,
                                  icon: ColorScheme.system.meta.icon,
                                  selected: colorScheme == ColorScheme.system),
                              onTap: () {
                                userSettings.useSystemMode = true;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ));
                      },
                    );
                    // showCupertinoModalPopup<void>(
                    //   context: context,
                    //   builder: (BuildContext context) => CupertinoActionSheet(
                    //     // title: const Text('Color Scheme'),
                    //     actions: <CupertinoActionSheetAction>[
                    //       CupertinoActionSheetAction(
                    //         /// This parameter indicates the action would be a default
                    //         /// default behavior, turns the action's text to bold text.
                    //         onPressed: () {
                    //           userSettings.useSystemMode = true;
                    //           Navigator.pop(context);
                    //         },
                    //         child: _ColorSchemeOption(
                    //             label: 'System', color: Theme.of(context).colorScheme.onSurface),
                    //       ),
                    //       CupertinoActionSheetAction(
                    //         onPressed: () {
                    //           userSettings.isLightMode = true;
                    //           Navigator.pop(context);
                    //         },
                    //         child: _ColorSchemeOption(
                    //             label: 'Light', color: Theme.of(context).colorScheme.onSurface),
                    //       ),
                    //       CupertinoActionSheetAction(
                    //
                    //           /// This parameter indicates the action would perform
                    //           /// a destructive action such as delete or exit and turns
                    //           /// the action's text color to red.
                    //           onPressed: () {
                    //             userSettings.isDarkMode = true;
                    //             Navigator.pop(context);
                    //           },
                    //           child: _ColorSchemeOption(
                    //               label: 'Dark',
                    //               color: Theme.of(context).colorScheme.onSurface)),
                    //     ],
                    //   ),
                    // );
                  },
                ),
                CardGroupDivider(),
                CardGroupListTile(
                  title: Text('Haptic Feedback'),
                  trailing: Switch(
                      // applyTheme: true,
                      value: userSettings.useHaptics,
                      onChanged: (value) {
                        userSettings.useHaptics = value;
                        userSettings.haptic(HapticFeedback.selectionClick);
                      }),
                  leading: Icon(Icons.vibration_rounded),
                ),
                CardGroupDivider(),
                CardGroupListTile(
                  title: Text('Live Prayers'),
                  trailing: Switch(
                      // applyTheme: true,
                      value: userSettings.showLivePrayers,
                      onChanged: (value) {
                        userSettings.showLivePrayers = value;
                        userSettings.haptic(HapticFeedback.selectionClick);
                      }),
                  leading: Icon(PlusPrayer.praying_hands),
                ),
                CardGroupDivider(),
                CardGroupListTile(
                  title: Row(children: [
                    Text('Language'),
                    Expanded(flex: 1, child: SizedBox.shrink()),
                    Text('English',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.6))),
                    SizedBox(width: 10),
                    Icon(Icons.unfold_more_rounded)
                  ]),
                  leading: Icon(Icons.language_rounded),
                  onTap: () {
                    // Navigator.of(context).push(MaterialPageRoute(builder: (context) => PeriodScreen()));
                    // clear CacheNetworkImage cache
                    ;
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            // _MetadataText('Made with ❤️'),
            // SizedBox(height: 8),
            // SurfaceCard(tinted: true, padding: EdgeInsets.all(6), child: Column(children: [
            GestureDetector(
              onTap: () {
                userSettings.haptic(HapticFeedback.selectionClick);
                final copiedText =
                    'version: ${packageVersion.value}\nemail: ${user.isAnonymous ? 'Guest' : user.email}\nuserID: ${user.authUser?.uid}';
                Clipboard.setData(ClipboardData(
                    text: copiedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(duration: 1.seconds, content: Center(child: Text("Copied to clipboard"))),
                );
              },
              child: Column(children: [
                _MetadataText('© ${DateTime.now().year} Plus Prayer, LLC'),
                if (packageVersion.value != null) _MetadataText('Version ${packageVersion.value!}'),
                if (user.email != null) _MetadataText(user.email!),
                if (user.isAnonymous) _MetadataText('Using as guest'),
                if (user.authUser?.uid != null) _MetadataText(user.authUser!.uid),
              ]),
            ),
            // ]))
            // if (user.authUser != null)
            //   Text(user.authUser!.uid,
            //       textAlign: TextAlign.center,
            //       style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3))),
          ]),
    );
  }
}

class _MetadataText extends StatelessWidget {
  final String text;

  const _MetadataText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style:
          TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.3), fontSize: 12),
    );
  }
}

class _BottomSheetDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.1),
      height: 0,
      thickness: .5,
    );
  }
}

class _ColorSchemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _ColorSchemeOption({required this.label, required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check,
          color: Colors.transparent,
          size: 16,
        ),
        const SizedBox(width: 10),
        Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(width: 10),
        Icon(Icons.check,
            color: selected
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha:.6)
                : Colors.transparent,
            size: 16),
      ],
    );
  }
}

// class _ColorSchemeOption extends StatelessWidget {
//   final String label;
//   final Color color;
//
//   const _ColorSchemeOption({required this.label, this.color = Colors.black});
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       label,
//       style: TextStyle(color: color),
//     );
//   }
// }

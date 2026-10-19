import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/main.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/framework/two_tone_icon.dart';

import '../../presentation/logo.dart';
import '../prayers/prayer_modal.dart';

void showCannotPrayDialog(BuildContext context) {
  showDialog(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return CannotPrayDialog2()
          .animate()
          // .fadeIn(duration: 3000.ms, curve: Curves.easeOutCirc)
          .moveY(begin: 100, end: 0, duration: 300.ms, curve: Curves.easeOutCirc);
    },
  );
}

class CannotPrayDialog extends StatelessWidget {
  const CannotPrayDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24),
      title: Row(children: [
        Icon(Icons.lock_outline_rounded,
            size: 24, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
        SizedBox(width: 8),
        const Text('Community first', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
      ]),
      content: IntrinsicHeight(
          child: Column(children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface.withValues(alpha:.75), BlendMode.srcIn),
          child: Image.asset(
            'assets/img/line_community.png',
            // height: 100, // Set desired height
            fit: BoxFit.contain,
          ),
        ),
        const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
                'You have not prayed for the current community prayer list yet. Please do so '
                'before logging personal prayers.'
                '\n\n'
                '+Prayer is built to encourage a culture of praying for others/strangers who '
                'have asked to be prayed for and to build a sense of community and support for each'
                ' other ❤.️'))
      ])),
      // actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Ok'),
        ),
        FilledButton.icon(
          onPressed: () {
            showPrayerModal(context: context, onPrayerAdded: () {});
          },
          label: Text('Community', style: TextStyle(color: Colors.white)),
          icon: Icon(PlusPrayer.praying_hands, color: Colors.white),
        ),
      ],
    );
  }
}

class CannotPrayDialog2 extends StatelessWidget {
  const CannotPrayDialog2({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.hardEdge,
      child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: IntrinsicHeight(
              child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(PlusPrayer.praying_hands_locked,
                  size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
              SizedBox(width: 6),
              Icon(Icons.arrow_right_alt_rounded,
                  size: 30, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.25)),
              SizedBox(width: 2),
              Icon(Icons.lock_open_rounded,
                  size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
            ]),
            SizedBox(height: 16),
            const Text(
                'Please pray for the current community prayer list before logging personal prayers',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Opacity(opacity: 0, child: TextButton(onPressed: null, child: const Text('Ok'))),
              Material(
                  color: Colors.transparent, // Set to transparent so only the button shows
                  elevation: 3, // Adjust elevation as needed
                  shape: CircleBorder(), // Ensures it stays circular like IconButton
                  child: IconButton.filled(
                    onPressed: () {
                      showPrayerModal(context: context, onPrayerAdded: () {});
                    },
                    iconSize: 26,
                    padding: const EdgeInsets.all(24),
                    icon: Icon(
                      PlusPrayer.praying_hands,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black.withValues(alpha:.1), blurRadius: 20)],
                    ),
                  )),
              TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Ok')),
            ]),
            SizedBox(height: 24),
            Image(image: remoteAppImgProvider(AppImageType.hands)),
          ]))),
      // actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

class CannotPrayDialog3 extends StatelessWidget {
  const CannotPrayDialog3({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.hardEdge,
      child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: IntrinsicHeight(
              child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded,
                  size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
              Icon(Icons.arrow_right_alt_rounded,
                  size: 30, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.25)),
              Icon(Icons.lock_open_rounded,
                  size: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
            ]),
            SizedBox(height: 16),
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface.withValues(alpha:.6), BlendMode.srcIn),
              child: Image.asset(
                'assets/img/line_community.png',
                // height: 100, // Set desired height
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24),
            const Text(
                'Please pray for the current community prayer list before logging personal prayers',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Opacity(opacity: 0, child: TextButton(onPressed: null, child: const Text('Ok'))),
              Material(
                  color: Colors.transparent, // Set to transparent so only the button shows
                  elevation: 3, // Adjust elevation as needed
                  shape: CircleBorder(), // Ensures it stays circular like IconButton
                  child: IconButton.filled(
                    onPressed: () {
                      showPrayerModal(context: context, onPrayerAdded: () {});
                    },
                    iconSize: 26,
                    padding: const EdgeInsets.all(24),
                    icon: Icon(
                      PlusPrayer.praying_hands,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black.withValues(alpha:.1), blurRadius: 20)],
                    ),
                  )),
              TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Ok')),
            ]),
            SizedBox(height: 24),
          ]))),
      // actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

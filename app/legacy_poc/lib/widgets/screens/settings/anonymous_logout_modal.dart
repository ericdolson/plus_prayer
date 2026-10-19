import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:plusprayer/widgets/framework/bottom_sheet.dart';

void showAnonymousLogoutSheet(BuildContext context) {
  makeBottomSheet(context, _AnonymousLogoutModal());
}

class _AnonymousLogoutModal extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final auth = useAuth();

    return SafeArea(
        child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: IntrinsicHeight(
          child: Column(children: [
        Text('Sign out in as guest...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        SizedBox(height: 16),
        const Text(
            'Your data will be lost. Sign in with Apple or Google first if you want to preserve your data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14)),
        SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: context.pop, child: const Text('Cancel')),
          SizedBox(width: 24),
          FilledButton(onPressed: () {}, child: const Text('Sign in...')),
        ]),
        SizedBox(height: 8),
        TextButton.icon(
            icon: const Icon(Icons.warning_rounded, size: 16),
            label: const Text('Continue to sign out'),
            onPressed: () async {
              context.go('/login');
              auth.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)),
      ])),
    ));
  }
}

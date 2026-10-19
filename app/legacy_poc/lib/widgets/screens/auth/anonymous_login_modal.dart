import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:plusprayer/widgets/framework/bottom_sheet.dart';

void showAnonymousLoginSheet(BuildContext context) {
  makeBottomSheet(context, _AnonymousLoginSheetContent());
}

class _AnonymousLoginSheetContent extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final auth = useAuth();

    return Column(children: [
      Text('Skip sign in...',
          textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      SizedBox(height: 16),
      const Text(
          'To save your progress safely in the cloud and across devices, we recommend signing in with Apple or Google. You can always do this later!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14)),
      SizedBox(height: 24),
      FilledButton(onPressed: context.pop, child: const Text('Back to Sign in')),
      SizedBox(height: 8),
      TextButton(
          onPressed: () async {
            context.pop();
            await auth.signInAnonymously();
          },
          child: const Text('Continue as guest')),
    ]);
  }
}

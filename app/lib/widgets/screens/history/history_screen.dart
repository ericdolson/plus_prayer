import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:plusprayer/presentation/text.dart';

class HistoryScreen extends HookWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Name is ${name.alias ?? name.name}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
          onPressed: () {
            context.pop();
          },
        ),
        title: FancyText('History'),
        actionsIconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.ios_share_rounded),
        //     onPressed: () {
        //     },
        //   ),
        //   Padding(
        //       padding: EdgeInsets.only(right: 12),
        //       child: IconButton(
        //         icon: Icon(Icons.edit_rounded),
        //         onPressed: () {
        //         },
        //       ))
        // ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            left: 24, right: 24, bottom: MediaQuery.of(context).padding.bottom + 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NameCard(name: name),
            // SizedBox(height: 24),
            // NamePrayedStatus(name: name),
            // SizedBox(height: 24),
            // NameCannotPrayDialog
      ])),
    );
  }
}

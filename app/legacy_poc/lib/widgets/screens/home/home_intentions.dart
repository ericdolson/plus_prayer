import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HomeIntentions extends HookWidget {
  final double bottomPadding;
  final bool filterUnprayed;

  const HomeIntentions({super.key, this.bottomPadding = 0, this.filterUnprayed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Center(child: Text('intentions')),
    ).animate().fadeIn();
  }
}

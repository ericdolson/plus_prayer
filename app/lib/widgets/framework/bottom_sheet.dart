import 'package:flutter/material.dart';

void makeBottomSheet(BuildContext context, Widget widget) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    enableDrag: true,
    isDismissible: true,
    builder: (BuildContext builder) {
      return BottomSheetWrapper(
        child: widget,
      );
    },
  );
}

class BottomSheetWrapper extends StatelessWidget {
  final Widget child;

  const BottomSheetWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: IntrinsicHeight(child: child),
      ),
    );
  }
}

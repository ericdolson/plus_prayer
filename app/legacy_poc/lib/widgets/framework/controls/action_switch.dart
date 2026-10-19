import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';

class ActionSwitch extends HookWidget {
  final Color? color;
  final String? label;
  final Function(bool) onChanged;
  final bool value;

  const ActionSwitch({
    super.key,
    this.color,
    this.label,
    required this.onChanged,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.primary;
    final inPrayer = useInPrayer();

    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // TextButton.icon(onPressed: () {}, label: Text('Filter'), icon: Icon(Icons.filter_list_rounded),),
      // IconButton(onPressed: () {}, icon: Icon(Icons.search_rounded)),
      GestureDetector(
          onTap: () {
            onChanged(!value);
          },
          child: Container(
              color: Colors.transparent,
              // Need this transparent color to make the GestureDetector work with expanded boundaries
              padding: const EdgeInsets.fromLTRB(0, 8, 4, 8),
              child: Row(children: [
                if (label != null)
                  Text(label!,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5))),
                if (label != null) const SizedBox(width: 4),
                SizedBox(
                    width: 30,
                    // height: 20,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Switch(
                        trackColor: WidgetStateColor.resolveWith(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return color ?? fallbackColor;
                            }
                            return Colors.transparent;
                          },
                        ),
                        trackOutlineColor: WidgetStateColor.resolveWith(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return color ?? fallbackColor;
                            }
                            return Theme.of(context).colorScheme.onSurface;
                          },
                        ),
                        value: value,
                        onChanged: onChanged,
                      ),
                    )),
              ])))
    ]));
  }
}

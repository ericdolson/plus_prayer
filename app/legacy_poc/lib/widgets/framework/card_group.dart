import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/widgets/framework/surface_card.dart';

class CardGroup extends HookWidget {
  final List<Widget> children;
  final Color? color;
  final String? title;
  final IconData? titleIcon;

  const CardGroup({required this.children, this.color, this.title, this.titleIcon});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 15),
      Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(children: [
            if (titleIcon != null) ...[
              Icon(titleIcon,
                  size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)),
              const SizedBox(width: 5)
            ],
            if (title != null)
              Text(title!.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.5)))
          ])),
      const SizedBox(height: 2),
      SurfaceCard(
          padding: EdgeInsets.zero,
          child: Material(
              color: Colors.transparent, // Use transparent to see the Container's decoration
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [...children],
              ))),
      const SizedBox(height: 15),
    ]);
  }
}

class CardGroupListTile extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CardGroupListTile(
      {required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      contentPadding: const EdgeInsets.only(left: 16, right: 20),
      // titleTextStyle: TextStyle(
      //     color: Theme.of(context).colorScheme.onSurface,
      //     fontSize: 15,
      //     // fontWeight: FontWeight.w500
      // ),
      subtitle: subtitle,
      subtitleTextStyle:
          TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.6), fontSize: 12),
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      visualDensity: VisualDensity.compact,
      // dense: true,
    );
  }
}

class CardGroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: 52,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:.1),
      height: 3,
      thickness: .5,
    );
  }
}

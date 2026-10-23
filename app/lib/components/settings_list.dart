// Grouped settings rows (You), from the POC's CardGroup: flat tonal cards on
// the ground with hairlines inset to the text. Quieter than the POC: no leading
// icons, sentence-case section titles, more air between groups.

import 'package:flutter/material.dart';

import '../theme/pp_icons.dart';
import '../theme/pp_theme.dart';

/// A titled (or untitled) card of rows, hairlines between them.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: pp.space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.only(start: pp.space.inset, bottom: pp.space.sm),
              child: Semantics(
                header: true,
                child: Text(title!, style: context.text.labelMedium),
              ),
            ),
          Material(
            color: pp.colors.cardSurface,
            borderRadius: BorderRadius.circular(pp.size.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(indent: pp.space.inset, height: 1),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What sits at the end of a row.
enum SettingsAccessory { none, chevron, menu }

/// One row: title, optional subtitle, optional value and trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.accessory = SettingsAccessory.none,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// The current choice, in muted ink before the accessory ("Dark").
  final String? value;
  final Widget? trailing;
  final SettingsAccessory accessory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final c = pp.colors;
    final icon = switch (accessory) {
      SettingsAccessory.none => null,
      SettingsAccessory.chevron => PPIcons.chevron,
      SettingsAccessory.menu => PPIcons.choose,
    };
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: pp.size.settingsRow),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(pp.space.inset, pp.space.md, pp.space.lg, pp.space.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: context.text.bodyLarge),
                      if (subtitle != null)
                        Padding(
                          padding: EdgeInsetsDirectional.only(top: pp.space.xxs),
                          child: Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                        ),
                    ],
                  ),
                ),
                if (value != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: pp.space.md),
                    child: Text(value!, style: context.text.bodyLarge?.copyWith(color: c.inkMuted)),
                  ),
                if (trailing != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: pp.space.md),
                    child: trailing,
                  ),
                if (icon != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: pp.space.xs),
                    child: Icon(icon, size: pp.size.rowIcon, color: c.inkFaint),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row that is a switch; tapping anywhere on it toggles.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;

  /// Sits between the title and the switch (a reminder's time).
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: context.pp.space.md)],
          // Neutral when on (design-direction.md §1); the iOS switch ignores the
          // theme's track colors, so it's passed here.
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: context.pp.colors.ink,
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? context.pp.colors.background : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row that opens a small menu of choices, checked at the current one
/// (the POC's Color Scheme picker, as a pull-down instead of a sheet).
class SettingsMenuTile<T> extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;

  /// Value → label, in menu order.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.pp.colors;
    final label = options.firstWhere((o) => o.$1 == selected, orElse: () => options.first).$2;
    return MenuAnchor(
      alignmentOffset: Offset(-context.pp.space.lg, 0),
      style: const MenuStyle(alignment: AlignmentDirectional.bottomEnd),
      menuChildren: [
        for (final (value, text) in options)
          MenuItemButton(
            onPressed: () => onSelected(value),
            leadingIcon: Icon(PPIcons.check, color: value == selected ? c.primary : Colors.transparent),
            child: Text(text),
          ),
      ],
      builder: (context, menu, _) => SettingsTile(
        title: title,
        value: label,
        accessory: SettingsAccessory.menu,
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

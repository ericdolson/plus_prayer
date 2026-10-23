// You (settings), opened from the header avatar (screens.md, app-brief §3).
// The POC's full-height settings sheet: drag down or ✕ to close, Home stays
// underneath. Contents follow the spec's list; rows whose screens come in
// build step 6 (name edit, sign-in, membership, Archived, privacy, about,
// delete) are laid out but go nowhere yet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/monogram_avatar.dart';
import '../../components/settings_list.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/reminder.dart';
import '../../domain/rules/avatar.dart';
import '../../domain/rules/membership.dart';
import '../../hooks/use_optimistic.dart';
import '../../l10n/app_localizations.dart';
import '../../state/appearance.dart';
import '../../state/providers.dart';
import '../../theme/pp_icons.dart';
import '../../theme/pp_theme.dart';
import 'reminder_time_sheet.dart';

Future<void> showYouSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: 1,
        // Dragged down to here, the sheet closes.
        minChildSize: .5,
        builder: (context, scroll) => YouSheet(scrollController: scroll),
      ),
    );

/// Build step 6: the screens these rows open.
void _later() {}

class YouSheet extends ConsumerWidget {
  const YouSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final header = ref.watch(headerProvider).value;
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final users = ref.read(userRepositoryProvider);
    final now = ref.watch(clockProvider)();

    return ScaffoldMessenger(
      // Transparent so the sheet's rounded top shows.
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Fixed, so the list scrolls under nothing.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: pp.space.sm),
                child: IconButton(
                  tooltip: l10n.close,
                  color: pp.colors.inkMuted,
                  icon: const Icon(PPIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsetsDirectional.fromSTEB(
                  pp.space.lg,
                  0,
                  pp.space.lg,
                  pp.space.xxxl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  const _Profile(),
                  SizedBox(height: pp.space.xxl),
                  SettingsSection(children: [
                    SettingsTile(
                      title: l10n.youSignIn,
                      subtitle: l10n.youSignInDetail,
                      accessory: SettingsAccessory.chevron,
                      onTap: _later,
                    ),
                    if (header != null)
                      SettingsTile(
                        title: l10n.youMembership,
                        value: switch (membershipState(header, now)) {
                          MembershipState.free => l10n.youMembershipFree,
                          MembershipState.trial => l10n.youMembershipTrial(header.entitlementExpiresAt!),
                          MembershipState.member => l10n.youMembershipActive,
                        },
                        accessory: SettingsAccessory.chevron,
                        onTap: _later,
                      ),
                    SettingsTile(title: l10n.youRestore, onTap: _later),
                  ]),
                  if (reminders.isNotEmpty)
                    SettingsSection(
                      title: l10n.youReminders,
                      children: [
                        for (final r in reminders)
                          if (r.slot != ReminderSlot.custom) _ReminderTile(key: ValueKey(r.slot), reminder: r),
                      ],
                    ),
                  if (header != null) ...[
                    SettingsSection(
                      title: l10n.youNotifications,
                      children: [
                        _SettingSwitch(
                          title: l10n.youListLive,
                          server: header.listLiveOptIn,
                          write: (v) => users.updateSettings(SettingsChange(listLiveOptIn: v)),
                        ),
                        _SettingSwitch(
                          title: l10n.youShowNames,
                          server: header.showNamesInNotifications,
                          write: (v) => users.updateSettings(SettingsChange(showNamesInNotifications: v)),
                        ),
                      ],
                    ),
                    SettingsSection(children: [
                      SettingsMenuTile<ThemeMode>(
                        title: l10n.youAppearance,
                        options: [
                          (ThemeMode.system, l10n.appearanceSystem),
                          (ThemeMode.light, l10n.appearanceLight),
                          (ThemeMode.dark, l10n.appearanceDark),
                        ],
                        selected: ref.watch(themeModeProvider),
                        onSelected: ref.read(themeModeProvider.notifier).set,
                      ),
                      _LanguageTile(server: header.locale),
                      _SettingSwitch(
                        title: l10n.youGraceOffers,
                        server: header.graceOffersEnabled,
                        write: (v) => users.updateSettings(SettingsChange(graceOffersEnabled: v)),
                      ),
                    ]),
                  ],
                  SettingsSection(children: [
                    SettingsTile(title: l10n.youArchived, accessory: SettingsAccessory.chevron, onTap: _later),
                    SettingsTile(title: l10n.youPrivacy, accessory: SettingsAccessory.chevron, onTap: _later),
                    SettingsTile(title: l10n.youAboutRitual, accessory: SettingsAccessory.chevron, onTap: _later),
                  ]),
                  Center(
                    child: TextButton(onPressed: _later, child: Text(l10n.youDeleteAccount)),
                  ),
                  SizedBox(height: pp.space.xxl),
                  const _Colophon(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showOffline(BuildContext context) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(L10n.of(context).errorSettingsOffline)));

/// Your avatar and name, centered — the sheet's title.
class _Profile extends ConsumerWidget {
  const _Profile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final self = ref.watch(subjectTreeProvider).value?.self;
    final name = ref.watch(headerProvider).value?.displayName ?? self?.publicName ?? '';
    return Column(
      children: [
        MonogramAvatar(
          initials: self == null ? '' : monogramOf(self),
          tone: self == null ? 0 : avatarToneOf(self),
          size: pp.size.avatarLarge,
        ),
        SizedBox(height: pp.space.lg),
        Semantics(
          header: true,
          child: Text(name, style: context.text.headlineMedium, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// A synced setting: moves at once, goes back if the write fails.
class _SettingSwitch extends HookWidget {
  const _SettingSwitch({required this.title, required this.server, required this.write});

  final String title;
  final bool server;
  final Future<void> Function(bool) write;

  @override
  Widget build(BuildContext context) {
    final (value, set) = useOptimistic(server, write, onError: (_) => _showOffline(context));
    return SettingsSwitchTile(title: title, value: value, onChanged: set);
  }
}

class _LanguageTile extends HookConsumerWidget {
  const _LanguageTile({required this.server});

  final String? server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final users = ref.read(userRepositoryProvider);
    final (value, set) = useOptimistic<String?>(
      server,
      (code) => users.updateSettings(
        SettingsChange(locale: code == null ? const LocaleChoice.device() : LocaleChoice(code)),
      ),
      onError: (_) => _showOffline(context),
    );
    // English is the only UI language so far.
    return SettingsMenuTile<String?>(
      title: l10n.youLanguage,
      options: [(null, l10n.languageDevice), ('en', l10n.languageEnglish)],
      selected: value,
      onSelected: set,
    );
  }
}

/// Morning / Midday / Evening: the time, then the switch.
class _ReminderTile extends HookConsumerWidget {
  const _ReminderTile({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final users = ref.read(userRepositoryProvider);
    final slot = reminder.slot;
    void offline(Object _) => _showOffline(context);

    final (enabled, setEnabled) =
        useOptimistic(reminder.enabled, (v) => users.setReminder(slot, enabled: v), onError: offline);
    final (time, setTime) =
        useOptimistic(reminder.localTime, (t) => users.setReminder(slot, localTime: t), onError: offline);

    final title = switch (slot) {
      ReminderSlot.morning => l10n.reminderMorning,
      ReminderSlot.midday => l10n.reminderMidday,
      ReminderSlot.evening || ReminderSlot.custom => reminder.label ?? l10n.reminderEvening,
    };
    final label = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return SettingsSwitchTile(
      title: title,
      value: enabled,
      onChanged: setEnabled,
      leading: Semantics(
        label: l10n.reminderTimeFor(title),
        value: label,
        button: true,
        excludeSemantics: true,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: pp.colors.surfaceRaised,
            foregroundColor: enabled ? pp.colors.ink : pp.colors.inkFaint,
            minimumSize: Size.zero,
            padding: EdgeInsetsDirectional.symmetric(horizontal: pp.space.md, vertical: pp.space.xs + pp.space.xxs),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () async {
            final picked = await showReminderTimeSheet(context, title: title, initial: time);
            if (picked != null && picked != time) setTime(picked);
          },
          child: Text(label),
        ),
      ),
    );
  }
}

/// The wordmark, version and copyright. Tap to copy the version and account
/// id for support (the POC did the same).
class _Colophon extends ConsumerWidget {
  const _Colophon();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pp = context.pp;
    final l10n = L10n.of(context);
    final version = ref.watch(appVersionProvider).value;
    final userId = ref.watch(headerProvider).value?.id;
    final faint = context.text.bodySmall?.copyWith(color: pp.colors.inkFaint);
    final year = ref.watch(clockProvider)().year;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Clipboard.setData(ClipboardData(text: 'version: $version\nuser: $userId'));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.youCopied)));
      },
      child: Column(
        children: [
          ExcludeSemantics(
            child: SvgPicture.asset(
              'assets/img/+_prayer.svg',
              height: pp.size.wordmark,
              colorFilter: ColorFilter.mode(pp.colors.inkFaint, BlendMode.srcIn),
            ),
          ),
          SizedBox(height: pp.space.md),
          if (version != null) Text(l10n.youVersion(version), style: faint),
          Text(l10n.youCopyright(year), style: faint),
        ],
      ),
    );
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '+Prayer';

  @override
  String listTitle(int number) {
    return 'List $number';
  }

  @override
  String listScale(int people, int prayers) {
    final intl.NumberFormat peopleNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peopleString = peopleNumberFormat.format(people);
    final intl.NumberFormat prayersNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String prayersString = prayersNumberFormat.format(prayers);

    return '$peopleString people · $prayersString prayers';
  }

  @override
  String listBeingFilmed(int number) {
    return 'List $number, being filmed';
  }

  @override
  String listSealed(int number) {
    return 'List $number, sealed';
  }

  @override
  String carryWillBe(int number) {
    return 'will be on List $number';
  }

  @override
  String cardOnListAre(int number) {
    return 'are on List $number';
  }

  @override
  String cardOnListIs(int number) {
    return 'is on List $number';
  }

  @override
  String cardCovered(int number) {
    return 'They\'ll be on List $number';
  }

  @override
  String cardCoveredYou(int number) {
    return 'You\'ll be on List $number';
  }

  @override
  String cardNextPrayer(int number) {
    return 'Your next prayer carries them onto List $number';
  }

  @override
  String cardNextPrayerYou(int number) {
    return 'Your next prayer carries you onto List $number';
  }

  @override
  String cardPrayToCarry(int number) {
    return 'Pray to carry them onto List $number';
  }

  @override
  String cardPrayToBe(int number) {
    return 'Pray to be on List $number';
  }

  @override
  String cardJoins(String name, int others, int number) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others join you on List $number',
      one: '$name and 1 other join you on List $number',
      zero: '$name joins you on List $number',
    );
    return '$_temp0';
  }

  @override
  String cardNotCarried(String name, int others, int number) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others aren\'t carried on List $number',
      one: '$name and 1 other aren\'t carried on List $number',
      zero: '$name isn\'t carried on List $number',
    );
    return '$_temp0';
  }

  @override
  String get clusterYou => 'You';

  @override
  String clusterTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String clusterCounted(String first, String second, int count) {
    return '$first, $second + $count';
  }

  @override
  String clusterAndOthers(String first, String second) {
    return '$first, $second and others';
  }

  @override
  String clusterOverflow(int count) {
    return '+$count';
  }

  @override
  String closesSoon(int number, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'List $number closes in $_temp0';
  }

  @override
  String presenceNow(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString praying now';
  }

  @override
  String presenceLastHour(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString prayed in the last hour';
  }

  @override
  String presenceToday(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString prayed today';
  }

  @override
  String statusAnswered(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Answered · $dateString';
  }

  @override
  String statusNotCarriedFull(int limit) {
    return 'Not on the list · all $limit places in use';
  }

  @override
  String get heldToday => 'Held today';

  @override
  String get filterAll => 'All';

  @override
  String get filterStillToHold => 'Still to hold';

  @override
  String searchNoMatches(String query) {
    return 'No matches for “$query”';
  }

  @override
  String get searchAdd => 'Add';

  @override
  String searchMatchesInAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString matches in All',
      one: '1 match in All',
    );
    return '$_temp0';
  }

  @override
  String get searchShow => 'Show →';

  @override
  String searchShowMatchesSpoken(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $countString matches in All',
      one: 'Show 1 match in All',
    );
    return '$_temp0';
  }

  @override
  String get carriedHelperMeaning =>
      'Carried means printed on the daily list, and held by everyone who prays it.';

  @override
  String get carriedHelperKeep =>
      'Pray with the list each day to keep them carried.';

  @override
  String get carriedHelperChoose => 'Choose who\'s carried';

  @override
  String get yourPortion => 'Your portion';

  @override
  String get filterEmptyStillToHold => 'Everyone\'s been held today.';

  @override
  String filterCountSpoken(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get filterAllHeldSpoken => 'all held';

  @override
  String get filterCarried => 'Carried';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get clearFilter => 'Show all';

  @override
  String get closeSearch => 'Close search';

  @override
  String get you => 'You';

  @override
  String streakBadge(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days with the world',
      one: '1 day with the world',
      zero: 'Days with the world',
    );
    return '$_temp0';
  }

  @override
  String get history => 'History';

  @override
  String get todaysList => 'Today\'s list';

  @override
  String get add => 'Add';

  @override
  String get pray => 'Pray';

  @override
  String get amen => 'Amen';

  @override
  String prayingWith(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'with $countString';
  }

  @override
  String prayingWithSpoken(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Praying with $countString others',
      one: 'Praying with 1 other',
    );
    return '$_temp0';
  }

  @override
  String get discardPrayer => 'End without saving';

  @override
  String get cancelPrayer => 'Cancel';

  @override
  String get discardPrayerQuestion => 'Discard this prayer?';

  @override
  String get keepPraying => 'Keep praying';

  @override
  String timeInPrayer(String time) {
    return 'Time in prayer $time';
  }

  @override
  String get holding => 'Holding';

  @override
  String get holdingSome => 'Holding some intentions';

  @override
  String invitationHold(int count, int number) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Hold the $countString on List $number in your prayer';
  }

  @override
  String invitationHolding(int count, int number) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Holding the $countString on List $number';
  }

  @override
  String closingCarried(int number) {
    return 'You\'ll be carried on List $number.';
  }

  @override
  String get addNote => 'Add a note';

  @override
  String get noteHint => 'Only you will see this';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String welcomeBackFinish(String time) {
    return 'Welcome back. Finish your prayer from $time?';
  }

  @override
  String get discard => 'Discard';

  @override
  String get addName => 'Add name';

  @override
  String get addIntention => 'Add intention';

  @override
  String addIntentionFor(String name) {
    return 'Add intention for $name';
  }

  @override
  String get kindName => 'Name';

  @override
  String get kindIntention => 'Intention';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldIntention => 'Intention';

  @override
  String get fieldAlias => 'Alias (optional)';

  @override
  String get fieldAliasHelper =>
      'Only you see the alias. The name is what\'s printed.';

  @override
  String get fieldFor => 'For';

  @override
  String offerIntention(String name) {
    return 'Add an intention for $name?';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get errorContact =>
      'Names and intentions can\'t include phone numbers, emails, or links.';

  @override
  String errorTooLong(int cap) {
    return '$cap characters at most';
  }

  @override
  String get errorOffline => 'Adding needs a connection.';

  @override
  String poolMeter(int carried, int limit) {
    return '$carried of $limit';
  }

  @override
  String poolMeterOver(int carried, int limit) {
    return '$carried / $limit';
  }

  @override
  String get errorCap =>
      'This list is very full. Contact us if you need more room.';

  @override
  String get close => 'Close';

  @override
  String get youSignIn => 'Keep your list safe';

  @override
  String get youSignInDetail => 'Sign in with Apple or Google';

  @override
  String get youMembership => 'Membership';

  @override
  String youMembershipTrial(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Trial until $dateString';
  }

  @override
  String get youMembershipActive => 'Member';

  @override
  String get youMembershipFree => 'Free';

  @override
  String get youRestore => 'Restore purchases';

  @override
  String get youReminders => 'Reminders';

  @override
  String get reminderMorning => 'Morning';

  @override
  String get reminderMidday => 'Midday';

  @override
  String get reminderEvening => 'Evening';

  @override
  String reminderTimeFor(String slot) {
    return '$slot reminder time';
  }

  @override
  String get youNotifications => 'Notifications';

  @override
  String get youListLive => 'Today\'s list is live';

  @override
  String get youShowNames => 'Show names in notifications';

  @override
  String get youAppearance => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get youLanguage => 'Language';

  @override
  String get languageDevice => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get youGraceOffers => 'Offer grace days';

  @override
  String get youArchived => 'Archived';

  @override
  String get youPrivacy => 'Privacy & terms';

  @override
  String get youAboutRitual => 'About the ritual';

  @override
  String get youDeleteAccount => 'Delete account';

  @override
  String youVersion(String version) {
    return 'Version $version';
  }

  @override
  String youCopyright(int year) {
    return '© $year Plus Prayer, LLC';
  }

  @override
  String get youCopied => 'Copied';

  @override
  String get errorSettingsOffline => 'Changing this needs a connection.';
}

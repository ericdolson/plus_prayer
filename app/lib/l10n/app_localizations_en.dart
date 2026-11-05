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
  String listPeople(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString people',
      one: '$countString person',
    );
    return '$_temp0';
  }

  @override
  String listPrayers(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString prayers',
      one: '$countString prayer',
    );
    return '$_temp0';
  }

  @override
  String get countsSeparator => '·';

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
    return 'Your next prayer puts you on List $number';
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
    return 'List $number closes in $minutes min · pray to carry them';
  }

  @override
  String closesSoonYou(int number, int minutes, int next) {
    return 'List $number closes in $minutes min · pray to be on List $next';
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
  String presenceShortLastHour(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString prayed this hour';
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
  String rowCarried(String name) {
    return '$name, carried';
  }

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

  @override
  String get historyThisWeek => 'This week';

  @override
  String get historyLastWeek => 'Last week';

  @override
  String historyEarlierIn(DateTime month) {
    final intl.DateFormat monthDateFormat = intl.DateFormat.MMMM(localeName);
    final String monthString = monthDateFormat.format(month);

    return 'Earlier in $monthString';
  }

  @override
  String historyMonth(DateTime month) {
    final intl.DateFormat monthDateFormat = intl.DateFormat.MMMM(localeName);
    final String monthString = monthDateFormat.format(month);

    return '$monthString';
  }

  @override
  String historyYear(DateTime year) {
    final intl.DateFormat yearDateFormat = intl.DateFormat.y(localeName);
    final String yearString = yearDateFormat.format(year);

    return '$yearString';
  }

  @override
  String historyPrayed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You prayed $countString times',
      one: 'You prayed once',
    );
    return '$_temp0';
  }

  @override
  String historyOnLists(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'On $countString lists',
      one: 'On 1 list',
    );
    return '$_temp0';
  }

  @override
  String historyCurrent(String onLists) {
    return '$onLists · current';
  }

  @override
  String historyNotesSpoken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get historyAnswered => 'Answered';

  @override
  String historyBegun(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Begun · $dateString';
  }

  @override
  String historyBegunYear(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Begun · $dateString';
  }

  @override
  String detailCovered(String name, int number) {
    return '$name will be on List $number';
  }

  @override
  String detailNextPrayer(String name, int number) {
    return 'Your next prayer carries $name onto List $number';
  }

  @override
  String detailPrayToCarry(String name, int number) {
    return 'Pray to carry $name onto List $number';
  }

  @override
  String detailCoveredIt(int number) {
    return 'It\'ll be on List $number';
  }

  @override
  String detailNextPrayerIt(int number) {
    return 'Your next prayer carries it onto List $number';
  }

  @override
  String detailPrayToCarryIt(int number) {
    return 'Pray to carry it onto List $number';
  }

  @override
  String detailClosesSoon(int number, int minutes, String name) {
    return 'List $number closes in $minutes min · pray to carry $name';
  }

  @override
  String detailClosesSoonIt(int number, int minutes) {
    return 'List $number closes in $minutes min · pray to carry it';
  }

  @override
  String detailHeldByYou(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Held by you · $countString prayers',
      one: 'Held by you · 1 prayer',
    );
    return '$_temp0';
  }

  @override
  String detailCarriedByWorld(String prayers, String lists) {
    return 'Carried by the world · $prayers · $lists';
  }

  @override
  String detailWorldPrayers(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString prayers',
      one: '1 prayer',
    );
    return '$_temp0';
  }

  @override
  String detailWorldLists(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lists',
      one: '1 list',
    );
    return '$_temp0';
  }

  @override
  String get detailIntentions => 'Intentions';

  @override
  String prayFor(String name) {
    return 'Pray for $name';
  }

  @override
  String get prayForOthers => 'Pray for others';

  @override
  String get back => 'Back';

  @override
  String get more => 'More';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAnswered => 'Answered';

  @override
  String get actionRelease => 'Release';

  @override
  String get actionArchive => 'Archive';

  @override
  String get cancel => 'Cancel';

  @override
  String get releaseQuestion => 'Release this intention? It moves to Archived.';

  @override
  String archiveNameQuestion(String name) {
    return 'Archive $name? Its intentions are archived too.';
  }

  @override
  String archiveQuestion(String name) {
    return 'Archive $name?';
  }

  @override
  String get editName => 'Edit name';

  @override
  String get editIntention => 'Edit intention';

  @override
  String get errorNeedsConnection => 'This needs a connection.';

  @override
  String selfNameTooSoon(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'You can change your name again on $dateString.';
  }
}

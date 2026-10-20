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
    return 'List $number';
  }

  @override
  String listBeingFilmed(int number) {
    return 'List $number, being filmed';
  }

  @override
  String listSealed(int number) {
    return 'List $number, sealed';
  }

  @override
  String carryNotYet(int number) {
    return 'are not yet carried on List $number';
  }

  @override
  String carryWillBe(int number) {
    return 'will be on List $number';
  }

  @override
  String get clusterYou => 'You';

  @override
  String clusterOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count others',
      one: '+ 1 other',
    );
    return '$_temp0';
  }

  @override
  String closesSoon(int number, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'List $number closes in $_temp0';
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
  String get statusPrayedToday => 'Prayed today';

  @override
  String statusLastPrayed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last prayed $days days ago',
      one: 'Last prayed yesterday',
    );
    return '$_temp0';
  }

  @override
  String statusNotCarriedFull(int limit) {
    return 'Not on the list · all $limit places in use';
  }

  @override
  String carriedMark(int number) {
    return 'Carried on List $number';
  }

  @override
  String get unprayedToday => 'Not yet prayed for today';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnprayed => 'Unprayed today';

  @override
  String get filterCarried => 'Carried';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

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

    return 'with $countString others';
  }

  @override
  String get discardPrayer => 'End without saving';

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

    return 'Hold the $countString on List $number in your prayer';
  }

  @override
  String invitationHolding(int count, int number) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Holding the $countString on List $number';
  }

  @override
  String closingCarried(int number) {
    return 'You\'ll be carried on List $number.';
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
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'+Prayer'**
  String get appTitle;

  /// No description provided for @listTitle.
  ///
  /// In en, this message translates to:
  /// **'List {number}'**
  String listTitle(int number);

  /// Screen reader label for the unsealed seal before the list is published.
  ///
  /// In en, this message translates to:
  /// **'List {number}, being filmed'**
  String listBeingFilmed(int number);

  /// No description provided for @listSealed.
  ///
  /// In en, this message translates to:
  /// **'List {number}, sealed'**
  String listSealed(int number);

  /// After the avatar cluster: 'You, Dad ●●● + 4 others are not yet carried on List 53'. Follows the cluster ('You' or 'You, Dad + 4 others').
  ///
  /// In en, this message translates to:
  /// **'are not yet carried on List {number}'**
  String carryNotYet(int number);

  /// No description provided for @carryWillBe.
  ///
  /// In en, this message translates to:
  /// **'will be on List {number}'**
  String carryWillBe(int number);

  /// No description provided for @clusterYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get clusterYou;

  /// No description provided for @clusterOthers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+ 1 other} other{+ {count} others}}'**
  String clusterOthers(int count);

  /// No description provided for @closesSoon.
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String closesSoon(int number, int minutes);

  /// No description provided for @presenceNow.
  ///
  /// In en, this message translates to:
  /// **'{count} praying now'**
  String presenceNow(int count);

  /// No description provided for @presenceLastHour.
  ///
  /// In en, this message translates to:
  /// **'{count} prayed in the last hour'**
  String presenceLastHour(int count);

  /// No description provided for @presenceToday.
  ///
  /// In en, this message translates to:
  /// **'{count} prayed today'**
  String presenceToday(int count);

  /// No description provided for @statusAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered · {date}'**
  String statusAnswered(DateTime date);

  /// No description provided for @statusPrayedToday.
  ///
  /// In en, this message translates to:
  /// **'Prayed today'**
  String get statusPrayedToday;

  /// No description provided for @statusLastPrayed.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Last prayed yesterday} other{Last prayed {days} days ago}}'**
  String statusLastPrayed(int days);

  /// No description provided for @statusNotCarriedFull.
  ///
  /// In en, this message translates to:
  /// **'Not on the list · all {limit} places in use'**
  String statusNotCarriedFull(int limit);

  /// Screen reader text for the carried mark.
  ///
  /// In en, this message translates to:
  /// **'Carried on List {number}'**
  String carriedMark(int number);

  /// Screen reader text for the unprayed dot.
  ///
  /// In en, this message translates to:
  /// **'Not yet prayed for today'**
  String get unprayedToday;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnprayed.
  ///
  /// In en, this message translates to:
  /// **'Unprayed today'**
  String get filterUnprayed;

  /// No description provided for @filterCarried.
  ///
  /// In en, this message translates to:
  /// **'Carried'**
  String get filterCarried;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// Header avatar → You (settings).
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Screen reader text for the header streak badge. At 0 the badge shows no number.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Days with the world} =1{1 day with the world} other{{days} days with the world}}'**
  String streakBadge(int days);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @todaysList.
  ///
  /// In en, this message translates to:
  /// **'Today\'s list'**
  String get todaysList;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @pray.
  ///
  /// In en, this message translates to:
  /// **'Pray'**
  String get pray;

  /// No description provided for @amen.
  ///
  /// In en, this message translates to:
  /// **'Amen'**
  String get amen;

  /// No description provided for @prayingWith.
  ///
  /// In en, this message translates to:
  /// **'with {count} others'**
  String prayingWith(int count);

  /// Screen reader label for ✕ in the prayer bar.
  ///
  /// In en, this message translates to:
  /// **'End without saving'**
  String get discardPrayer;

  /// No description provided for @timeInPrayer.
  ///
  /// In en, this message translates to:
  /// **'Time in prayer {time}'**
  String timeInPrayer(String time);

  /// Screen reader state of a checked row in prayer.
  ///
  /// In en, this message translates to:
  /// **'Holding'**
  String get holding;

  /// No description provided for @holdingSome.
  ///
  /// In en, this message translates to:
  /// **'Holding some intentions'**
  String get holdingSome;

  /// No description provided for @invitationHold.
  ///
  /// In en, this message translates to:
  /// **'Hold the {count} on List {number} in your prayer'**
  String invitationHold(int count, int number);

  /// No description provided for @invitationHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding the {count} on List {number}'**
  String invitationHolding(int count, int number);

  /// No description provided for @closingCarried.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be carried on List {number}.'**
  String closingCarried(int number);

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Only you will see this'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @welcomeBackFinish.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Finish your prayer from {time}?'**
  String welcomeBackFinish(String time);

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @addName.
  ///
  /// In en, this message translates to:
  /// **'Add name'**
  String get addName;

  /// No description provided for @addIntention.
  ///
  /// In en, this message translates to:
  /// **'Add intention'**
  String get addIntention;

  /// No description provided for @addIntentionFor.
  ///
  /// In en, this message translates to:
  /// **'Add intention for {name}'**
  String addIntentionFor(String name);

  /// No description provided for @kindName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get kindName;

  /// No description provided for @kindIntention.
  ///
  /// In en, this message translates to:
  /// **'Intention'**
  String get kindIntention;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldIntention.
  ///
  /// In en, this message translates to:
  /// **'Intention'**
  String get fieldIntention;

  /// No description provided for @fieldAlias.
  ///
  /// In en, this message translates to:
  /// **'Alias (optional)'**
  String get fieldAlias;

  /// No description provided for @fieldAliasHelper.
  ///
  /// In en, this message translates to:
  /// **'Only you see the alias. The name is what\'s printed.'**
  String get fieldAliasHelper;

  /// No description provided for @fieldFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get fieldFor;

  /// No description provided for @offerIntention.
  ///
  /// In en, this message translates to:
  /// **'Add an intention for {name}?'**
  String offerIntention(String name);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @errorContact.
  ///
  /// In en, this message translates to:
  /// **'Names and intentions can\'t include phone numbers, emails, or links.'**
  String get errorContact;

  /// No description provided for @errorTooLong.
  ///
  /// In en, this message translates to:
  /// **'{cap} characters at most'**
  String errorTooLong(int cap);

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'Adding needs a connection.'**
  String get errorOffline;

  /// No description provided for @poolMeter.
  ///
  /// In en, this message translates to:
  /// **'{carried} of {limit}'**
  String poolMeter(int carried, int limit);

  /// No description provided for @poolMeterOver.
  ///
  /// In en, this message translates to:
  /// **'{carried} / {limit}'**
  String poolMeterOver(int carried, int limit);

  /// No description provided for @errorCap.
  ///
  /// In en, this message translates to:
  /// **'This list is very full. Contact us if you need more room.'**
  String get errorCap;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
      'L10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

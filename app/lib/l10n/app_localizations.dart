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
  /// **'List {number}'**
  String listTitle(int number);

  /// Community card, scale first (design-direction.md §6).
  ///
  /// In en, this message translates to:
  /// **'{people} people · {prayers} prayers'**
  String listScale(int people, int prayers);

  /// Screen reader label for the unsealed seal before the list is published.
  ///
  /// In en, this message translates to:
  /// **'List {number}, being filmed'**
  String listBeingFilmed(int number);

  /// No description provided for @listSealed.
  ///
  /// In en, this message translates to:
  /// **'List {number}, sealed'**
  String listSealed(int number);

  /// No description provided for @carryWillBe.
  ///
  /// In en, this message translates to:
  /// **'will be on List {number}'**
  String carryWillBe(int number);

  /// After the avatar row of yours on today's list: 'You, Dad + 3 are on List 52'.
  ///
  /// In en, this message translates to:
  /// **'are on List {number}'**
  String cardOnListAre(int number);

  /// Avatar row with one name that isn't you.
  ///
  /// In en, this message translates to:
  /// **'is on List {number}'**
  String cardOnListIs(int number);

  /// No description provided for @cardCovered.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be on List {number}'**
  String cardCovered(int number);

  /// No description provided for @cardCoveredYou.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be on List {number}'**
  String cardCoveredYou(int number);

  /// No description provided for @cardNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Your next prayer carries them onto List {number}'**
  String cardNextPrayer(int number);

  /// Not in the spec (the 'you' form of cardNextPrayer); for review.
  ///
  /// In en, this message translates to:
  /// **'Your next prayer carries you onto List {number}'**
  String cardNextPrayerYou(int number);

  /// No description provided for @cardPrayToCarry.
  ///
  /// In en, this message translates to:
  /// **'Pray to carry them onto List {number}'**
  String cardPrayToCarry(int number);

  /// No description provided for @cardPrayToBe.
  ///
  /// In en, this message translates to:
  /// **'Pray to be on List {number}'**
  String cardPrayToBe(int number);

  /// Names carried tomorrow that aren't on today's list. The plural forms beyond one name aren't in the spec; for review.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} joins you on List {number}} =1{{name} and 1 other join you on List {number}} other{{name} and {others} others join you on List {number}}}'**
  String cardJoins(String name, int others, int number);

  /// Names on today's list that won't be carried tomorrow (tap → Your portion). Plural forms are for review.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} isn\'t carried on List {number}} =1{{name} and 1 other aren\'t carried on List {number}} other{{name} and {others} others aren\'t carried on List {number}}}'**
  String cardNotCarried(String name, int others, int number);

  /// No description provided for @clusterYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get clusterYou;

  /// Grouped avatars, two people: 'You and Dad are on List 52'.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String clusterTwo(String first, String second);

  /// Grouped avatars, 3–5 people (all shown): 'You, Dad + 3 are on List 52'.
  ///
  /// In en, this message translates to:
  /// **'{first}, {second} + {count}'**
  String clusterCounted(String first, String second, int count);

  /// Grouped avatars, more than 5 people (the +N disc carries the count): 'You, Dad and others are on List 52'.
  ///
  /// In en, this message translates to:
  /// **'{first}, {second} and others'**
  String clusterAndOthers(String first, String second);

  /// The gray disc after 4 grouped avatars.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String clusterOverflow(int count);

  /// No description provided for @closesSoon.
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
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

  /// No description provided for @statusNotCarriedFull.
  ///
  /// In en, this message translates to:
  /// **'Not on the list · all {limit} places in use'**
  String statusNotCarriedFull(int limit);

  /// Screen reader text for the gold ring / dot. Not in the spec; for review.
  ///
  /// In en, this message translates to:
  /// **'Held today'**
  String get heldToday;

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

  /// In the prayer bar: '3:12 · with 229' (others in prayer now).
  ///
  /// In en, this message translates to:
  /// **'with {count}'**
  String prayingWith(int count);

  /// Screen reader label for 'with 229' in the prayer bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Praying with 1 other} other{Praying with {count} others}}'**
  String prayingWithSpoken(int count);

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
  /// **'Hold the {count} on List {number} in your prayer'**
  String invitationHold(int count, int number);

  /// No description provided for @invitationHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding the {count} on List {number}'**
  String invitationHolding(int count, int number);

  /// No description provided for @closingCarried.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be carried on List {number}.'**
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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// You: sign-in / link row (auth-onboarding.md prompt copy).
  ///
  /// In en, this message translates to:
  /// **'Keep your list safe'**
  String get youSignIn;

  /// No description provided for @youSignInDetail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple or Google'**
  String get youSignInDetail;

  /// No description provided for @youMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get youMembership;

  /// Not in the spec; plainest wording, for review.
  ///
  /// In en, this message translates to:
  /// **'Trial until {date}'**
  String youMembershipTrial(DateTime date);

  /// Not in the spec; for review.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get youMembershipActive;

  /// Not in the spec; for review.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get youMembershipFree;

  /// No description provided for @youRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get youRestore;

  /// No description provided for @youReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get youReminders;

  /// No description provided for @reminderMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get reminderMorning;

  /// No description provided for @reminderMidday.
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get reminderMidday;

  /// No description provided for @reminderEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get reminderEvening;

  /// Screen reader label for a reminder's time button.
  ///
  /// In en, this message translates to:
  /// **'{slot} reminder time'**
  String reminderTimeFor(String slot);

  /// No description provided for @youNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get youNotifications;

  /// No description provided for @youListLive.
  ///
  /// In en, this message translates to:
  /// **'Today\'s list is live'**
  String get youListLive;

  /// No description provided for @youShowNames.
  ///
  /// In en, this message translates to:
  /// **'Show names in notifications'**
  String get youShowNames;

  /// Device-local light/dark choice, from the POC. Not in the You spec yet.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get youAppearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @youLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get youLanguage;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageDevice;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Grace offers toggle. Not worded in the spec; for review.
  ///
  /// In en, this message translates to:
  /// **'Offer grace days'**
  String get youGraceOffers;

  /// No description provided for @youArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get youArchived;

  /// No description provided for @youPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & terms'**
  String get youPrivacy;

  /// No description provided for @youAboutRitual.
  ///
  /// In en, this message translates to:
  /// **'About the ritual'**
  String get youAboutRitual;

  /// No description provided for @youDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get youDeleteAccount;

  /// No description provided for @youVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String youVersion(String version);

  /// From the POC settings footer.
  ///
  /// In en, this message translates to:
  /// **'© {year} Plus Prayer, LLC'**
  String youCopyright(int year);

  /// After tapping the footer: version and account id are on the clipboard for support.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get youCopied;

  /// No description provided for @errorSettingsOffline.
  ///
  /// In en, this message translates to:
  /// **'Changing this needs a connection.'**
  String get errorSettingsOffline;
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

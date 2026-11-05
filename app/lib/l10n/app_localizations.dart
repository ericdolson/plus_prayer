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

  /// Community card's screen reader label: the world's scale (design-direction.md §6).
  ///
  /// In en, this message translates to:
  /// **'{people} people · {prayers} prayers'**
  String listScale(int people, int prayers);

  /// Community card counts row: the number is drawn in ink, the words in inkMuted (2026-11-02).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} person} other{{count} people}}'**
  String listPeople(int count);

  /// Community card counts row, after listPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} prayer} other{{count} prayers}}'**
  String listPrayers(int count);

  /// The thin middle dot between the card's counts.
  ///
  /// In en, this message translates to:
  /// **'·'**
  String get countsSeparator;

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

  /// Only you carried, after the flip (design-direction.md §6, 2026-11-02).
  ///
  /// In en, this message translates to:
  /// **'Your next prayer puts you on List {number}'**
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

  /// Replaces the card's status line in the last 5 minutes (2026-11-02).
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes} min · pray to carry them'**
  String closesSoon(int number, int minutes);

  /// closesSoon when only you are carried (2026-11-02).
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes} min · pray to be on List {next}'**
  String closesSoonYou(int number, int minutes, int next);

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

  /// The card's presence line, last-hour rung: no dot (design-direction.md §6). Screen readers hear presenceLastHour.
  ///
  /// In en, this message translates to:
  /// **'{count} prayed this hour'**
  String presenceShortLastHour(int count);

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

  /// Screen reader: a Home row with the carried mark (design-direction.md §5).
  ///
  /// In en, this message translates to:
  /// **'{name}, carried'**
  String rowCarried(String name);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterStillToHold.
  ///
  /// In en, this message translates to:
  /// **'Still to hold'**
  String get filterStillToHold;

  /// Search empty state, every no-results case. Always one line: the query truncates with …, never the sentence.
  ///
  /// In en, this message translates to:
  /// **'No matches for “{query}”'**
  String searchNoMatches(String query);

  /// Search empty state: blue, with a + icon; opens the add sheet prefilled with the query. Type-neutral (names or intentions). Hidden in prayer.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get searchAdd;

  /// Match hint (flat card) under the search empty state when a filter hides matches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match in All} other{{count} matches in All}}'**
  String searchMatchesInAll(int count);

  /// On the match hint: switches the filter to All, keeps the search. Flip the arrow for right-to-left languages.
  ///
  /// In en, this message translates to:
  /// **'Show →'**
  String get searchShow;

  /// Screen-reader label for the whole match hint (one button).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 match in All} other{Show {count} matches in All}}'**
  String searchShowMatchesSpoken(int count);

  /// No description provided for @carriedHelperMeaning.
  ///
  /// In en, this message translates to:
  /// **'Carried means printed on the daily list, and held by everyone who prays it.'**
  String get carriedHelperMeaning;

  /// No description provided for @carriedHelperKeep.
  ///
  /// In en, this message translates to:
  /// **'Pray with the list each day to keep them carried.'**
  String get carriedHelperKeep;

  /// Under the Carried filter when it holds only you: opens Your portion.
  ///
  /// In en, this message translates to:
  /// **'Choose who\'s carried'**
  String get carriedHelperChoose;

  /// No description provided for @yourPortion.
  ///
  /// In en, this message translates to:
  /// **'Your portion'**
  String get yourPortion;

  /// Home, under the Still to hold filter, when nothing is left.
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s been held today.'**
  String get filterEmptyStillToHold;

  /// Screen reader: the count beside a filter in the menu.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String filterCountSpoken(int count);

  /// Screen reader: the gold check beside Still to hold when nothing is left.
  ///
  /// In en, this message translates to:
  /// **'all held'**
  String get filterAllHeldSpoken;

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

  /// Screen reader label for × inside the active filter chip (returns to All).
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get clearFilter;

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

  /// Screen reader hint for Cancel in the header during prayer.
  ///
  /// In en, this message translates to:
  /// **'End without saving'**
  String get discardPrayer;

  /// Top-left of the header during prayer: ends the prayer without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelPrayer;

  /// Asked when ✕ ends a prayer that has run over ~30 seconds.
  ///
  /// In en, this message translates to:
  /// **'Discard this prayer?'**
  String get discardPrayerQuestion;

  /// Declines discarding the prayer. Not in the spec yet: for review.
  ///
  /// In en, this message translates to:
  /// **'Keep praying'**
  String get keepPraying;

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

  /// Detail-page history period row (detail-page.md).
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get historyThisWeek;

  /// No description provided for @historyLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get historyLastWeek;

  /// Days of the current month not in This week / Last week.
  ///
  /// In en, this message translates to:
  /// **'Earlier in {month}'**
  String historyEarlierIn(DateTime month);

  /// An earlier month of the current year.
  ///
  /// In en, this message translates to:
  /// **'{month}'**
  String historyMonth(DateTime month);

  /// An earlier year.
  ///
  /// In en, this message translates to:
  /// **'{year}'**
  String historyYear(DateTime year);

  /// Tier 1, counts only, never ratios (stats-history.md); 'once' per detail-page.md.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You prayed once} other{You prayed {count} times}}'**
  String historyPrayed(int count);

  /// No description provided for @historyOnLists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{On 1 list} other{On {count} lists}}'**
  String historyOnLists(int count);

  /// The period holds the current list.
  ///
  /// In en, this message translates to:
  /// **'{onLists} · current'**
  String historyCurrent(String onLists);

  /// Screen reader form of the ✎ N hint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String historyNotesSpoken(int count);

  /// Hint on the period where the intention was answered (heldGoldText).
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get historyAnswered;

  /// Last history row: the day the subject was created.
  ///
  /// In en, this message translates to:
  /// **'Begun · {date}'**
  String historyBegun(DateTime date);

  /// As historyBegun, created in an earlier year.
  ///
  /// In en, this message translates to:
  /// **'Begun · {date}'**
  String historyBegunYear(DateTime date);

  /// Detail page status line (detail-page.md): a carried name, next list covered.
  ///
  /// In en, this message translates to:
  /// **'{name} will be on List {number}'**
  String detailCovered(String name, int number);

  /// No description provided for @detailNextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Your next prayer carries {name} onto List {number}'**
  String detailNextPrayer(String name, int number);

  /// No description provided for @detailPrayToCarry.
  ///
  /// In en, this message translates to:
  /// **'Pray to carry {name} onto List {number}'**
  String detailPrayToCarry(String name, int number);

  /// A carried intention's status line.
  ///
  /// In en, this message translates to:
  /// **'It\'ll be on List {number}'**
  String detailCoveredIt(int number);

  /// No description provided for @detailNextPrayerIt.
  ///
  /// In en, this message translates to:
  /// **'Your next prayer carries it onto List {number}'**
  String detailNextPrayerIt(int number);

  /// No description provided for @detailPrayToCarryIt.
  ///
  /// In en, this message translates to:
  /// **'Pray to carry it onto List {number}'**
  String detailPrayToCarryIt(int number);

  /// Replaces the status line in the closing window (card rule).
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes} min · pray to carry {name}'**
  String detailClosesSoon(int number, int minutes, String name);

  /// No description provided for @detailClosesSoonIt.
  ///
  /// In en, this message translates to:
  /// **'List {number} closes in {minutes} min · pray to carry it'**
  String detailClosesSoonIt(int number, int minutes);

  /// Tier 1, always shown (stats-history.md).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Held by you · 1 prayer} other{Held by you · {count} prayers}}'**
  String detailHeldByYou(int count);

  /// Tier 3, only once ever carried. {prayers} = detailWorldPrayers, {lists} = detailWorldLists.
  ///
  /// In en, this message translates to:
  /// **'Carried by the world · {prayers} · {lists}'**
  String detailCarriedByWorld(String prayers, String lists);

  /// No description provided for @detailWorldPrayers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 prayer} other{{count} prayers}}'**
  String detailWorldPrayers(int count);

  /// No description provided for @detailWorldLists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 list} other{{count} lists}}'**
  String detailWorldLists(int count);

  /// Detail page section title (Roca, the Home name style).
  ///
  /// In en, this message translates to:
  /// **'Intentions'**
  String get detailIntentions;

  /// A name page's pray button. Self and intention pages say 'Pray'.
  ///
  /// In en, this message translates to:
  /// **'Pray for {name}'**
  String prayFor(String name);

  /// In prayer on a detail page: go to Home, still praying.
  ///
  /// In en, this message translates to:
  /// **'Pray for others'**
  String get prayForOthers;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// The detail page's ⋯ (screen readers, tooltip).
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// ⋯ / quick action on an open intention: mark it answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get actionAnswered;

  /// No description provided for @actionRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get actionRelease;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// From detail-page.md.
  ///
  /// In en, this message translates to:
  /// **'Release this intention? It moves to Archived.'**
  String get releaseQuestion;

  /// Not in the spec ('a name's confirm says its intentions go too'): for review.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}? Its intentions are archived too.'**
  String archiveNameQuestion(String name);

  /// A name with no intentions, or an intention. Not in the spec: for review.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String archiveQuestion(String name);

  /// Edit sheet title for a name or the self. Not in the spec: for review.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @editIntention.
  ///
  /// In en, this message translates to:
  /// **'Edit intention'**
  String get editIntention;

  /// An online command (edit, answered, release, archive) failed offline. Not in the spec: for review.
  ///
  /// In en, this message translates to:
  /// **'This needs a connection.'**
  String get errorNeedsConnection;

  /// R10: once per 7 days after first printed, next-available date shown plainly. Wording for review.
  ///
  /// In en, this message translates to:
  /// **'You can change your name again on {date}.'**
  String selfNameTooSoon(DateTime date);
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

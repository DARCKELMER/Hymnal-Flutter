import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('ru'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Hymnal'**
  String get appName;

  /// Label for the home screen or navigation tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Label for the lists screen or navigation tab
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// Label for the favorites screen or navigation tab
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Label for the settings screen or navigation tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for the history screen or navigation tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Label for the search functionality
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Hint text shown in the search bar
  ///
  /// In en, this message translates to:
  /// **'Search hymns...'**
  String get searchHint;

  /// Message shown when a search results in no matches
  ///
  /// In en, this message translates to:
  /// **'No hymns found'**
  String get noHymnsFound;

  /// Option to sort or view hymns numerically
  ///
  /// In en, this message translates to:
  /// **'Numeric'**
  String get numeric;

  /// Option to sort or view hymns alphabetically
  ///
  /// In en, this message translates to:
  /// **'Alphabetic'**
  String get alpha;

  /// Option to sort or view hymns by theme
  ///
  /// In en, this message translates to:
  /// **'Thematic'**
  String get thematic;

  /// Label for the currently selected hymnal
  ///
  /// In en, this message translates to:
  /// **'Selected Hymnal'**
  String get selectedHymnal;

  /// Action to open the hymnal selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Hymnal'**
  String get selectHymnal;

  /// Title shown on the welcome or onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Hymnal App'**
  String get welcomeTitle;

  /// Subtitle shown on the welcome or onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Select a hymnal to start browsing'**
  String get welcomeSubtitle;

  /// Label for the hymn number input field
  ///
  /// In en, this message translates to:
  /// **'Hymn Number'**
  String get hymnNumber;

  /// Hint text for the hymn number input field
  ///
  /// In en, this message translates to:
  /// **'Enter hymn number'**
  String get enterHymnNumber;

  /// Action to open a specific hymn by its number
  ///
  /// In en, this message translates to:
  /// **'Open Hymn'**
  String get openHymn;

  /// Generic 'Go' or 'Proceed' action
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// Error message for invalid hymn number input
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid hymn number'**
  String get invalidHymnNumber;

  /// Error message when a specific hymn number doesn't exist
  ///
  /// In en, this message translates to:
  /// **'Hymn not found'**
  String get hymnNotFound;

  /// Error message when no hymnal is selected
  ///
  /// In en, this message translates to:
  /// **'Selected hymnal is null'**
  String get hymnalNotSelected;

  /// Action to clear the user's view history
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// Confirmation dialog message for clearing history
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your history? This cannot be undone.'**
  String get clearHistoryConfirm;

  /// Success message after clearing history
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get historyCleared;

  /// Action to clear all user favorites
  ///
  /// In en, this message translates to:
  /// **'Clear Favorites'**
  String get clearFavorites;

  /// Confirmation dialog message for clearing favorites
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all favorites? This cannot be undone.'**
  String get clearFavoritesConfirm;

  /// Success message after clearing favorites
  ///
  /// In en, this message translates to:
  /// **'Favorites cleared'**
  String get favoritesCleared;

  /// Message shown when the favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// Instructional text shown when the favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'Add hymns to your favorites from the hymn page'**
  String get addHymnsToFavorites;

  /// Message shown when the history list is empty
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// Confirmation message to remove a specific hymn from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from favorites?'**
  String removeFavorite(String title);

  /// Title for the remove favorite confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get removeFavoriteTitle;

  /// Generic 'Cancel' action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic 'Remove' action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Action to undo the previous operation
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Success message after an action is undone
  ///
  /// In en, this message translates to:
  /// **'Action reversed'**
  String get actionReversed;

  /// Text showing a range of hymn numbers
  ///
  /// In en, this message translates to:
  /// **'Hymns {start}-{end}'**
  String hymnRange(int start, int end);

  /// Category label for app appearance settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Label for theme selection setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Option to follow the system theme
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Option for light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Option for dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label for font size setting
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Label for background image setting
  ///
  /// In en, this message translates to:
  /// **'Background Image'**
  String get backgroundImage;

  /// Toggle to show or hide the background image
  ///
  /// In en, this message translates to:
  /// **'Show background image'**
  String get showBackgroundImage;

  /// Category label for audio playback settings
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// Toggle to keep the screen from going to sleep
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get keepScreenOn;

  /// Description for the 'Keep Screen On' setting
  ///
  /// In en, this message translates to:
  /// **'Don\'t dim or turn off screen'**
  String get keepScreenOnDesc;

  /// Toggle for continuous audio playback
  ///
  /// In en, this message translates to:
  /// **'Continuous Play'**
  String get continuousPlay;

  /// Category label for data management settings
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// Description for the 'Clear History' action
  ///
  /// In en, this message translates to:
  /// **'Remove all recently viewed hymns'**
  String get clearHistoryDesc;

  /// Description for the 'Clear Favorites' action
  ///
  /// In en, this message translates to:
  /// **'Remove all favorite hymns'**
  String get clearFavoritesDesc;

  /// Category label for information about the app
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Link to the app's website
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Link to contribute to the project
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contribute;

  /// Action to contact the developers
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Link to the GitHub repository
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get repository;

  /// Action to rate the app in the store
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateApp;

  /// Label for the app version number
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Action to view open source licenses
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// Title for the sheet music view
  ///
  /// In en, this message translates to:
  /// **'Sheet Music - Hymn {number}'**
  String sheetMusicTitle(int number);

  /// Error message when an image fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load image: {error}'**
  String failedToLoadImage(String error);

  /// Message shown when the current hymnal lacks sheet music
  ///
  /// In en, this message translates to:
  /// **'No sheet music available for this hymnal'**
  String get noSheetMusicAvailable;

  /// Message shown when a specific hymn lacks sheet music
  ///
  /// In en, this message translates to:
  /// **'No sheet music found for hymn {number}'**
  String noSheetMusicFound(int number);

  /// Generic 'Share' action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Generic 'Copy' action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Action to view the lyrics of a hymn
  ///
  /// In en, this message translates to:
  /// **'View Lyrics'**
  String get viewLyrics;

  /// Label for instrumental audio version
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get instrumental;

  /// Label for sung audio version
  ///
  /// In en, this message translates to:
  /// **'Sung'**
  String get sung;

  /// Label for hymnal language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get hymnalLanguage;

  /// Generic 'Clear All' action
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Generic 'Clear' action
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Title format for a hymn
  ///
  /// In en, this message translates to:
  /// **'Hymn {number}'**
  String hymnTitle(int number);

  /// Text appended to shared hymn lyrics
  ///
  /// In en, this message translates to:
  /// **'\n---\n✨ Discover more hymns in the Hymnal App\nDownload here:\niOS: {iOSLink}\nAndroid: {androidLink}'**
  String sharedFromApp(String iOSLink, String androidLink);

  /// Label for the mini-player or current track
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// Status message when the player is idle
  ///
  /// In en, this message translates to:
  /// **'No audio playing'**
  String get noAudioPlaying;

  /// Section header for hymnal-related settings
  ///
  /// In en, this message translates to:
  /// **'Hymnal'**
  String get sectionHymnal;

  /// Section header for appearance settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// Section header for app behavior settings
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get sectionBehavior;

  /// Section header for data management settings
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get sectionDataManagement;

  /// Section header for about settings
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// Subtitle description for background image setting
  ///
  /// In en, this message translates to:
  /// **'Show background image on screens'**
  String get backgroundImageSubtitle;

  /// Subtitle description for clear history setting
  ///
  /// In en, this message translates to:
  /// **'Remove all recently viewed hymns'**
  String get clearHistorySubtitle;

  /// Subtitle description for clear favorites setting
  ///
  /// In en, this message translates to:
  /// **'Remove all favorite hymns'**
  String get clearFavoritesSubtitle;

  /// Label for GitHub repository link in settings
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepo;

  /// Heading for theme selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// Label for Apple App Store
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get appStore;

  /// Label for Google Play Store
  ///
  /// In en, this message translates to:
  /// **'Play Store'**
  String get playStore;

  /// Error message when a URL fails to open
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String couldNotLaunch(String url);

  /// Error message for link opening failure
  ///
  /// In en, this message translates to:
  /// **'Error opening link: {error}'**
  String errorOpeningLink(String error);

  /// Generic 'None' value
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Legal/Copyright text
  ///
  /// In en, this message translates to:
  /// **'© {year} GoGoShift'**
  String applicationLegalese(String year);

  /// Credit text for the app developers
  ///
  /// In en, this message translates to:
  /// **'Created with dedication by Katherin Castillo and Isaac Rebolledo.'**
  String get aboutDevelopers;

  /// Debug-only screen to test the Liquid Glass effect
  ///
  /// In en, this message translates to:
  /// **'Glass lab'**
  String get glassLabTitle;

  /// Subtitle of the glass lab entry in Settings
  ///
  /// In en, this message translates to:
  /// **'Debug only: test the Liquid Glass effect'**
  String get glassLabSubtitle;

  /// Label for the glass tint slider in the glass lab
  ///
  /// In en, this message translates to:
  /// **'Tint'**
  String get glassLabTint;

  /// Left end of the glass tint slider
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get glassLabClear;

  /// Right end of the glass tint slider
  ///
  /// In en, this message translates to:
  /// **'Tinted'**
  String get glassLabTinted;

  /// Switch that forces the fallback glass renderer
  ///
  /// In en, this message translates to:
  /// **'Force FakeGlass'**
  String get glassLabForceFake;

  /// Switch that slowly moves the background
  ///
  /// In en, this message translates to:
  /// **'Animated background'**
  String get glassLabAnimatedBackground;

  /// Switch for Flutter's performance overlay
  ///
  /// In en, this message translates to:
  /// **'Performance overlay'**
  String get glassLabPerformanceOverlay;

  /// Accessibility label for the play button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Accessibility label for the pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Switch between shiny water glass and the standard iOS 27 Clear glass in the glass lab
  ///
  /// In en, this message translates to:
  /// **'Shiny water'**
  String get glassLabWater;

  /// Accessibility label of the button that closes the mini player in the glass lab
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get playerClose;

  /// Accessibility action to go to the next hymn by swiping the mini player
  ///
  /// In en, this message translates to:
  /// **'Next hymn'**
  String get playerNextHymn;

  /// Accessibility action to go to the previous hymn by swiping the mini player
  ///
  /// In en, this message translates to:
  /// **'Previous hymn'**
  String get playerPreviousHymn;

  /// Switch in the glass lab: the play drop uses its own lens (cannot merge) instead of the shared glass
  ///
  /// In en, this message translates to:
  /// **'Own lens on ▶ drop'**
  String get glassLabPlayOwnLens;

  /// Accessibility action that expands the mini player to show playback controls
  ///
  /// In en, this message translates to:
  /// **'Show controls'**
  String get playerShowControls;

  /// Accessibility action that collapses the mini player controls
  ///
  /// In en, this message translates to:
  /// **'Hide controls'**
  String get playerHideControls;

  /// Button that rewinds the hymn 10 seconds
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get playerSeekBack;

  /// Button that skips the hymn forward 10 seconds
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get playerSeekForward;

  /// Chip that jumps to the start of the hymn
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get playerJumpStart;

  /// Chip that jumps to the middle of the hymn
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get playerJumpMiddle;

  /// Chip that jumps to the last seconds of the hymn
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get playerJumpEnd;

  /// Accessibility label of the time slider of the mini player
  ///
  /// In en, this message translates to:
  /// **'Hymn position'**
  String get playerPosition;

  /// Accessibility label of a playback speed chip
  ///
  /// In en, this message translates to:
  /// **'Speed {value}×'**
  String playerSpeed(int value);

  /// Accessibility label of the mini player chip that jumps the hymn position
  ///
  /// In en, this message translates to:
  /// **'Go to start'**
  String get playerGoToStart;

  /// Accessibility label of the mini player chip that jumps the hymn position
  ///
  /// In en, this message translates to:
  /// **'Go to middle'**
  String get playerGoToMiddle;

  /// Accessibility label of the mini player chip that jumps the hymn position
  ///
  /// In en, this message translates to:
  /// **'Go to end'**
  String get playerGoToEnd;

  /// Settings slider title: transparency of the liquid glass surfaces
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glassTint;

  /// Left end of the glass slider
  ///
  /// In en, this message translates to:
  /// **'Transparent'**
  String get glassTransparent;

  /// Right end of the glass slider
  ///
  /// In en, this message translates to:
  /// **'Tinted'**
  String get glassTinted;

  /// Shown under the glass slider when the system high contrast setting forces tinted glass
  ///
  /// In en, this message translates to:
  /// **'Tinted because high contrast is on'**
  String get glassTintForced;

  /// Debug-only screen title showing the glass design system components
  ///
  /// In en, this message translates to:
  /// **'Glass catalog'**
  String get glassCatalogTitle;

  /// Subtitle of the glass catalog entry in settings
  ///
  /// In en, this message translates to:
  /// **'Debug only: redesign components'**
  String get glassCatalogSubtitle;

  /// Glass catalog section
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get glassCatalogButtons;

  /// Glass catalog section
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get glassCatalogControls;

  /// Glass catalog section
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get glassCatalogNavigation;

  /// Glass catalog section with the lyrics card
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get glassCatalogLyrics;

  /// Accessibility label of the sheet music button
  ///
  /// In en, this message translates to:
  /// **'Sheet music'**
  String get sheetMusic;

  /// Accessibility hint: tapping the mini player opens the full player
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get playerOpen;

  /// Shown in the search results panel when the field is empty and there are no recent searches
  ///
  /// In en, this message translates to:
  /// **'Search by number, title or lyrics'**
  String get searchEmptyHint;

  /// Section title with the latest searches
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// Accessibility label of the button that removes a recent search
  ///
  /// In en, this message translates to:
  /// **'Remove from recent'**
  String get removeRecentSearch;

  /// Number of search results
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hymn} other{{count} hymns}}'**
  String searchResultsCount(int count);

  /// Shown in the tablet detail pane when no hymn is selected
  ///
  /// In en, this message translates to:
  /// **'Choose a hymn from the list'**
  String get selectHymnPrompt;

  /// Small header above screen titles
  ///
  /// In en, this message translates to:
  /// **'Adventist Hymnal'**
  String get appFullName;

  /// Live preview on the home number card when the typed hymn number does not exist
  ///
  /// In en, this message translates to:
  /// **'Does not exist'**
  String get hymnDoesNotExist;

  /// Accessibility label of the backspace key of the home keypad
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get deleteDigit;

  /// Accessibility label of the clear key of the home keypad
  ///
  /// In en, this message translates to:
  /// **'Clear number'**
  String get clearNumber;

  /// Number of sections of a thematic category
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 section} other{{count} sections}}'**
  String sectionsCount(int count);

  /// Tablet header between previous/next arrows
  ///
  /// In en, this message translates to:
  /// **'Hymn {number} of {total}'**
  String hymnOfTotal(int number, int total);

  /// Card under the lyrics on tablet portrait that opens the next hymn
  ///
  /// In en, this message translates to:
  /// **'Next hymn'**
  String get nextHymnCard;

  /// Accessibility label of the favorite button when the hymn is not a favorite
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAdd;

  /// Accessibility label of the favorite button when the hymn is a favorite
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemove;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

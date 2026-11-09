// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hymnal';

  @override
  String get home => 'Home';

  @override
  String get lists => 'Lists';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get history => 'History';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search hymns...';

  @override
  String get noHymnsFound => 'No hymns found';

  @override
  String get numeric => 'Numeric';

  @override
  String get alpha => 'Alphabetic';

  @override
  String get thematic => 'Thematic';

  @override
  String get selectedHymnal => 'Selected Hymnal';

  @override
  String get selectHymnal => 'Select Hymnal';

  @override
  String get welcomeTitle => 'Welcome to the Hymnal App';

  @override
  String get welcomeSubtitle => 'Select a hymnal to start browsing';

  @override
  String get hymnNumber => 'Hymn Number';

  @override
  String get enterHymnNumber => 'Enter hymn number';

  @override
  String get openHymn => 'Open Hymn';

  @override
  String get go => 'Go';

  @override
  String get invalidHymnNumber => 'Please enter a valid hymn number';

  @override
  String get hymnNotFound => 'Hymn not found';

  @override
  String get hymnalNotSelected => 'Selected hymnal is null';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear your history? This cannot be undone.';

  @override
  String get historyCleared => 'History cleared';

  @override
  String get clearFavorites => 'Clear Favorites';

  @override
  String get clearFavoritesConfirm =>
      'Are you sure you want to clear all favorites? This cannot be undone.';

  @override
  String get favoritesCleared => 'Favorites cleared';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get addHymnsToFavorites =>
      'Add hymns to your favorites from the hymn page';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String removeFavorite(String title) {
    return 'Remove \"$title\" from favorites?';
  }

  @override
  String get removeFavoriteTitle => 'Remove Favorite';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get undo => 'Undo';

  @override
  String get actionReversed => 'Action reversed';

  @override
  String hymnRange(int start, int end) {
    return 'Hymns $start-$end';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Font Size';

  @override
  String get backgroundImage => 'Background Image';

  @override
  String get showBackgroundImage => 'Show background image';

  @override
  String get playback => 'Playback';

  @override
  String get keepScreenOn => 'Keep Screen On';

  @override
  String get keepScreenOnDesc => 'Don\'t dim or turn off screen';

  @override
  String get continuousPlay => 'Continuous Play';

  @override
  String get data => 'Data';

  @override
  String get clearHistoryDesc => 'Remove all recently viewed hymns';

  @override
  String get clearFavoritesDesc => 'Remove all favorite hymns';

  @override
  String get about => 'About';

  @override
  String get website => 'Website';

  @override
  String get contribute => 'Contribute';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get repository => 'GitHub Repository';

  @override
  String get rateApp => 'Rate the App';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licenses';

  @override
  String sheetMusicTitle(int number) {
    return 'Sheet Music - Hymn $number';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Failed to load image: $error';
  }

  @override
  String get noSheetMusicAvailable =>
      'No sheet music available for this hymnal';

  @override
  String noSheetMusicFound(int number) {
    return 'No sheet music found for hymn $number';
  }

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get viewLyrics => 'View Lyrics';

  @override
  String get instrumental => 'Instrumental';

  @override
  String get sung => 'Sung';

  @override
  String get hymnalLanguage => 'Language';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clear => 'Clear';

  @override
  String hymnTitle(int number) {
    return 'Hymn $number';
  }

  @override
  String sharedFromApp(String iOSLink, String androidLink) {
    return '\n---\n✨ Discover more hymns in the Hymnal App\nDownload here:\niOS: $iOSLink\nAndroid: $androidLink';
  }

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noAudioPlaying => 'No audio playing';

  @override
  String get sectionHymnal => 'Hymnal';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionBehavior => 'Behavior';

  @override
  String get sectionDataManagement => 'Data Management';

  @override
  String get sectionAbout => 'About';

  @override
  String get backgroundImageSubtitle => 'Show background image on screens';

  @override
  String get clearHistorySubtitle => 'Remove all recently viewed hymns';

  @override
  String get clearFavoritesSubtitle => 'Remove all favorite hymns';

  @override
  String get githubRepo => 'GitHub Repository';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get appStore => 'App Store';

  @override
  String get playStore => 'Play Store';

  @override
  String couldNotLaunch(String url) {
    return 'Could not launch $url';
  }

  @override
  String errorOpeningLink(String error) {
    return 'Error opening link: $error';
  }

  @override
  String get none => 'None';

  @override
  String applicationLegalese(String year) {
    return '© $year GoGoShift';
  }

  @override
  String get aboutDevelopers =>
      'Created with dedication by Katherin Castillo and Isaac Rebolledo.';

  @override
  String get glassLabTitle => 'Glass lab';

  @override
  String get glassLabSubtitle => 'Debug only: test the Liquid Glass effect';

  @override
  String get glassLabTint => 'Tint';

  @override
  String get glassLabClear => 'Clear';

  @override
  String get glassLabTinted => 'Tinted';

  @override
  String get glassLabForceFake => 'Force FakeGlass';

  @override
  String get glassLabAnimatedBackground => 'Animated background';

  @override
  String get glassLabPerformanceOverlay => 'Performance overlay';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get glassLabWater => 'Shiny water';

  @override
  String get playerClose => 'Close player';

  @override
  String get playerNextHymn => 'Next hymn';

  @override
  String get playerPreviousHymn => 'Previous hymn';

  @override
  String get glassLabPlayOwnLens => 'Own lens on ▶ drop';

  @override
  String get playerShowControls => 'Show controls';

  @override
  String get playerHideControls => 'Hide controls';

  @override
  String get playerSeekBack => 'Back 10 seconds';

  @override
  String get playerSeekForward => 'Forward 10 seconds';

  @override
  String get playerJumpStart => 'Start';

  @override
  String get playerJumpMiddle => 'Middle';

  @override
  String get playerJumpEnd => 'End';

  @override
  String get playerPosition => 'Hymn position';

  @override
  String playerSpeed(int value) {
    return 'Speed $value×';
  }

  @override
  String get playerGoToStart => 'Go to start';

  @override
  String get playerGoToMiddle => 'Go to middle';

  @override
  String get playerGoToEnd => 'Go to end';

  @override
  String get glassTint => 'Glass';

  @override
  String get glassTransparent => 'Transparent';

  @override
  String get glassTinted => 'Tinted';

  @override
  String get glassTintForced => 'Tinted because high contrast is on';

  @override
  String get glassCatalogTitle => 'Glass catalog';

  @override
  String get glassCatalogSubtitle => 'Debug only: redesign components';

  @override
  String get glassCatalogButtons => 'Buttons';

  @override
  String get glassCatalogControls => 'Controls';

  @override
  String get glassCatalogNavigation => 'Navigation';

  @override
  String get glassCatalogLyrics => 'Lyrics';

  @override
  String get sheetMusic => 'Sheet music';

  @override
  String get playerOpen => 'Open player';

  @override
  String get searchEmptyHint => 'Search by number, title or lyrics';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get removeRecentSearch => 'Remove from recent';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hymns',
      one: '1 hymn',
    );
    return '$_temp0';
  }

  @override
  String get selectHymnPrompt => 'Choose a hymn from the list';
}

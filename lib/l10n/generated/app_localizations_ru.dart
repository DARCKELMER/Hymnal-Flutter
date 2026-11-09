// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Гимны';

  @override
  String get home => 'Главная';

  @override
  String get lists => 'Списки';

  @override
  String get favorites => 'Избранное';

  @override
  String get settings => 'Настройки';

  @override
  String get history => 'История';

  @override
  String get search => 'Поиск';

  @override
  String get searchHint => 'Поиск гимнов...';

  @override
  String get noHymnsFound => 'Гимны не найдены';

  @override
  String get numeric => 'По номеру';

  @override
  String get alpha => 'По алфавиту';

  @override
  String get thematic => 'По темам';

  @override
  String get selectedHymnal => 'Выбранный сборник';

  @override
  String get selectHymnal => 'Выбрать сборник';

  @override
  String get welcomeTitle => 'Добро пожаловать в приложение «Гимны»';

  @override
  String get welcomeSubtitle => 'Выберите сборник, чтобы начать просмотр';

  @override
  String get hymnNumber => 'Номер гимна';

  @override
  String get enterHymnNumber => 'Введите номер гимна';

  @override
  String get openHymn => 'Открыть гимн';

  @override
  String get go => 'Перейти';

  @override
  String get invalidHymnNumber => 'Пожалуйста, введите правильный номер гимна';

  @override
  String get hymnNotFound => 'Гимн не найден';

  @override
  String get hymnalNotSelected => 'Сборник не выбран';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryConfirm =>
      'Вы уверены, что хотите очистить историю? Это действие нельзя отменить.';

  @override
  String get historyCleared => 'История очищена';

  @override
  String get clearFavorites => 'Очистить избранное';

  @override
  String get clearFavoritesConfirm =>
      'Вы уверены, что хотите очистить все избранное? Это действие нельзя отменить.';

  @override
  String get favoritesCleared => 'Избранное очищено';

  @override
  String get noFavoritesYet => 'В избранном пока ничего нет';

  @override
  String get addHymnsToFavorites =>
      'Добавляйте гимны в избранное со страницы гимна';

  @override
  String get noHistoryYet => 'История пуста';

  @override
  String removeFavorite(String title) {
    return 'Удалить «$title» из избранного?';
  }

  @override
  String get removeFavoriteTitle => 'Удалить из избранного';

  @override
  String get cancel => 'Отмена';

  @override
  String get remove => 'Удалить';

  @override
  String get undo => 'Отменить действие';

  @override
  String get actionReversed => 'Действие отменено';

  @override
  String hymnRange(int start, int end) {
    return 'Гимны $start–$end';
  }

  @override
  String get appearance => 'Внешний вид';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Темная';

  @override
  String get fontSize => 'Размер шрифта';

  @override
  String get backgroundImage => 'Фоновое изображение';

  @override
  String get showBackgroundImage => 'Показывать фоновое изображение';

  @override
  String get playback => 'Воспроизведение';

  @override
  String get keepScreenOn => 'Не выключать экран';

  @override
  String get keepScreenOnDesc => 'Экран не будет гаснуть или выключаться';

  @override
  String get continuousPlay => 'Автовоспроизведение';

  @override
  String get data => 'Данные';

  @override
  String get clearHistoryDesc => 'Удалить все недавно просмотренные гимны';

  @override
  String get clearFavoritesDesc => 'Удалить все избранные гимны';

  @override
  String get about => 'О приложении';

  @override
  String get website => 'Веб-сайт';

  @override
  String get contribute => 'Помочь проекту';

  @override
  String get contactUs => 'Связаться с нами';

  @override
  String get repository => 'Репозиторий GitHub';

  @override
  String get rateApp => 'Оценить приложение';

  @override
  String get version => 'Версия';

  @override
  String get licenses => 'Лицензии';

  @override
  String sheetMusicTitle(int number) {
    return 'Ноты — Гимн $number';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Не удалось загрузить изображение: $error';
  }

  @override
  String get noSheetMusicAvailable => 'Для этого сборника нет нот';

  @override
  String noSheetMusicFound(int number) {
    return 'Ноты для гимна $number не найдены';
  }

  @override
  String get share => 'Поделиться';

  @override
  String get copy => 'Копировать';

  @override
  String get viewLyrics => 'Посмотреть текст';

  @override
  String get instrumental => 'Инструментал';

  @override
  String get sung => 'Вокал';

  @override
  String get hymnalLanguage => 'Язык';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get clear => 'Очистить';

  @override
  String hymnTitle(int number) {
    return 'Гимн $number';
  }

  @override
  String sharedFromApp(String iOSLink, String androidLink) {
    return '\n---\n✨ Откройте для себя больше гимнов в приложении «Сборник гимнов»\nСкачать здесь:\niOS: $iOSLink\nAndroid: $androidLink';
  }

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get noAudioPlaying => 'Аудио не воспроизводится';

  @override
  String get sectionHymnal => 'Гимны';

  @override
  String get sectionAppearance => 'Внешний вид';

  @override
  String get sectionBehavior => 'Поведение';

  @override
  String get sectionDataManagement => 'Управление данными';

  @override
  String get sectionAbout => 'О приложении';

  @override
  String get backgroundImageSubtitle => 'Показывать фон на экранах';

  @override
  String get clearHistorySubtitle => 'Удалить все недавно просмотренные гимны';

  @override
  String get clearFavoritesSubtitle => 'Удалить все избранные гимны';

  @override
  String get githubRepo => 'Репозиторий GitHub';

  @override
  String get selectTheme => 'Выбрать тему';

  @override
  String get appStore => 'App Store';

  @override
  String get playStore => 'Play Маркет';

  @override
  String couldNotLaunch(String url) {
    return 'Не удалось открыть $url';
  }

  @override
  String errorOpeningLink(String error) {
    return 'Ошибка при открытии ссылки: $error';
  }

  @override
  String get none => 'Нет';

  @override
  String applicationLegalese(String year) {
    return '© $year GoGoShift';
  }

  @override
  String get aboutDevelopers =>
      'Создано с преданностью Кэтрин Кастильо и Исааком Ребольедо.';

  @override
  String get glassLabTitle => 'Лаборатория стекла';

  @override
  String get glassLabSubtitle =>
      'Только отладка: проверка эффекта Liquid Glass';

  @override
  String get glassLabTint => 'Оттенок';

  @override
  String get glassLabClear => 'Прозрачное';

  @override
  String get glassLabTinted => 'Тонированное';

  @override
  String get glassLabForceFake => 'Принудительно FakeGlass';

  @override
  String get glassLabAnimatedBackground => 'Анимированный фон';

  @override
  String get glassLabPerformanceOverlay => 'Оверлей производительности';

  @override
  String get glassLabPlay => 'Воспроизвести';

  @override
  String get glassLabPause => 'Пауза';

  @override
  String get glassLabWater => 'Блестящая вода';

  @override
  String get glassLabClosePlayer => 'Закрыть плеер';

  @override
  String get glassLabNextHymn => 'Следующий гимн';

  @override
  String get glassLabPreviousHymn => 'Предыдущий гимн';

  @override
  String get glassLabPlayOwnLens => 'Своя линза у капли ▶';

  @override
  String get glassLabShowControls => 'Показать настройки';

  @override
  String get glassLabHideControls => 'Скрыть настройки';

  @override
  String get glassLabSeekBack => 'Назад на 10 секунд';

  @override
  String get glassLabSeekForward => 'Вперёд на 10 секунд';

  @override
  String get glassLabJumpStart => 'Начало';

  @override
  String get glassLabJumpMiddle => 'Середина';

  @override
  String get glassLabJumpEnd => 'Конец';

  @override
  String get glassLabPosition => 'Позиция гимна';

  @override
  String glassLabSpeed(int value) {
    return 'Скорость $value×';
  }

  @override
  String get glassLabGoToStart => 'Перейти к началу';

  @override
  String get glassLabGoToMiddle => 'Перейти к середине';

  @override
  String get glassLabGoToEnd => 'Перейти к концу';

  @override
  String get glassTint => 'Стекло';

  @override
  String get glassTransparent => 'Прозрачное';

  @override
  String get glassTinted => 'Тонированное';

  @override
  String get glassTintForced => 'Тонировано: включён высокий контраст';
}

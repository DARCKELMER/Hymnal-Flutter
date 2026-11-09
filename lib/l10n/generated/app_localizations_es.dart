// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Himnario';

  @override
  String get home => 'Inicio';

  @override
  String get lists => 'Listas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get settings => 'Ajustes';

  @override
  String get history => 'Historial';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar himnos...';

  @override
  String get noHymnsFound => 'No se encontraron himnos';

  @override
  String get numeric => 'Numérico';

  @override
  String get alpha => 'Alfabético';

  @override
  String get thematic => 'Temático';

  @override
  String get selectedHymnal => 'Himnario seleccionado';

  @override
  String get selectHymnal => 'Seleccionar himnario';

  @override
  String get welcomeTitle => 'Bienvenido a la App de Himnario';

  @override
  String get welcomeSubtitle => 'Selecciona un himnario para comenzar';

  @override
  String get hymnNumber => 'Número del Himno';

  @override
  String get enterHymnNumber => 'Introduce el número del himno';

  @override
  String get openHymn => 'Abrir Himno';

  @override
  String get go => 'Ir';

  @override
  String get invalidHymnNumber =>
      'Por favor, introduce un número de himno válido';

  @override
  String get hymnNotFound => 'Himno no encontrado';

  @override
  String get hymnalNotSelected => 'No se ha seleccionado ningún himnario';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get clearHistoryConfirm =>
      '¿Estás seguro de que quieres borrar el historial? Esta acción no se puede deshacer.';

  @override
  String get historyCleared => 'Historial borrado';

  @override
  String get clearFavorites => 'Borrar favoritos';

  @override
  String get clearFavoritesConfirm =>
      '¿Estás seguro de que quieres borrar todos los favoritos? Esta acción no se puede deshacer.';

  @override
  String get favoritesCleared => 'Favoritos borrados';

  @override
  String get noFavoritesYet => 'Aún no hay favoritos';

  @override
  String get addHymnsToFavorites =>
      'Añade himnos a tus favoritos desde la página del himno';

  @override
  String get noHistoryYet => 'Aún no hay historial';

  @override
  String removeFavorite(String title) {
    return '¿Quitar \"$title\" de favoritos?';
  }

  @override
  String get removeFavoriteTitle => 'Quitar Favorito';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Quitar';

  @override
  String get undo => 'Deshacer';

  @override
  String get actionReversed => 'Acción revertida';

  @override
  String hymnRange(int start, int end) {
    return 'Himnos $start-$end';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get fontSize => 'Tamaño de fuente';

  @override
  String get backgroundImage => 'Imagen de fondo';

  @override
  String get showBackgroundImage => 'Mostrar imagen de fondo';

  @override
  String get playback => 'Reproducción';

  @override
  String get keepScreenOn => 'Mantener pantalla encendida';

  @override
  String get keepScreenOnDesc => 'No atenuar ni apagar la pantalla';

  @override
  String get continuousPlay => 'Reproducción continua';

  @override
  String get data => 'Datos';

  @override
  String get clearHistoryDesc =>
      'Eliminar todos los himnos vistos recientemente';

  @override
  String get clearFavoritesDesc => 'Eliminar todos los himnos favoritos';

  @override
  String get about => 'Acerca de';

  @override
  String get website => 'Sitio web';

  @override
  String get contribute => 'Contribuir';

  @override
  String get contactUs => 'Contáctanos';

  @override
  String get repository => 'Repositorio de GitHub';

  @override
  String get rateApp => 'Calificar la App';

  @override
  String get version => 'Versión';

  @override
  String get licenses => 'Licencias';

  @override
  String sheetMusicTitle(int number) {
    return 'Partitura - Himno $number';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Error al cargar la imagen: $error';
  }

  @override
  String get noSheetMusicAvailable =>
      'No hay partituras disponibles para este himnario';

  @override
  String noSheetMusicFound(int number) {
    return 'No se encontró partitura para el himno $number';
  }

  @override
  String get share => 'Compartir';

  @override
  String get copy => 'Copiar';

  @override
  String get viewLyrics => 'Ver letra';

  @override
  String get instrumental => 'Instrumental';

  @override
  String get sung => 'Cantado';

  @override
  String get hymnalLanguage => 'Idioma';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get clear => 'Borrar';

  @override
  String hymnTitle(int number) {
    return 'Himno $number';
  }

  @override
  String sharedFromApp(String iOSLink, String androidLink) {
    return '\n---\n✨ Descubre más himnos en la app Himnario\nDescárgala aquí:\niOS: $iOSLink\nAndroid: $androidLink';
  }

  @override
  String get nowPlaying => 'Reproduciendo ahora';

  @override
  String get noAudioPlaying => 'No se está reproduciendo audio';

  @override
  String get sectionHymnal => 'Himnario';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get sectionBehavior => 'Comportamiento';

  @override
  String get sectionDataManagement => 'Gestión de datos';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get backgroundImageSubtitle =>
      'Mostrar imagen de fondo en las pantallas';

  @override
  String get clearHistorySubtitle =>
      'Eliminar todos los himnos vistos recientemente';

  @override
  String get clearFavoritesSubtitle => 'Eliminar todos los himnos favoritos';

  @override
  String get githubRepo => 'Repositorio GitHub';

  @override
  String get selectTheme => 'Seleccionar tema';

  @override
  String get appStore => 'App Store';

  @override
  String get playStore => 'Play Store';

  @override
  String couldNotLaunch(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String errorOpeningLink(String error) {
    return 'Error al abrir el enlace: $error';
  }

  @override
  String get none => 'Ninguno';

  @override
  String applicationLegalese(String year) {
    return '© $year GoGoShift';
  }

  @override
  String get aboutDevelopers =>
      'Creada con dedicación por Katherin Castillo e Isaac Rebolledo.';

  @override
  String get glassLabTitle => 'Laboratorio de cristal';

  @override
  String get glassLabSubtitle =>
      'Solo depuración: prueba el efecto Liquid Glass';

  @override
  String get glassLabTint => 'Tinte';

  @override
  String get glassLabClear => 'Transparente';

  @override
  String get glassLabTinted => 'Tintado';

  @override
  String get glassLabForceFake => 'Forzar FakeGlass';

  @override
  String get glassLabAnimatedBackground => 'Fondo animado';

  @override
  String get glassLabPerformanceOverlay => 'Superposición de rendimiento';

  @override
  String get playerPlay => 'Reproducir';

  @override
  String get playerPause => 'Pausa';

  @override
  String get glassLabWater => 'Agua brillante';

  @override
  String get playerClose => 'Cerrar reproductor';

  @override
  String get playerNextHymn => 'Himno siguiente';

  @override
  String get playerPreviousHymn => 'Himno anterior';

  @override
  String get glassLabPlayOwnLens => 'Lente propia en la gota ▶';

  @override
  String get playerShowControls => 'Mostrar ajustes';

  @override
  String get playerHideControls => 'Ocultar ajustes';

  @override
  String get playerSeekBack => 'Retroceder 10 segundos';

  @override
  String get playerSeekForward => 'Avanzar 10 segundos';

  @override
  String get playerJumpStart => 'Inicio';

  @override
  String get playerJumpMiddle => 'Mitad';

  @override
  String get playerJumpEnd => 'Final';

  @override
  String get playerPosition => 'Posición del himno';

  @override
  String playerSpeed(int value) {
    return 'Velocidad $value×';
  }

  @override
  String get playerGoToStart => 'Ir al inicio';

  @override
  String get playerGoToMiddle => 'Ir a la mitad';

  @override
  String get playerGoToEnd => 'Ir al final';

  @override
  String get glassTint => 'Cristal';

  @override
  String get glassTransparent => 'Transparente';

  @override
  String get glassTinted => 'Tintado';

  @override
  String get glassTintForced => 'Tintado porque el alto contraste está activo';

  @override
  String get glassCatalogTitle => 'Catálogo de cristal';

  @override
  String get glassCatalogSubtitle =>
      'Solo depuración: componentes del rediseño';

  @override
  String get glassCatalogButtons => 'Botones';

  @override
  String get glassCatalogControls => 'Controles';

  @override
  String get glassCatalogNavigation => 'Navegación';

  @override
  String get glassCatalogLyrics => 'Letra';

  @override
  String get sheetMusic => 'Partitura';

  @override
  String get playerOpen => 'Abrir reproductor';
}

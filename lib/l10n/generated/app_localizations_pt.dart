// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Hinário';

  @override
  String get home => 'Início';

  @override
  String get lists => 'Listas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get settings => 'Ajustes';

  @override
  String get history => 'Histórico';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar hinos...';

  @override
  String get noHymnsFound => 'Nenhum hino encontrado';

  @override
  String get numeric => 'Numérico';

  @override
  String get alpha => 'Alfabético';

  @override
  String get thematic => 'Temático';

  @override
  String get selectedHymnal => 'Hinário selecionado';

  @override
  String get selectHymnal => 'Selecionar hinário';

  @override
  String get welcomeTitle => 'Bem-vindo ao App Hinário';

  @override
  String get welcomeSubtitle => 'Selecione um hinário para começar';

  @override
  String get hymnNumber => 'Número do Hino';

  @override
  String get enterHymnNumber => 'Digite o número do hino';

  @override
  String get openHymn => 'Abrir Hino';

  @override
  String get go => 'Ir';

  @override
  String get invalidHymnNumber => 'Por favor, digite un número de hino válido';

  @override
  String get hymnNotFound => 'Hino não encontrado';

  @override
  String get hymnalNotSelected => 'Nenhum hinário selecionado';

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get clearHistoryConfirm =>
      'Tem certeza de que deseja limpar o histórico? Esta ação não pode ser desfeita.';

  @override
  String get historyCleared => 'Histórico limpo';

  @override
  String get clearFavorites => 'Limpar favoritos';

  @override
  String get clearFavoritesConfirm =>
      'Tem certeza de que deseja limpar todos os favoritos? Esta ação não pode ser desfeita.';

  @override
  String get favoritesCleared => 'Favoritos limpos';

  @override
  String get noFavoritesYet => 'Ainda não há favoritos';

  @override
  String get addHymnsToFavorites =>
      'Adicione hinos aos seus favoritos na página do hino';

  @override
  String get noHistoryYet => 'Ainda não há histórico';

  @override
  String removeFavorite(String title) {
    return 'Remover \"$title\" dos favoritos?';
  }

  @override
  String get removeFavoriteTitle => 'Remover Favorito';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get undo => 'Desfazer';

  @override
  String get actionReversed => 'Ação revertida';

  @override
  String hymnRange(int start, int end) {
    return 'Hinos $start-$end';
  }

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get backgroundImage => 'Imagem de fondo';

  @override
  String get showBackgroundImage => 'Mostrar imagem de fondo';

  @override
  String get playback => 'Reprodução';

  @override
  String get keepScreenOn => 'Manter tela ligada';

  @override
  String get keepScreenOnDesc => 'Não escurecer ou desligar a tela';

  @override
  String get continuousPlay => 'Reprodução contínua';

  @override
  String get data => 'Dados';

  @override
  String get clearHistoryDesc =>
      'Remover todos os hinos visualizados recentemente';

  @override
  String get clearFavoritesDesc => 'Remover todos os hinos favoritos';

  @override
  String get about => 'Sobre';

  @override
  String get website => 'Site';

  @override
  String get contribute => 'Contribuir';

  @override
  String get contactUs => 'Contate-nos';

  @override
  String get repository => 'Repositório GitHub';

  @override
  String get rateApp => 'Avaliar o App';

  @override
  String get version => 'Versão';

  @override
  String get licenses => 'Licenças';

  @override
  String sheetMusicTitle(int number) {
    return 'Partitura - Hino $number';
  }

  @override
  String failedToLoadImage(String error) {
    return 'Falha ao carregar a imagem: $error';
  }

  @override
  String get noSheetMusicAvailable =>
      'Nenhuma partitura disponível para este hinário';

  @override
  String noSheetMusicFound(int number) {
    return 'Nenhuma partitura encontrada para o hino $number';
  }

  @override
  String get share => 'Compartilhar';

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
  String get clearAll => 'Limpar tudo';

  @override
  String get clear => 'Limpar';

  @override
  String hymnTitle(int number) {
    return 'Hino $number';
  }

  @override
  String sharedFromApp(String iOSLink, String androidLink) {
    return '\n---\n✨ Descubra mais hinos no aplicativo Hinário\nBaixe aqui:\niOS: $iOSLink\nAndroid: $androidLink';
  }

  @override
  String get nowPlaying => 'Reproduzindo agora';

  @override
  String get noAudioPlaying => 'Nenhum áudio tocando';

  @override
  String get sectionHymnal => 'Hinário';

  @override
  String get sectionAppearance => 'Aparência';

  @override
  String get sectionBehavior => 'Comportamento';

  @override
  String get sectionDataManagement => 'Gerenciamento de dados';

  @override
  String get sectionAbout => 'Sobre';

  @override
  String get backgroundImageSubtitle => 'Mostrar imagem de fundo nas telas';

  @override
  String get clearHistorySubtitle =>
      'Remover todos os hinos vistos recentemente';

  @override
  String get clearFavoritesSubtitle => 'Remover todos os hinos favoritos';

  @override
  String get githubRepo => 'Repositório GitHub';

  @override
  String get selectTheme => 'Selecionar tema';

  @override
  String get appStore => 'App Store';

  @override
  String get playStore => 'Play Store';

  @override
  String couldNotLaunch(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String errorOpeningLink(String error) {
    return 'Erro ao abrir o link: $error';
  }

  @override
  String get none => 'Nenhum';

  @override
  String applicationLegalese(String year) {
    return '© $year GoGoShift';
  }

  @override
  String get aboutDevelopers =>
      'Criado com dedicação por Katherin Castillo e Isaac Rebolledo.';

  @override
  String get glassLabTitle => 'Laboratório de vidro';

  @override
  String get glassLabSubtitle =>
      'Somente depuração: teste o efeito Liquid Glass';

  @override
  String get glassLabTint => 'Tonalidade';

  @override
  String get glassLabClear => 'Transparente';

  @override
  String get glassLabTinted => 'Tingido';

  @override
  String get glassLabForceFake => 'Forçar FakeGlass';

  @override
  String get glassLabAnimatedBackground => 'Fundo animado';

  @override
  String get glassLabPerformanceOverlay => 'Sobreposição de desempenho';

  @override
  String get playerPlay => 'Reproduzir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get glassLabWater => 'Água brilhante';

  @override
  String get playerClose => 'Fechar reprodutor';

  @override
  String get playerNextHymn => 'Próximo hino';

  @override
  String get playerPreviousHymn => 'Hino anterior';

  @override
  String get glassLabPlayOwnLens => 'Lente própria na gota ▶';

  @override
  String get playerShowControls => 'Mostrar ajustes';

  @override
  String get playerHideControls => 'Ocultar ajustes';

  @override
  String get playerSeekBack => 'Voltar 10 segundos';

  @override
  String get playerSeekForward => 'Avançar 10 segundos';

  @override
  String get playerJumpStart => 'Início';

  @override
  String get playerJumpMiddle => 'Meio';

  @override
  String get playerJumpEnd => 'Final';

  @override
  String get playerPosition => 'Posição do hino';

  @override
  String playerSpeed(int value) {
    return 'Velocidade $value×';
  }

  @override
  String get playerGoToStart => 'Ir ao início';

  @override
  String get playerGoToMiddle => 'Ir para o meio';

  @override
  String get playerGoToEnd => 'Ir ao final';

  @override
  String get glassTint => 'Vidro';

  @override
  String get glassTransparent => 'Transparente';

  @override
  String get glassTinted => 'Tingido';

  @override
  String get glassTintForced => 'Tingido porque o alto contraste está ativo';

  @override
  String get glassCatalogTitle => 'Catálogo de vidro';

  @override
  String get glassCatalogSubtitle =>
      'Somente depuração: componentes do redesenho';

  @override
  String get glassCatalogButtons => 'Botões';

  @override
  String get glassCatalogControls => 'Controles';

  @override
  String get glassCatalogNavigation => 'Navegação';

  @override
  String get glassCatalogLyrics => 'Letra';

  @override
  String get sheetMusic => 'Partitura';

  @override
  String get playerOpen => 'Abrir reprodutor';

  @override
  String get searchEmptyHint => 'Busque por número, título ou letra';

  @override
  String get recentSearches => 'Pesquisas recentes';

  @override
  String get removeRecentSearch => 'Remover dos recentes';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hinos',
      one: '1 hino',
    );
    return '$_temp0';
  }

  @override
  String get selectHymnPrompt => 'Escolha um hino da lista';

  @override
  String get appFullName => 'Hinário Adventista';

  @override
  String get hymnDoesNotExist => 'Não existe';

  @override
  String get deleteDigit => 'Apagar último dígito';

  @override
  String get clearNumber => 'Apagar número';

  @override
  String sectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seções',
      one: '1 seção',
    );
    return '$_temp0';
  }
}

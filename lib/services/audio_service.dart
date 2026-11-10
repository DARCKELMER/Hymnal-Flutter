import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:just_audio/just_audio.dart';
import 'package:hymnal_app/layers/data/repository/hymnal_repository.dart';
import 'package:hymnal_app/layers/domain/model/hymn.dart';
import 'package:hymnal_app/layers/domain/model/hymnal.dart';
import 'package:hymnal_app/services/audio_handler.dart';

class AudioService extends ChangeNotifier {
  final MyAudioHandler _handler =
      GetIt.I<audio.AudioHandler>() as MyAudioHandler;

  Hymn? _currentHymn;
  Hymnal? _currentHymnal;
  String? _currentUrl;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInstrumental = true;
  bool _continuousPlay = false;
  bool _isDismissing = false;
  int _playRequestId = 0;
  double _speed = 1;

  AudioPlayer get player => _handler.player;
  Hymn? get currentHymn => _currentHymn;
  Hymnal? get currentHymnal => _currentHymnal;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isInstrumental => _isInstrumental;
  bool get hasAudio => _currentUrl != null;
  bool get continuousPlay => _continuousPlay;
  bool get isDismissing => _isDismissing;

  /// Velocidad de reproducción (1 = normal).
  double get speed => _speed;

  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService.test();

  AudioService._internal() {
    debugPrint('[AudioService] Initializing...');

    _handler.onSkipNext = skipNext;
    _handler.onSkipPrevious = skipPrevious;

    // Listen to position changes from the system
    audio.AudioService.position.listen((position) {
      _position = position;
      notifyListeners();
    });

    _handler.mediaItem.listen((item) {
      if (item?.duration != null) {
        debugPrint('[AudioService] Duration updated: ${item!.duration}');
        _duration = item.duration!;
        notifyListeners();
      }
    });

    _handler.playbackState.listen((state) {
      debugPrint(
        '[AudioService] Player state changed: playing=${state.playing}, processingState=${state.processingState}',
      );
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == audio.AudioProcessingState.loading ||
          state.processingState == audio.AudioProcessingState.buffering;

      notifyListeners();

      // Handle playback completion
      if (state.processingState == audio.AudioProcessingState.completed) {
        if (_continuousPlay) {
          debugPrint(
            '[AudioService] Playback completed, continuous play is ON — advancing to next hymn',
          );
          skipNext();
        } else {
          debugPrint('[AudioService] Playback completed, stopping playback');
          stop();
        }
      }
    });
    debugPrint('[AudioService] Initialized successfully');
  }

  void toggleContinuousPlay() {
    _continuousPlay = !_continuousPlay;
    debugPrint('[AudioService] Continuous play: $_continuousPlay');
    notifyListeners();
  }

  Future<void> skipNext() async {
    debugPrint('[AudioService] skipNext()');
    final nextHymn = await _getAdjacentHymn(1);
    if (nextHymn != null) {
      await _playAdjacentHymn(nextHymn);
    } else {
      debugPrint('[AudioService] No next hymn available');
    }
  }

  Future<void> skipPrevious() async {
    debugPrint('[AudioService] skipPrevious()');
    final prevHymn = await _getAdjacentHymn(-1);
    if (prevHymn != null) {
      await _playAdjacentHymn(prevHymn);
    } else {
      debugPrint('[AudioService] No previous hymn available');
    }
  }

  Future<Hymn?> _getAdjacentHymn(int offset) async {
    if (_currentHymn == null || _currentHymnal == null) return null;

    try {
      final repository = GetIt.I<HymnalRepository>();
      final hymns = await repository.getHymns(_currentHymnal!.id);
      final currentIndex = hymns.indexWhere(
        (h) => h.number == _currentHymn!.number,
      );

      if (currentIndex < 0) return null;

      final nextIndex = currentIndex + offset;
      if (nextIndex < 0 || nextIndex >= hymns.length) return null;

      return hymns[nextIndex];
    } catch (e) {
      debugPrint('[AudioService] Error getting adjacent hymn: $e');
      return null;
    }
  }

  Future<void> _playAdjacentHymn(Hymn hymn) async {
    if (_currentHymnal == null) return;

    try {
      final repository = GetIt.I<HymnalRepository>();
      final musicSettings = await repository.getMusicSettings(
        _currentHymnal!.id,
      );

      String? url;
      if (_isInstrumental) {
        url = musicSettings?.getInstrumentalUrl(hymn.number);
      } else {
        url = musicSettings?.getSungUrl(hymn.number);
      }

      if (url != null) {
        debugPrint(
          '[AudioService] Playing adjacent hymn: ${hymn.number} "${hymn.title}"',
        );
        // Reset _currentUrl so playHymn doesn't treat it as a toggle
        _currentUrl = null;
        await playHymn(_currentHymnal!, hymn, url);
      } else {
        debugPrint(
          '[AudioService] No ${_isInstrumental ? "instrumental" : "sung"} URL for hymn ${hymn.number}',
        );
      }
    } catch (e) {
      debugPrint('[AudioService] Error playing adjacent hymn: $e');
    }
  }

  Future<void> playHymn(
    Hymnal hymnal,
    Hymn hymn,
    String url, {
    bool? instrumental,
  }) async {
    // Keep current instrumental setting if not explicitly provided
    final isInstrumental = instrumental ?? _isInstrumental;

    debugPrint(
      '[AudioService] playHymn called: hymn=${hymn.number} "${hymn.title}", hymnal=${hymnal.id}, instrumental=$isInstrumental',
    );
    debugPrint('[AudioService] URL: $url');

    // Increment request ID to invalidate any previous pending requests
    final requestId = ++_playRequestId;

    if (_currentUrl == url && _isPlaying) {
      debugPrint('[AudioService] Same URL already playing, pausing instead');
      await pause();
      return;
    }

    _isLoading = true;
    _currentHymn = hymn;
    _currentHymnal = hymnal;
    _currentUrl = url;
    _isInstrumental = isInstrumental;
    notifyListeners();

    try {
      debugPrint(
        '[AudioService] Setting audio source... (Request ID: $requestId)',
      );

      await _handler.setAudioSource(
        url,
        audio.MediaItem(
          id: url,
          album: hymnal.name,
          title: hymn.title,
          artist: 'Hymnal',
          extras: {'hymnNumber': hymn.number, 'hymnalId': hymnal.id},
        ),
      );

      // Check if this request is still the latest one
      if (requestId != _playRequestId) {
        debugPrint(
          '[AudioService] Request ID $requestId is stale, ignoring success',
        );
        return;
      }

      debugPrint('[AudioService] Audio source set, starting playback...');
      if (_speed != 1) await _handler.setSpeed(_speed);
      await _handler.play();

      if (requestId != _playRequestId) return;

      _isLoading = false;
      debugPrint('[AudioService] Playback started successfully');
      notifyListeners();
    } catch (e) {
      // Only clear state if this was the latest request
      if (requestId == _playRequestId) {
        _isLoading = false;
        _currentHymn = null;
        _currentHymnal = null;
        _currentUrl = null;
        notifyListeners();
        debugPrint('[AudioService] ERROR playing audio: $e');
      } else {
        debugPrint(
          '[AudioService] Ignoring error from stale request ID $requestId: $e',
        );
      }
      if (requestId == _playRequestId) {
        rethrow;
      }
    }
  }

  Future<void> play() async {
    debugPrint('[AudioService] play()');
    await _handler.play();
  }

  Future<void> pause() async {
    debugPrint('[AudioService] pause()');
    await _handler.pause();
  }

  Future<void> stop() async {
    debugPrint('[AudioService] stop()');
    if (_isDismissing) return; // Already animating out

    if (_currentHymn != null) {
      // Signal the player to animate out; actual state is cleared in finalizeDismiss()
      _isDismissing = true;
      _isPlaying = false;
      notifyListeners();
    }

    try {
      await _handler.stop();
    } catch (e) {
      debugPrint('[AudioService] Error stopping audio handler: $e');
    }
  }

  void finalizeDismiss() {
    debugPrint('[AudioService] finalizeDismiss()');
    if (!_isDismissing) return;
    _isDismissing = false;
    _currentHymn = null;
    _currentHymnal = null;
    _currentUrl = null;
    _isPlaying = false;
    notifyListeners();
  }

  /// Cambia la velocidad de reproducción (se conserva entre himnos).
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    notifyListeners();
    try {
      await _handler.setSpeed(speed);
    } catch (e) {
      debugPrint('[AudioService] Error setting speed: $e');
    }
  }

  /// URL de la versión instrumental o cantada del himno actual (`null` si
  /// no existe).
  Future<String?> versionUrl({required bool instrumental}) async {
    final hymn = _currentHymn;
    final hymnal = _currentHymnal;
    if (hymn == null || hymnal == null) return null;
    try {
      final settings = await GetIt.I<HymnalRepository>().getMusicSettings(
        hymnal.id,
      );
      return instrumental
          ? settings?.getInstrumentalUrl(hymn.number)
          : settings?.getSungUrl(hymn.number);
    } catch (e) {
      debugPrint('[AudioService] Error getting version URL: $e');
      return null;
    }
  }

  /// Pasa del audio instrumental al cantado (o al revés) en el mismo punto
  /// del himno. Devuelve `false` si esa versión no existe.
  Future<bool> switchVersion({required bool instrumental}) async {
    if (instrumental == _isInstrumental) return true;
    final hymn = _currentHymn;
    final hymnal = _currentHymnal;
    final url = await versionUrl(instrumental: instrumental);
    if (hymn == null || hymnal == null || url == null) return false;
    final position = _position;
    _currentUrl = null; // que playHymn no lo tome como pausa
    await playHymn(hymnal, hymn, url, instrumental: instrumental);
    if (position > Duration.zero) await seek(position);
    return true;
  }

  Future<void> seek(Duration position) async {
    debugPrint('[AudioService] seek($position)');
    await _handler.seek(position);
  }

  Future<void> togglePlayPause() async {
    debugPrint(
      '[AudioService] togglePlayPause() — currently ${_isPlaying ? "playing" : "paused"}',
    );
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }
}

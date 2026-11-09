import 'package:hymnal_app/constants/app_links.dart';
import 'package:hymnal_app/widgets/glass/glass_background.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hymnal_app/services/audio_service.dart';
import 'package:hymnal_app/services/settings_service.dart';
import 'package:hymnal_app/services/favorites_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hymnal_app/layers/screens/hymn/hymn_screen.dart';
import 'package:hymnal_app/l10n/generated/app_localizations.dart';

part 'player_controller.dart';

class PlayerScreen extends StatefulWidget {
  final bool showBackground;
  final VoidCallback? onClose;
  const PlayerScreen({super.key, this.showBackground = true, this.onClose});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends _PlayerController {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: widget.onClose != null
              ? IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: widget.onClose,
                )
              : null,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          title: Text(l10n.nowPlaying),
        ),
        body: AnimatedBuilder(
          animation: _audioService,
          builder: (context, child) {
            final hymn = _audioService.currentHymn;
            final hymnal = _audioService.currentHymnal;

            if (hymn == null) {
              return Center(child: Text(l10n.noAudioPlaying));
            }

            final isLandscape =
                MediaQuery.of(context).orientation == Orientation.landscape;

            final albumArt = Container(
              width: isLandscape ? 140 : 100,
              height: isLandscape ? 140 : 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _audioService.isInstrumental
                    ? Icons.piano
                    : Icons.record_voice_over,
                size: isLandscape ? 50 : 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            );

            final hymnInfo = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hymn.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape ? 18 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isLandscape ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '#${hymn.number} • ${hymnal?.name ?? ""}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.7),
                    fontSize: isLandscape ? 14 : null,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _audioService.isInstrumental
                        ? l10n.instrumental
                        : l10n.sung,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );

            final controls = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _audioService.position.inMilliseconds.toDouble().clamp(
                    0,
                    _audioService.duration.inMilliseconds.toDouble().clamp(
                      1,
                      double.infinity,
                    ),
                  ),
                  max: _audioService.duration.inMilliseconds.toDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  onChanged: (value) {
                    _audioService.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioService.position),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_audioService.duration),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLandscape ? 12 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: isLandscape ? 32 : 42,
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () => _audioService.skipPrevious(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: isLandscape ? 24 : 32,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.8),
                      onPressed: () {
                        _audioService.seek(
                          _audioService.position - const Duration(seconds: 10),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _audioService.togglePlayPause(),
                      child: Container(
                        width: isLandscape ? 56 : 62,
                        height: isLandscape ? 56 : 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _audioService.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: isLandscape ? 32 : 42,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded),
                      iconSize: isLandscape ? 24 : 32,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.8),
                      onPressed: () {
                        _audioService.seek(
                          _audioService.position + const Duration(seconds: 10),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: isLandscape ? 32 : 42,
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () => _audioService.skipNext(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      color: _isFavorite ? Colors.red : null,
                      onPressed: _toggleFavorite,
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _audioService.toggleContinuousPlay(),
                      icon: Icon(
                        Icons.playlist_play,
                        color: _audioService.continuousPlay
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: isLandscape ? 18 : null,
                      ),
                      label: Text(
                        l10n.continuousPlay,
                        style: TextStyle(
                          color: _audioService.continuousPlay
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          fontWeight: _audioService.continuousPlay
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: isLandscape ? 11 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      onPressed: _shareHymn,
                    ),
                    if (isLandscape) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (hymnal != null) {
                            _openHymnPage(context, hymnal.id, hymn.number);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.library_music, size: 18),
                        label: Text(
                          l10n.viewLyrics,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );

            if (isLandscape) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Center(child: albumArt),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          hymnInfo,
                          const SizedBox(height: 8),
                          controls,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  albumArt,
                  const Spacer(),
                  hymnInfo,
                  const Spacer(),
                  controls,
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (hymnal != null) {
                        _openHymnPage(context, hymnal.id, hymn.number);
                      }
                    },
                    icon: const Icon(Icons.library_music),
                    label: Text(l10n.viewLyrics),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (!widget.showBackground) return content;

    return AnimatedBuilder(
      animation: _settingsService,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: GlassBackground(
                showImage: _settingsService.showBackgroundImage,
              ),
            ),
            content,
          ],
        );
      },
    );
  }
}

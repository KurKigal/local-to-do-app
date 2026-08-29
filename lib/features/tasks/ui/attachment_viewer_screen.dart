import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/attachments.dart';
import '../providers/task_providers.dart';

class AttachmentViewerScreen
    extends ConsumerWidget {
  const AttachmentViewerScreen({
    required this.attachment,
    super.key,
  });

  final Attachment attachment;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final repository = ref.read(
      attachmentRepositoryProvider,
    );

    return FutureBuilder<File>(
      future: repository.resolveFile(
        attachment,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return Scaffold(
            backgroundColor:
                Colors.black,
            appBar: AppBar(
              backgroundColor:
                  Colors.black,
              foregroundColor:
                  Colors.white,
              title: Text(
                attachment.originalName,
              ),
            ),
            body: const Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final file = snapshot.data;

        if (snapshot.hasError ||
            file == null) {
          return _MissingAttachmentScreen(
            name:
                attachment.originalName,
          );
        }

        return FutureBuilder<bool>(
          future: file.exists(),
          builder:
              (context, existsSnapshot) {
            if (existsSnapshot.data !=
                true) {
              if (existsSnapshot
                      .connectionState !=
                  ConnectionState.done) {
                return Scaffold(
                  backgroundColor:
                      Colors.black,
                  body: const Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              }

              return _MissingAttachmentScreen(
                name: attachment
                    .originalName,
              );
            }

            return switch (
                attachment.type) {
              AttachmentType.image =>
                _ImageViewer(
                  attachment:
                      attachment,
                  file: file,
                ),
              AttachmentType.video =>
                _VideoViewer(
                  attachment:
                      attachment,
                  file: file,
                ),
              AttachmentType.file =>
                _UnsupportedInternalViewer(
                  attachment:
                      attachment,
                ),
            };
          },
        );
      },
    );
  }
}

class _ImageViewer
    extends ConsumerWidget {
  const _ImageViewer({
    required this.attachment,
    required this.file,
  });

  final Attachment attachment;
  final File file;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
        title: Text(
          attachment.originalName,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () =>
                _share(
              context,
              ref,
              attachment,
            ),
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            filterQuality:
                FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _VideoViewer
    extends ConsumerStatefulWidget {
  const _VideoViewer({
    required this.attachment,
    required this.file,
  });

  final Attachment attachment;
  final File file;

  @override
  ConsumerState<_VideoViewer>
      createState() =>
          _VideoViewerState();
}

class _VideoViewerState
    extends ConsumerState<_VideoViewer> {
  late final VideoPlayerController
      _controller;

  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.file(
      widget.file,
    );

    _initializeFuture =
        _controller.initialize().then(
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
        title: Text(
          widget
              .attachment
              .originalName,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () =>
                _share(
              context,
              ref,
              widget.attachment,
            ),
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError ||
              !_controller
                  .value
                  .isInitialized) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  'Could not play this video.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color:
                            Colors.white,
                      ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        _controller
                            .value
                            .aspectRatio,
                    child: VideoPlayer(
                      _controller,
                    ),
                  ),
                ),
              ),
              _VideoControls(
                controller:
                    _controller,
              ),
              const SafeArea(
                top: false,
                child:
                    SizedBox(height: 8),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoControls
    extends StatefulWidget {
  const _VideoControls({
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  State<_VideoControls>
      createState() =>
          _VideoControlsState();
}

class _VideoControlsState
    extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(
      _controllerChanged,
    );
  }

  @override
  void dispose() {
    widget.controller
        .removeListener(
      _controllerChanged,
    );

    super.dispose();
  }

  void _controllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value =
        widget.controller.value;

    final duration =
        value.duration;

    final position =
        value.position > duration
            ? duration
            : value.position;

    final maxMilliseconds =
        duration.inMilliseconds <= 0
            ? 1.0
            : duration
                .inMilliseconds
                .toDouble();

    final currentMilliseconds =
        position.inMilliseconds
            .clamp(
              0,
              maxMilliseconds.toInt(),
            )
            .toDouble();

    return Container(
      color: Colors.black,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      child: Column(
        children: [
          Slider(
            value: currentMilliseconds,
            max: maxMilliseconds,
            onChanged: (value) {
              widget.controller.seekTo(
                Duration(
                  milliseconds:
                      value.round(),
                ),
              );
            },
          ),
          Row(
            children: [
              Text(
                _formatDuration(
                  position,
                ),
                style:
                    const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              IconButton.filled(
                onPressed: () {
                  if (value.isPlaying) {
                    widget.controller
                        .pause();
                  } else {
                    widget.controller
                        .play();
                  }
                },
                icon: Icon(
                  value.isPlaying
                      ? Icons
                          .pause_rounded
                      : Icons
                          .play_arrow_rounded,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(
                  duration,
                ),
                style:
                    const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final totalSeconds =
        duration.inSeconds;

    final hours =
        totalSeconds ~/ 3600;

    final minutes =
        (totalSeconds % 3600) ~/
            60;

    final seconds =
        totalSeconds % 60;

    final mm =
        minutes.toString().padLeft(
      2,
      '0',
    );

    final ss =
        seconds.toString().padLeft(
      2,
      '0',
    );

    if (hours > 0) {
      return '$hours:$mm:$ss';
    }

    return '$mm:$ss';
  }
}

class _UnsupportedInternalViewer
    extends ConsumerWidget {
  const _UnsupportedInternalViewer({
    required this.attachment,
  });

  final Attachment attachment;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attachment.originalName,
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(28),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .description_outlined,
                size: 54,
              ),
              const SizedBox(height: 18),
              Text(
                attachment.originalName,
                textAlign:
                    TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final result = await ref
                      .read(
                        attachmentActionServiceProvider,
                      )
                      .openExternal(
                        attachment,
                      );

                  if (!result.success &&
                      context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ??
                              'Could not open file.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.open_in_new_rounded,
                ),
                label: const Text(
                  'Open with app',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    _share(
                  context,
                  ref,
                  attachment,
                ),
                icon: const Icon(
                  Icons.share_outlined,
                ),
                label:
                    const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingAttachmentScreen
    extends StatelessWidget {
  const _MissingAttachmentScreen({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attachment',
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(28),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .broken_image_outlined,
                size: 54,
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
              const SizedBox(height: 16),
              Text(
                'File not found',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _share(
  BuildContext context,
  WidgetRef ref,
  Attachment attachment,
) async {
  try {
    await ref
        .read(
          attachmentActionServiceProvider,
        )
        .share(attachment);
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Could not share attachment: $error',
        ),
      ),
    );
  }
}

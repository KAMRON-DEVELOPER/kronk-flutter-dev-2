import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/feed/feed_card_state_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/general/video_controller_provider.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/widgets/feed/feed_video_error_widget.dart';
import 'package:kronk/widgets/feed/feed_video_shimmer_widget.dart';
import 'package:kronk/widgets/feed/video_overlay_widget.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// FeedCard
class FeedCard extends ConsumerWidget {
  final FeedModel initialFeed;
  final bool isRefreshing;

  const FeedCard({super.key, required this.initialFeed, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final FeedModel feed = ref.watch(feedCardStateProvider(initialFeed));
    final FeedCardStateNotifier notifier = ref.read(feedCardStateProvider(initialFeed).notifier);

    final displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
    return VisibilityDetector(
      key: ValueKey('1-${feed.id}'),
      onVisibilityChanged: (info) async => await notifier.onVisibilityChanged(info: info),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(0),
        color: theme.primaryBackground.withValues(alpha: displayState.cardOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isFloating ? displayState.cardBorderRadius : 0),
          side: isFloating ? BorderSide(color: theme.secondaryBackground, width: 0.5) : BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.all(8.dp),
          child: Column(
            spacing: 8.dp,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedHeaderSection(feed: feed, isRefreshing: isRefreshing, notifier: notifier),
              FeedBodySection(feed: feed, notifier: notifier),
              FeedMediaSection(feed: feed, notifier: notifier, isRefreshing: isRefreshing),
              FeedActionSection(feed: feed, notifier: notifier),
            ],
          ),
        ),
      ),
    );
  }
}

/// FeedBodySection
class FeedBodySection extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedBodySection({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;

    if (isEditable) {
      return FeedBodyInputWidget(feed: feed, notifier: notifier);
    }
    return Text(
      feed.body!,
      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
    );
  }
}

/// FeedBodyInputWidget
class FeedBodyInputWidget extends ConsumerStatefulWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedBodyInputWidget({super.key, required this.feed, required this.notifier});

  @override
  ConsumerState<FeedBodyInputWidget> createState() => _FeedBodyInputWidgetState();
}

class _FeedBodyInputWidgetState extends ConsumerState<FeedBodyInputWidget> {
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: widget.feed.body);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    return TextField(
      controller: textEditingController,
      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
        border: InputBorder.none,
        counter: null,
        counterStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
      ),
      maxLength: 300,
      minLines: 1,
      maxLines: 6,
      cursorColor: theme.primaryText,
      onChanged: (value) {
        widget.notifier.updateField(feed: widget.feed.copyWith(body: value));
      },
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
      },
    );
  }
}

/// FeedHeaderSection
class FeedHeaderSection extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedHeaderSection({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    double blurSigma = isRefreshing ? 3 : 0;

    final String? avatarUrl = feed.author.avatarUrl;
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Left side items (avatar + name + time)
        Row(
          spacing: 8.dp,
          children: [
            /// Avatar
            GestureDetector(
              onTap: () {
                final Storage storage = Storage();
                final UserModel? user = storage.getUser();
                context.go('/profile', extra: user?.id == feed.author.id ? null : feed.author.id);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.dp),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Image.network(
                    '${constants.bucketEndpoint}/$avatarUrl',
                    fit: BoxFit.cover,
                    width: 32.dp,
                    cacheWidth: 32.cacheSize(context),
                    loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress == null ? child : Icon(Icons.account_circle_rounded, size: 32.dp, color: theme.primaryText),
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle_rounded, size: 32.dp, color: theme.primaryText),
                  ),
                ),
              ),
            ),

            /// Name
            Text(
              '${feed.author.name}',
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
            ),
            if (!isEditable)
              Text(
                FeedModel.timeAgoShort(dateTime: feed.createdAt!),
                style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
              ),
          ],
        ),

        /// FeedCardMenuButton
        FeedCardMenuButton(feed: feed, notifier: notifier),
      ],
    );
  }
}

/// FeedCardMenuButton
class FeedCardMenuButton extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedCardMenuButton({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;
    return Row(
      spacing: 16.dp,
      children: [
        if (isEditable)
          GestureDetector(
            onTap: () async {
              try {
                if (feed.feedMode == FeedMode.create) await notifier.save();
                if (feed.feedMode == FeedMode.edit) await notifier.update();
              } catch (error) {
                myLogger.e('$error');

                String errorMessage;
                if (error is List) {
                  errorMessage = error.join(', ');
                } else if (error is Exception && error.toString().startsWith('Exception: [')) {
                  // Extract inner list string from Exception string: "Exception: [msg1, msg2]"
                  errorMessage = error.toString().replaceFirst('Exception: [', '').replaceFirst(']', '');
                } else {
                  errorMessage = error.toString();
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: theme.tertiaryBackground,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                    content: Text(errorMessage, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.redAccent)),
                  ),
                );
              }
            },
            child: Text(
              'save',
              style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

        GestureDetector(
          child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24.dp),
          onTap: () {
            final Storage storage = Storage();
            final UserModel? user = storage.getUser();
            if (feed.feedMode == FeedMode.create || feed.author.id != user?.id) return;
            showModalBottomSheet(
              context: context,
              backgroundColor: theme.secondaryBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12.dp))),
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      splashColor: Colors.red,
                      iconColor: theme.primaryText,
                      titleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                      subtitleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                      leading: const Icon(Icons.flag_rounded),
                      title: const Text('Edit'),
                      // subtitle: const Text('subtitle'),
                      onTap: () {
                        notifier.updateField(feed: feed.copyWith(feedMode: FeedMode.edit));
                        context.pop();
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      iconColor: theme.primaryText,
                      titleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                      subtitleTextStyle: GoogleFonts.quicksand(color: theme.primaryText),
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: const Text('Delete'),
                      // subtitle: const Text('subtitle'),
                      onTap: () async {
                        final communityServices = FeedService();
                        try {
                          final bool ok = await communityServices.fetchDeleteFeed(feedId: feed.id);
                          myLogger.d('ok: $ok');
                          if (ok) {
                            await ref.read(timelineNotifierProvider(TimelineType.following).notifier).refresh(timelineType: TimelineType.following);
                          }
                          if (!context.mounted) return;
                          context.pop();
                        } catch (error) {
                          String errorMessage;
                          if (error is List) {
                            errorMessage = error.join(', ');
                          } else if (error is Exception && error.toString().startsWith('Exception: [')) {
                            // Extract inner list string from Exception string: "Exception: [msg1, msg2]"
                            errorMessage = error.toString().replaceFirst('Exception: [', '').replaceFirst(']', '');
                          } else {
                            errorMessage = error.toString();
                          }

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: theme.tertiaryBackground,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                              content: Text(errorMessage, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.redAccent)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// FeedMediaSection
class FeedMediaSection extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedMediaSection({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;
    final bool showVideo = feed.videoFile != null || feed.videoUrl != null;
    final bool showImages = feed.imageFiles != null && feed.imageFiles!.isNotEmpty || feed.imageUrls.isNotEmpty;

    if (showVideo) return FeedVideoWidget(feed: feed, isRefreshing: isRefreshing, notifier: notifier);
    if (showImages) return FeedImageWidget(feed: feed, isRefreshing: isRefreshing, notifier: notifier);
    if (isEditable) return AddMediaWidget(feed: feed, notifier: notifier);
    return const SizedBox.shrink();
  }
}

/// FeedVideoWidget
class FeedVideoWidget extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedVideoWidget({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final VideoSourceState videoSourceState = VideoSourceState(feedId: feed.id, videoUrl: feed.videoUrl, videoFile: feed.videoFile);
    final videoController = ref.watch(videoControllerProvider(videoSourceState));
    final videoControllerNotifier = ref.read(videoControllerProvider(videoSourceState).notifier);

    final double videoWidth = Sizes.screenWidth - 40.dp;
    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;
    double blurSigma = isRefreshing ? 3 : 0;

    return videoController.when(
      data: (VideoPlayerController controller) {
        return Stack(
          alignment: Alignment.center,
          children: [
            /// Actual Video
            ClipRRect(
              borderRadius: BorderRadius.circular(10.dp),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: videoWidth / controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),

            /// Animated icons layer
            VideoOverlayWidget(feedId: feed.id),

            /// Gesture handling layer
            Positioned.fill(
              child: Row(
                children: [
                  /// Left double tap
                  Expanded(
                    child: GestureDetector(
                      onTap: () async => await videoControllerNotifier.togglePlayPause(),
                      onLongPressStart: (details) async => await videoControllerNotifier.startFastForward(),
                      onLongPressEnd: (details) async => await videoControllerNotifier.stopFastForward(),
                      onDoubleTap: () async => await videoControllerNotifier.seekTo(duration: const Duration(seconds: 5), backward: true),
                    ),
                  ),

                  /// Right double tap
                  Expanded(
                    child: GestureDetector(
                      onTap: () async => await videoControllerNotifier.togglePlayPause(),
                      onLongPressStart: (details) async => await videoControllerNotifier.startFastForward(),
                      onLongPressEnd: (details) async => await videoControllerNotifier.stopFastForward(),
                      onDoubleTap: () async => await videoControllerNotifier.seekTo(duration: const Duration(seconds: 5)),
                    ),
                  ),
                ],
              ),
            ),

            /// Mute Button and video duration
            Positioned(
              bottom: 8,
              right: 8,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, VideoPlayerValue value, child) {
                  String formatDuration(Duration d) {
                    final minutes = d.inMinutes.toString().padLeft(2, '0');
                    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
                    return '$minutes:$seconds';
                  }

                  final positionText = formatDuration(value.position);
                  final totalText = formatDuration(controller.value.duration);
                  final durationText = '$positionText/$totalText';

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.dp, vertical: 2.dp),
                    decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      spacing: 8.dp,
                      children: [
                        Text(
                          durationText,
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 12.dp),
                        ),
                        GestureDetector(
                          child: Icon(controller.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: theme.secondaryText),
                          onTap: () async => await videoControllerNotifier.toggleMute(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (isEditable)
              Positioned(
                top: 8.dp,
                right: 8.dp,
                child: GestureDetector(
                  onTap: () {
                    if (feed.feedMode == FeedMode.create) notifier.updateField(feed: feed.copyWith(videoFile: null, videoUrl: null));
                    if (feed.feedMode == FeedMode.edit && feed.videoUrl != null) notifier.update(removeVideoTarget: feed.videoUrl);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12.dp)),
                    child: Icon(Icons.close_rounded, color: theme.secondaryText, size: 24.dp),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const FeedVideoShimmerWidget(),
      error: (error, _) {
        myLogger.e('error: $error');
        return const FeedVideoErrorWidget();
      },
    );
  }
}

/// FeedImageWidget
class FeedImageWidget extends ConsumerWidget {
  final FeedModel feed;
  final bool isRefreshing;
  final FeedCardStateNotifier notifier;

  const FeedImageWidget({super.key, required this.feed, required this.isRefreshing, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);

    final bool isEditable = feed.feedMode == FeedMode.create || feed.feedMode == FeedMode.edit;
    final imageFiles = feed.imageFiles ?? [];
    final imageUrls = feed.imageUrls;
    final combinedImages = [...feed.imageUrls.map((url) => (isFile: false, data: url)), ...imageFiles.map((file) => (isFile: true, data: file))];
    final imageCount = combinedImages.length;
    final showAddButton = isEditable && imageCount < 4;
    double blurSigma = isRefreshing ? 3 : 0;
    final double imageWidth = Sizes.screenWidth - 40.dp;

    myLogger.w('imageCount: $imageCount');

    if (imageCount == 1 && !isEditable) {
      final imageUrl = '${constants.bucketEndpoint}/${imageUrls.first}';
      return FutureBuilder<Size>(
        future: _getNetworkImageSize(imageUrl),
        builder: (context, snapshot) {
          final double imageHeight = snapshot.hasData ? (imageWidth * snapshot.data!.height / snapshot.data!.width) : imageWidth * 9 / 16;

          return ClipRRect(
            borderRadius: BorderRadius.circular(8.dp),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Image.network(
                imageUrl,
                width: imageWidth,
                height: imageHeight,
                cacheWidth: imageWidth.cacheSize(context),
                cacheHeight: imageHeight.cacheSize(context),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                    ? child
                    : Container(
                        width: imageWidth,
                        height: imageHeight,
                        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(8.dp)),
                      ),
                errorBuilder: (context, error, stackTrace) => Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(8.dp)),
                ),
              ),
            ),
          );
        },
      );
    }

    List<StaggeredGridTile> tiles = [];

    for (int index = 0; index < combinedImages.length; index++) {
      final item = combinedImages[index];
      final isFile = item.isFile;
      final data = item.data;

      tiles.add(
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double maxHeight = constraints.maxHeight;
              final int cacheWidth = maxWidth.cacheSize(context);
              final int cacheHeight = maxHeight.cacheSize(context);

              Widget imageWidget;
              if (isFile) {
                imageWidget = Image.file(data as File, fit: BoxFit.cover, width: double.infinity, height: double.infinity, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
              } else {
                imageWidget = Image.network(
                  '${constants.bucketEndpoint}/$data',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: cacheWidth,
                  cacheHeight: cacheHeight,
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(8.dp),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                        child: imageWidget,
                      ),
                    ),
                    if (isEditable)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            if (isFile) {
                              final updated = List<File>.from(feed.imageFiles ?? [])..remove(data);
                              notifier.updateField(feed: feed.copyWith(imageFiles: updated));
                            } else {
                              notifier.update(removeImageTargets: [data as String]);
                            }
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: theme.primaryBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12.dp)),
                            child: Icon(Icons.close_rounded, size: 24.dp, color: theme.secondaryText),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    if (showAddButton) {
      tiles.add(
        StaggeredGridTile.count(
          crossAxisCellCount: imageCount == 2 ? 2 : 1,
          mainAxisCellCount: 1,
          child: GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final int remaining = 4 - imageCount;
              final List<XFile> selectedImages = await picker.pickMultiImage(imageQuality: 100, limit: remaining >= 2 ? remaining : null);

              if (selectedImages.isEmpty) return;

              final images = selectedImages.where((f) => lookupMimeType(f.path)?.startsWith('image/') ?? false).map((x) => File(x.path)).toList();

              if (images.isNotEmpty) {
                final updated = List<File>.from(feed.imageFiles as Iterable)..addAll(images);
                notifier.updateField(feed: feed.copyWith(imageFiles: updated));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.dp),
                border: Border.all(color: theme.outline),
              ),
              child: Icon(Icons.add_rounded, size: 24.dp, color: theme.secondaryText),
            ),
          ),
        ),
      );
    }

    return StaggeredGrid.count(crossAxisCount: 2, mainAxisSpacing: 4.dp, crossAxisSpacing: 4.dp, children: tiles);
  }
}

/// AddMediaWidget
class AddMediaWidget extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const AddMediaWidget({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final displayState = ref.watch(feedsScreenStyleProvider);
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final List<XFile> selectedFiles = await picker.pickMultipleMedia();
        if (selectedFiles.isEmpty) return;

        final fl = selectedFiles.firstOrNull;
        if (fl != null) {
          myLogger.d('mimeType from mime lookupMimeType: ${lookupMimeType(fl.path)}');
          myLogger.d('name: ${fl.name}');
          myLogger.d('path: ${fl.path}');
        }
        final images = selectedFiles.where((f) => lookupMimeType(f.path)?.startsWith('image/') ?? false).toList();
        final videos = selectedFiles.where((f) => lookupMimeType(f.path)?.startsWith('video/') ?? false).toList();

        if (videos.length == 1) {
          notifier.updateField(feed: feed.copyWith(videoFile: File(videos.first.path)));
        } else if (images.isNotEmpty) {
          notifier.updateField(feed: feed.copyWith(imageFiles: images.map((x) => File(x.path)).toList()));
        }
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(displayState.cardBorderRadius),
          border: BoxBorder.all(color: theme.outline),
        ),
        width: double.infinity,
        height: 220,
        child: Icon(Icons.add_rounded, size: 24, color: theme.secondaryText),
      ),
    );
  }
}

/// FeedActionSection
class FeedActionSection extends ConsumerWidget {
  final FeedModel feed;
  final FeedCardStateNotifier notifier;

  const FeedActionSection({super.key, required this.feed, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 24.dp,
          children: [
            /// Comments
            FeedActionRow(
              iconDataFill: KronkIcon.messageCircle1,
              iconDataOutline: KronkIcon.messageSquareLeft2,
              count: feed.engagement.comments,
              onTap: () => context.push('/feeds/feed', extra: feed),
            ),

            /// Repost & quote
            FeedActionRow(
              iconDataFill: KronkIcon.repeat6,
              iconDataOutline: KronkIcon.repeat6,
              interacted: (feed.engagement.reposted == true) || (feed.engagement.quoted == true),
              count: feed.repostsAndQuotes,
              onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.reposts),
            ),

            /// Heart
            FeedActionRow(
              iconDataFill: KronkIcon.heartFill,
              iconDataOutline: KronkIcon.heartOutline,
              interacted: feed.engagement.liked ?? false,
              count: feed.engagement.likes,
              onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.likes),
            ),

            /// Views
            FeedActionRow(iconDataFill: KronkIcon.eyeOpen, iconDataOutline: KronkIcon.eyeOpen, count: feed.engagement.views),
          ],
        ),

        /// Bookmark icons
        FeedActionRow(
          iconDataFill: KronkIcon.bookmarkFill5,
          iconDataOutline: KronkIcon.bookmarkOutline5,
          interacted: feed.engagement.bookmarked ?? false,
          onTap: feed.feedMode == FeedMode.create ? null : () async => notifier.handleEngagement(engagementType: EngagementType.bookmarks),
        ),
      ],
    );
  }
}

/// FeedActionRow
class FeedActionRow extends ConsumerWidget {
  final IconData iconDataFill;
  final IconData iconDataOutline;
  final bool interacted;
  final int? count;
  final void Function()? onTap;

  const FeedActionRow({super.key, required this.iconDataFill, required this.iconDataOutline, this.interacted = false, this.count, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    final IconData iconToUse = interacted ? iconDataFill : iconDataOutline;
    final Color color = interacted ? iconDataOutline.appropriateColor : theme.primaryText;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        spacing: 4,
        children: [
          Icon(iconToUse, size: 20, color: color, weight: 600),
          if (count != null)
            AnimatedFlipCounter(
              hideLeadingZeroes: true,
              value: count!.toDouble(),
              textStyle: GoogleFonts.quicksand(color: color, fontSize: 16, height: 0),
            ),
        ],
      ),
    );
  }
}

Future<Size> _getNetworkImageSize(String url) async {
  final Completer<Size> completer = Completer();
  final Image image = Image.network(url);
  image.image
      .resolve(const ImageConfiguration())
      .addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          final myImage = info.image;
          final size = Size(myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        }),
      );
  return completer.future;
}

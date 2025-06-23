import 'dart:io';

import 'package:kronk/constants/enums.dart';

class VideoOverlayState {
  final bool showPlayPauseOverlay;
  final bool showSkipOverlay;
  final bool skipRight;
  final bool isPlay;
  final bool isCompleted;
  final bool showMuteOverlay;
  final bool fastForward;
  final bool showFastForward;

  VideoOverlayState({
    this.showPlayPauseOverlay = false,
    this.isPlay = false,
    this.showSkipOverlay = false,
    this.skipRight = false,
    this.isCompleted = false,
    this.showMuteOverlay = false,
    this.fastForward = false,
    this.showFastForward = false,
  });

  VideoOverlayState copyWith({
    bool? showPlayPauseOverlay,
    bool? isPlay,
    bool? showSkipOverlay,
    bool? skipRight,
    bool? isCompleted,
    bool? showMuteOverlay,
    bool? fastForward,
    bool? showFastForward,
  }) {
    return VideoOverlayState(
      showPlayPauseOverlay: showPlayPauseOverlay ?? this.showPlayPauseOverlay,
      isPlay: isPlay ?? this.isPlay,
      showSkipOverlay: showSkipOverlay ?? this.showSkipOverlay,
      skipRight: skipRight ?? this.skipRight,
      isCompleted: isCompleted ?? this.isCompleted,
      showMuteOverlay: showMuteOverlay ?? this.showMuteOverlay,
      fastForward: fastForward ?? this.fastForward,
      showFastForward: showFastForward ?? this.showFastForward,
    );
  }
}

class FeedScreenDisplayState {
  final FeedScreenStyle feedScreenDisplayStyle;
  final double cardOpacity;
  final double cardBorderRadius;
  final String backgroundImagePath;

  FeedScreenDisplayState({required this.feedScreenDisplayStyle, required this.cardOpacity, required this.cardBorderRadius, required this.backgroundImagePath});

  FeedScreenDisplayState copyWith({FeedScreenStyle? feedScreenDisplayStyle, double? cardOpacity, double? cardBorderRadius, String? backgroundImagePath}) {
    return FeedScreenDisplayState(
      feedScreenDisplayStyle: feedScreenDisplayStyle ?? this.feedScreenDisplayStyle,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  factory FeedScreenDisplayState.from(
    FeedScreenDisplayState base, {
    FeedScreenStyle? feedScreenDisplayStyle,
    double? cardOpacity,
    double? cardBorderRadius,
    String? backgroundImagePath,
  }) {
    return FeedScreenDisplayState(
      feedScreenDisplayStyle: feedScreenDisplayStyle ?? base.feedScreenDisplayStyle,
      cardOpacity: cardOpacity ?? base.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? base.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? base.backgroundImagePath,
    );
  }
}

class VideoSourceState {
  final String? feedId;
  final String? videoUrl;
  final File? videoFile;

  VideoSourceState({required this.feedId, this.videoUrl, this.videoFile});

  @override
  bool operator ==(Object other) {
    return other is VideoSourceState && other.videoUrl == videoUrl && other.videoFile?.path == videoFile?.path;
  }

  @override
  int get hashCode => Object.hash(videoUrl, videoFile?.path);
}

// class FeedNotificationState {
//   final ScrollController scrollController;
//   final GlobalKey<RefreshIndicatorState> refreshKey;
//   final List<String> avatarUrls;
//
//   FeedNotificationState({required this.scrollController, required this.refreshKey, this.avatarUrls = const []});
//
//   factory FeedNotificationState.from(FeedNotificationState base, {ScrollController? scrollController, GlobalKey<RefreshIndicatorState>? refreshKey, List<String>? avatarUrls}) {
//     return FeedNotificationState(scrollController: scrollController ?? base.scrollController, refreshKey: refreshKey ?? base.refreshKey, avatarUrls: avatarUrls ?? base.avatarUrls);
//   }
// }

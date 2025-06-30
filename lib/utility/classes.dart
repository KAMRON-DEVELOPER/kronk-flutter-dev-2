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
  final ScreenStyle screenStyle;
  final double cardOpacity;
  final double cardBorderRadius;
  final String backgroundImagePath;

  FeedScreenDisplayState({required this.screenStyle, required this.cardOpacity, required this.cardBorderRadius, required this.backgroundImagePath});

  FeedScreenDisplayState copyWith({ScreenStyle? screenStyle, double? cardOpacity, double? cardBorderRadius, String? backgroundImagePath}) {
    return FeedScreenDisplayState(
      screenStyle: screenStyle ?? this.screenStyle,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  factory FeedScreenDisplayState.from(
    FeedScreenDisplayState base, {
    ScreenStyle? feedScreenDisplayStyle,
    double? cardOpacity,
    double? cardBorderRadius,
    String? backgroundImagePath,
  }) {
    return FeedScreenDisplayState(
      screenStyle: feedScreenDisplayStyle ?? base.screenStyle,
      cardOpacity: cardOpacity ?? base.cardOpacity,
      cardBorderRadius: cardBorderRadius ?? base.cardBorderRadius,
      backgroundImagePath: backgroundImagePath ?? base.backgroundImagePath,
    );
  }
}

class ChatsScreenDisplayState {
  final ScreenStyle screenStyle;
  final double tileOpacity;
  final double tileBorderRadius;
  final String backgroundImagePath;

  ChatsScreenDisplayState({required this.screenStyle, required this.tileOpacity, required this.tileBorderRadius, required this.backgroundImagePath});

  ChatsScreenDisplayState copyWith({ScreenStyle? screenStyle, double? tileOpacity, double? tileBorderRadius, String? backgroundImagePath}) {
    return ChatsScreenDisplayState(
      screenStyle: screenStyle ?? this.screenStyle,
      tileOpacity: tileOpacity ?? this.tileOpacity,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
    );
  }

  factory ChatsScreenDisplayState.from(ChatsScreenDisplayState base, {ScreenStyle? screenStyle, double? tileOpacity, double? tileBorderRadius, String? backgroundImagePath}) {
    return ChatsScreenDisplayState(
      screenStyle: screenStyle ?? base.screenStyle,
      tileOpacity: tileOpacity ?? base.tileOpacity,
      tileBorderRadius: tileBorderRadius ?? base.tileBorderRadius,
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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:visibility_detector/visibility_detector.dart';

final feedCardStateProvider = AutoDisposeNotifierProviderFamily<FeedCardStateNotifier, FeedModel, FeedModel>(() => FeedCardStateNotifier());

class FeedCardStateNotifier extends AutoDisposeFamilyNotifier<FeedModel, FeedModel> {
  Timer? _viewTimer;

  @override
  FeedModel build(FeedModel initialFeed) {
    ref.onDispose(() {
      myLogger.t('onDispose is working...');
      if (_viewTimer != null && _viewTimer!.isActive) _viewTimer?.cancel();
    });

    ref.onCancel(() {
      myLogger.t('onCancel is working...');
      if (_viewTimer != null && _viewTimer!.isActive) _viewTimer?.cancel();
    });

    return initialFeed;
  }

  void updateField({required FeedModel feed}) {
    myLogger.d('feed.id: ${feed.id}');
    myLogger.d('feed.body: ${feed.body}');
    myLogger.d('feed.author.name: ${feed.author.name}');
    myLogger.d('feed.author.username: ${feed.author.username}');
    myLogger.d('feed.engagement.likes: ${feed.engagement.likes}');
    myLogger.d('feed.engagement.bookmarks: ${feed.engagement.bookmarks}');
    myLogger.d('feed.engagement.liked: ${feed.engagement.liked}');
    myLogger.d('feed.engagement.bookmarked: ${feed.engagement.bookmarked}');
    state = feed;
  }

  Future<void> save() async {
    final FeedService service = FeedService();

    myLogger.d('SAVE');
    myLogger.d('state.body: ${state.body}');
    myLogger.d('state.state.author.name: ${state.author.name}');
    myLogger.d('state.imageFiles.length: ${state.imageFiles?.length}');
    myLogger.d('state.state.videoFile?.path: ${state.videoFile?.path}');

    try {
      final feed = state;
      final hasImages = feed.imageFiles?.isNotEmpty ?? false;
      final hasVideo = feed.videoFile != null;

      Map<String, dynamic> map = {
        'body': feed.body,
        if (feed.feedVisibility != null) 'feed_visibility': feed.feedVisibility?.name,
        if (feed.commentPolicy != null) 'commenting_policy': feed.commentPolicy?.name,
        if (feed.scheduledAt != null) 'scheduled_at': feed.scheduledAt,
      };

      if (hasImages || hasVideo) {
        if (hasVideo) {
          map['video_file'] = await MultipartFile.fromFile(feed.videoFile!.path, filename: feed.videoFile!.path.split('/').last);
        }

        if (hasImages) {
          map['image_files'] = await Future.wait(
            feed.imageFiles!.map((image) async {
              return await MultipartFile.fromFile(image.path, filename: image.path.split('/').last);
            }),
          );
        }
      }

      myLogger.d('map: $map');
      Response jsonResponse = await service.fetchCreateFeed(formData: FormData.fromMap(map));
      myLogger.d('jsonResponse.data: ${jsonResponse.data}, statusCode: ${jsonResponse.statusCode}');

      final Map<String, dynamic> data = jsonResponse.data;

      final updatedFeed = state.copyWith(
        id: data['id'],
        createdAt: DateTime.fromMillisecondsSinceEpoch((data['created_at'] * 1000).toInt()),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((data['updated_at'] * 1000).toInt()),
        body: data['body'],
        author: AuthorModel.fromJson(data['author']),
        feedVisibility: FeedVisibility.values.byName(data['feed_visibility']),
        commentPolicy: CommentingPolicy.values.byName(data['comment_policy']),
        feedModeEnum: FeedModeEnum.view,
      );

      state = updatedFeed;
    } catch (error) {
      myLogger.e('error: $error');
      rethrow;
    }
  }

  Future<void> update({String? removeVideoTarget, List<String>? removeImageTargets}) async {
    final FeedService service = FeedService();

    myLogger.d('UPDATE');
    myLogger.d('state.body: ${state.body}');
    myLogger.d('state.imageFiles.length: ${state.imageFiles?.length}');
    myLogger.d('state.state.videoFile?.path: ${state.videoFile?.path}');
    myLogger.d('state.state.author.name: ${state.author.name}');

    try {
      final map = {'': 1};
      final jsonResponse = await service.fetchUpdateFeed(feedId: state.id, formData: FormData.fromMap(map));
      myLogger.d('jsonResponse, statusCode: $jsonResponse');

      // if (jsonResponse.statusCode == 200 && removeVideoTarget != null) {
      //   state = state.copyWith(videoUrl: null);
      // } else if (jsonResponse.statusCode == 200 && removeImageTargets != null && removeImageTargets.isNotEmpty) {
      //   state = state.copyWith(imageUrls: null);
      // } else {
      //   state = state.copyWith(feedModeEnum: FeedModeEnum.view);
      // }
      //
      // final hasImages = state.imageFiles?.isNotEmpty;
      // final hasVideo = state.videoFile != null;
      //
      // if (hasImages != null && !hasImages && !hasVideo) return;
      //
      // final Map<String, dynamic> mediaMap = {};
      //
      // if (hasVideo) {
      //   mediaMap['video_file'] = await MultipartFile.fromFile(state.videoFile!.path, filename: state.videoFile!.path.split('/').last);
      // }
      //
      // if (hasImages != null && hasImages && state.imageFiles != null) {
      //   mediaMap['image_files'] = await Future.wait(
      //     state.imageFiles.map((image) async {
      //       return await MultipartFile.fromFile(image.path, filename: image.path.split('/').last);
      //     }),
      //   );
      // }
      //
      // final Response _ = await service.fetchUpdateFeedMedia(feedId: state.id!, formData: FormData.fromMap(mediaMap));
      // await ref.read(timelineNotifierProvider(TimelineType.following).notifier).refresh(timelineType: TimelineType.following);
    } catch (error) {
      myLogger.e('error: $error');
      rethrow;
    }
  }

  Future<void> onVisibilityChanged({required VisibilityInfo info}) async {
    if ((state.feedModeEnum.name == FeedModeEnum.create.name) || (state.engagement.viewed ?? false)) return;

    final FeedService feedService = FeedService();

    final hasMedia = state.imageUrls.isNotEmpty || state.videoUrl != null;
    final isVisibleEnough = hasMedia ? info.visibleFraction > 0.25 : info.visibleFraction > 0;

    if (isVisibleEnough) {
      _viewTimer ??= Timer(const Duration(seconds: 2), () async {
        final EngagementModel engagement = await feedService.fetchSetEngagement(feedId: state.id, engagementType: EngagementType.views);
        state = state.copyWith(engagement: engagement);
      });
    } else {
      _viewTimer?.cancel();
      _viewTimer = null;
    }
  }

  Future<void> handleEngagement({required EngagementType engagementType}) async {
    final FeedService feedService = FeedService();
    try {
      final bool isSetInteraction = switch (engagementType) {
        EngagementType.likes => state.engagement.liked != true,
        EngagementType.bookmarks => state.engagement.bookmarked != true,
        EngagementType.reposts => state.engagement.reposted != true,
        EngagementType.quotes => state.engagement.quoted != true,
        EngagementType.views => state.engagement.viewed != true,
        EngagementType.feeds => throw UnimplementedError(),
      };

      final EngagementModel engagement = isSetInteraction
          ? await feedService.fetchSetEngagement(feedId: state.id, engagementType: engagementType)
          : await feedService.fetchRemoveEngagement(feedId: state.id, engagementType: engagementType);

      state = state.copyWith(engagement: engagement);
    } catch (error, _) {
      myLogger.e('catch in handleEngagement: ${error.toString()}');
    }
  }
}

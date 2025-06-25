import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:kronk/constants/enums.dart';

class EngagementModel extends Equatable {
  final int? comments;
  final int? reposts;
  final int? quotes;
  final int? likes;
  final int? views;
  final int? bookmarks;
  final bool? reposted;
  final bool? quoted;
  final bool? liked;
  final bool? viewed;
  final bool? bookmarked;

  const EngagementModel({this.comments, this.reposts, this.quotes, this.likes, this.views, this.bookmarks, this.reposted, this.quoted, this.liked, this.viewed, this.bookmarked});

  factory EngagementModel.fromJson(Map<String, dynamic> json) {
    return EngagementModel(
      comments: json['comments'],
      reposts: json['reposts'],
      quotes: json['quotes'],
      likes: json['likes'],
      views: json['views'],
      bookmarks: json['bookmarks'],
      reposted: json['reposted'],
      quoted: json['quoted'],
      liked: json['liked'],
      viewed: json['viewed'],
      bookmarked: json['bookmarked'],
    );
  }

  @override
  List<Object?> get props => [comments, reposts, quotes, likes, views, bookmarks, reposted, quoted, liked, viewed, bookmarked];
}

class AuthorModel extends Equatable {
  final String? id;
  final String? name;
  final String? username;
  final String? avatarUrl;

  const AuthorModel({this.id, this.name, this.username, this.avatarUrl});

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(id: json['id'], name: json['name'], username: json['username'], avatarUrl: json['avatarUrl']);
  }

  @override
  List<Object?> get props => [id, name, username, avatarUrl];
}

class FeedModel extends Equatable {
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final String? id;
  final String? body;
  final AuthorModel author;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? scheduledAt;
  final FeedVisibility? feedVisibility;
  final CommentingPolicy? commentPolicy;
  final EngagementModel engagement;
  final String? quoteId;
  final String? parentId;
  final List<File>? imageFiles;
  final File? videoFile;
  final FeedModeEnum feedModeEnum;

  const FeedModel({
    this.updatedAt,
    this.createdAt,
    this.id,
    this.body,
    required this.author,
    required this.imageUrls,
    this.videoUrl,
    this.scheduledAt,
    this.feedVisibility,
    this.commentPolicy,
    required this.engagement,
    this.quoteId,
    this.parentId,
    this.feedModeEnum = FeedModeEnum.view,
    this.imageFiles,
    this.videoFile,
  });

  int? get repostsAndQuotes {
    final reposts = engagement.reposts;
    final quotes = engagement.quotes;

    if (reposts == null && quotes == null) return null;
    return (reposts ?? 0) + (quotes ?? 0);
  }

  bool? get repostedOrQuoted {
    if (engagement.reposted == true || engagement.quoted == true) return true;
    if (engagement.reposted == null && engagement.quoted == null) return null;
    return null;
  }

  factory FeedModel.fromJson(Map<String, dynamic> json) {
    return FeedModel(
      id: json['id'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch((json['updated_at'] * 1000).round()),
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] * 1000).round()),
      body: json['body'],
      author: AuthorModel.fromJson(json['author']),
      videoUrl: json['video_url'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      scheduledAt: json['scheduled_at'],
      feedVisibility: FeedVisibility.values.byName(json['feed_visibility']),
      commentPolicy: CommentingPolicy.values.byName(json['comment_policy']),
      quoteId: json['quote_id'],
      parentId: json['parent_id'],
      engagement: EngagementModel.fromJson(json['engagement']),
    );
  }

  static String timeAgoShort({required DateTime dateTime}) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}m';
    return '${(diff.inDays / 365).floor()}y';
  }

  static const _sentinel = Object();

  FeedModel copyWith({
    Object? id = _sentinel,
    Object? updatedAt = _sentinel,
    Object? createdAt = _sentinel,
    Object? body = _sentinel,
    AuthorModel? author,
    Object? videoUrl = _sentinel,
    Object? imageUrls = _sentinel,
    Object? scheduledAt = _sentinel,
    Object? feedVisibility = _sentinel,
    Object? commentPolicy = _sentinel,
    Object? quoteId = _sentinel,
    Object? parentId = _sentinel,
    EngagementModel? engagement,
    Object? feedModeEnum = _sentinel,
    Object? imageFiles = _sentinel,
    Object? videoFile = _sentinel,
  }) {
    return FeedModel(
      id: id == _sentinel ? this.id : id as String?,
      updatedAt: updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
      createdAt: createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      body: body == _sentinel ? this.body : body as String?,
      author: author ?? this.author,
      imageUrls: imageUrls == _sentinel ? this.imageUrls : imageUrls as List<String>,
      videoUrl: videoUrl == _sentinel ? this.videoUrl : videoUrl as String?,
      scheduledAt: scheduledAt == _sentinel ? this.scheduledAt : scheduledAt as String?,
      feedVisibility: feedVisibility == _sentinel ? this.feedVisibility : feedVisibility as FeedVisibility,
      commentPolicy: commentPolicy == _sentinel ? this.commentPolicy : commentPolicy as CommentingPolicy,
      quoteId: quoteId == _sentinel ? this.quoteId : quoteId as String?,
      parentId: parentId == _sentinel ? this.parentId : parentId as String?,
      engagement: engagement ?? this.engagement,
      feedModeEnum: feedModeEnum == _sentinel ? this.feedModeEnum : feedModeEnum as FeedModeEnum,
      imageFiles: imageFiles == _sentinel ? this.imageFiles : imageFiles as List<File>,
      videoFile: videoFile == _sentinel ? this.videoFile : videoFile as File?,
    );
  }

  @override
  List<Object?> get props => [
    updatedAt,
    createdAt,
    id,
    author,
    body,
    imageUrls,
    videoUrl,
    scheduledAt,
    feedVisibility,
    commentPolicy,
    engagement,
    imageFiles,
    videoFile,
    feedModeEnum,
  ];
}

class FeedSearchResultModel {
  final String id;
  final String body;
  final String authorId;
  final String videoUrl;
  final String createdAt;
  final String updatedAt;
  final String feedVisibility;
  final String commentMode;

  const FeedSearchResultModel({
    required this.id,
    required this.body,
    required this.authorId,
    required this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.feedVisibility,
    required this.commentMode,
  });

  factory FeedSearchResultModel.fromJson(Map<String, dynamic> json) {
    return FeedSearchResultModel(
      id: json['id'],
      body: json['body'],
      authorId: json['author_id'],
      videoUrl: json['video_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      feedVisibility: json['feed_visibility'],
      commentMode: json['comment_mode'],
    );
  }

  FeedSearchResultModel copyWith({
    String? id,
    String? body,
    String? authorId,
    String? videoUrl,
    String? createdAt,
    String? updatedAt,
    String? feedVisibility,
    String? commentMode,
  }) {
    return FeedSearchResultModel(
      id: id ?? this.id,
      body: body ?? this.body,
      authorId: authorId ?? this.authorId,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      feedVisibility: feedVisibility ?? this.feedVisibility,
      commentMode: commentMode ?? this.commentMode,
    );
  }
}

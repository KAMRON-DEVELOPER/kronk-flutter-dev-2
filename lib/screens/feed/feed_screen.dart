import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/feed/feed_card.dart';

class FeedScreen extends ConsumerWidget {
  final FeedModel feed;

  const FeedScreen({super.key, required this.feed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final double margin2 = dimensions.margin2;
    final double margin3 = dimensions.margin3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
        ),
        actionsPadding: EdgeInsets.only(right: margin2),
      ),
      body: RefreshIndicator(
        color: theme.primaryText,
        backgroundColor: theme.secondaryBackground,
        onRefresh: () => ref.refresh(commentNotifierProvider(feed.id).notifier).refresh(parentId: feed.id),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// Main Feed
            SliverPadding(
              padding: EdgeInsets.all(isFloating ? margin3 : 0),
              sliver: SliverToBoxAdapter(child: FeedCard(initialFeed: feed, isRefreshing: false)),
            ),

            /// Comments Section
            CommentWidget(parentId: feed.id),
          ],
        ),
      ),
    );
  }
}

class CommentWidget extends ConsumerStatefulWidget {
  final String? parentId;

  const CommentWidget({super.key, required this.parentId});

  @override
  ConsumerState<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends ConsumerState<CommentWidget> {
  List<FeedModel> _previousFeeds = [];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<FeedModel>> feeds = ref.watch(commentNotifierProvider(widget.parentId));

    return feeds.when(
      error: (error, stackTrace) {
        if (error is DioException) return Center(child: Text('${error.message}'));
        return SliverToBoxAdapter(child: Center(child: Text('$error')));
      },
      loading: () => CommentListWidget(comments: _previousFeeds, isRefreshing: true),
      data: (List<FeedModel> comments) {
        _previousFeeds = comments;
        return CommentListWidget(comments: comments);
      },
    );
  }
}

class CommentListWidget extends ConsumerWidget {
  final List<FeedModel> comments;
  final bool isRefreshing;

  const CommentListWidget({super.key, required this.comments, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    myLogger.i('CommentListWidget is building...');

    if (comments.isEmpty && !isRefreshing) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No comments yet. 📨', style: Theme.of(context).textTheme.bodyLarge),
              Text('You can add the first!', style: Theme.of(context).textTheme.displaySmall),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(isFloating ? margin3 : 0),
      sliver: SliverList.separated(
        itemCount: comments.length,
        separatorBuilder: (context, index) => SizedBox(height: margin3),
        itemBuilder: (context, index) {
          return FeedCard(key: ValueKey(comments[index].id), initialFeed: comments[index], isRefreshing: isRefreshing);
        },
      ),
    );
  }
}

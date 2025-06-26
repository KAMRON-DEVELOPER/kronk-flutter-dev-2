import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/feed/feed_notification_widget.dart';
import 'package:kronk/widgets/navbar.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

/// FeedsScreen
class FeedsScreen extends ConsumerWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
    final bool isFloating = displayState.feedScreenDisplayStyle == FeedScreenStyle.floating;
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;

    final double screenWidth = dimensions.screenWidth;
    final double appBarHeight = 56 + 50.2; // Title + tab bar heights
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - appBarHeight - kBottomNavigationBarHeight;
    final double padding4 = dimensions.padding4;
    final double radius1 = dimensions.radius1;
    final double tabHeight1 = dimensions.tabHeight1;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            ref.read(tabIndexProvider.notifier).state = tabController.index;
          });
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Feeds'),
              leading: Builder(
                builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer()),
              ),

              actions: [IconButton(onPressed: () => showFeedScreenSettingsDialog(context, ref), icon: const Icon(Icons.display_settings_rounded))],
              bottom: PreferredSize(
                preferredSize: const Size(100, 50.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.outline, width: 1)),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: margin3),
                    decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius1)),
                    child: TabBar(
                      padding: EdgeInsets.all(padding4 / 1.5),
                      tabs: [
                        Tab(height: tabHeight1, text: 'discover'),
                        Tab(height: tabHeight1, text: 'following'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                /// Static background images
                if (isFloating)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        displayState.backgroundImagePath,
                        fit: BoxFit.cover,
                        cacheHeight: screenHeight.cacheSize(context),
                        cacheWidth: screenWidth.cacheSize(context),
                      ),
                    ),
                  ),

                const TabBarView(
                  children: [
                    TimelineTab(timelineType: TimelineType.discover),
                    TimelineTab(timelineType: TimelineType.following),
                  ],
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                try {
                  final currentIndex = ref.read(tabIndexProvider);
                  final currentTimeline = currentIndex == 0 ? TimelineType.discover : TimelineType.following;
                  ref.read(timelineNotifierProvider(currentTimeline).notifier).createFeed();
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: theme.tertiaryBackground,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                      content: Text('Failed to create feed: $error', style: Theme.of(context).textTheme.labelSmall),
                    ),
                  );
                }
              },
              child: const Icon(Icons.add_rounded),
            ),
            bottomNavigationBar: const Navbar(),
            drawer: const CustomDrawer(),
          );
        },
      ),
    );
  }
}

/// TimelineTab
class TimelineTab extends ConsumerStatefulWidget {
  final TimelineType timelineType;

  const TimelineTab({super.key, required this.timelineType});

  @override
  ConsumerState<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends ConsumerState<TimelineTab> with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  List<FeedModel> _previousFeeds = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        ref.read(scrollPositionProvider.notifier).state = _scrollController.position.pixels;
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
          ref.read(timelineNotifierProvider(widget.timelineType).notifier).loadMore(timelineType: widget.timelineType);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<List<FeedModel>> feeds = ref.watch(timelineNotifierProvider(widget.timelineType));

    final double radius1 = dimensions.radius1;
    ref.listen(feedNotificationStateProvider, (_, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (error is NoValidTokenException) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.tertiaryBackground,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                content: Text('You token is expired or not authenticated.', style: Theme.of(context).textTheme.labelSmall),
              ),
            );
          }
        },
      );
    });

    ref.listen(timelineNotifierProvider(widget.timelineType), (_, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          if (error is DioException) {
            myLogger.e('DioException error.error: ${error.error}');
            myLogger.e('DioException error.message: ${error.message}');
            myLogger.e('DioException error.type: ${error.type}');
            context.go('/auth');
          }
        },
      );
    });

    myLogger.i('TimelineTab is building...');
    return Stack(
      children: [
        /// Feeds
        RefreshIndicator(
          color: theme.primaryText,
          backgroundColor: theme.secondaryBackground,
          // onRefresh: () => ref.refresh(timelineNotifierProvider(widget.timelineType).future),
          onRefresh: () => ref.refresh(timelineNotifierProvider(widget.timelineType).notifier).refresh(timelineType: widget.timelineType),
          child: feeds.when(
            error: (error, stackTrace) {
              if (error is DioException) return Center(child: Text('${error.message}'));
              return Center(child: Text('$error'));
            },
            loading: () => FeedListWidget(feeds: _previousFeeds, controller: _scrollController, isRefreshing: true),
            data: (List<FeedModel> feeds) {
              _previousFeeds = feeds;
              return FeedListWidget(feeds: feeds, controller: _scrollController);
            },
          ),
        ),

        /// Notification bubble
        FeedNotificationWidget(scrollController: _scrollController, refreshKey: _refreshKey),
      ],
    );
  }
}

/// FeedListWidget
class FeedListWidget extends ConsumerWidget {
  final List<FeedModel> feeds;
  final ScrollController? controller;
  final bool isRefreshing;

  const FeedListWidget({super.key, required this.feeds, this.controller, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;
    final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
    final bool isFloating = displayState.feedScreenDisplayStyle == FeedScreenStyle.floating;

    myLogger.i('FeedListWidget is building...');

    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (feeds.isEmpty && !isRefreshing)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No feeds yet. 🦄', style: Theme.of(context).textTheme.bodyLarge),
                  Text('You can add the first!', style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
            ),
          ),

        if (feeds.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? margin3 : 0),
            sliver: SliverList.separated(
              itemCount: feeds.length,
              separatorBuilder: (context, index) => SizedBox(height: margin3),
              itemBuilder: (context, index) => FeedCard(key: ValueKey(feeds.elementAt(index).id), initialFeed: feeds.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

void showFeedScreenSettingsDialog(BuildContext context, WidgetRef ref) {
  const List<String> backgroundImages = [
    'feed_bg1.jpeg',
    'feed_bg2.jpeg',
    'feed_bg3.jpeg',
    'feed_bg4.jpeg',
    'feed_bg6.jpeg',
    'feed_bg7.jpeg',
    'feed_bg8.jpeg',
    'feed_bg9.jpeg',
    'feed_bg10.jpeg',
    'feed_bg11.jpeg',
    'feed_bg12.jpeg',
    'feed_bg13.jpeg',
    'feed_bg14.jpeg',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final Dimensions dimensions = Dimensions.of(context);
          final theme = ref.watch(themeNotifierProvider);
          final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
          final bool isFloating = displayState.feedScreenDisplayStyle == FeedScreenStyle.floating;

          final double feedImageSelectorWidth = dimensions.feedImageSelectorWidth;
          final double width = feedImageSelectorWidth;
          final double height = 16 / 9 * width;
          final double iconSize2 = dimensions.iconSize2;
          final double padding2 = dimensions.padding2;
          final double padding3 = dimensions.padding3;
          final double radius2 = dimensions.radius2;
          return Dialog(
            backgroundColor: theme.tertiaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(padding2)),
            child: Padding(
              padding: EdgeInsets.all(padding3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: padding2,
                children: [
                  /// Background image list
                  SizedBox(
                    height: height,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: backgroundImages.length,
                      itemBuilder: (context, index) {
                        final String imageName = 'assets/images/feed/${backgroundImages.elementAt(index)}';
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Images list
                            ClipRRect(
                              borderRadius: BorderRadius.circular(radius2),
                              child: GestureDetector(
                                onTap: () => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(backgroundImagePath: imageName),
                                child: Image.asset(imageName, height: height, width: width, cacheHeight: height.cacheSize(context), cacheWidth: width.cacheSize(context)),
                              ),
                            ),

                            /// Selected background image indicator
                            if (displayState.backgroundImagePath == imageName)
                              Positioned(
                                bottom: 8,
                                child: Icon(Icons.check_circle_rounded, color: theme.secondaryText, size: iconSize2),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: padding3),
                    ),
                  ),

                  /// Toggle button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(feedScreenStyle: FeedScreenStyle.edgeToEdge),
                          child: Container(
                            height: feedImageSelectorWidth,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(radius2),
                              border: Border.all(color: isFloating ? theme.secondaryBackground : theme.primaryText),
                            ),
                            child: Center(
                              child: Text('Edge-to-edge', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isFloating ? theme.secondaryText : theme.primaryText)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(feedScreenStyle: FeedScreenStyle.floating),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isFloating ? theme.primaryText : theme.secondaryBackground),
                            ),
                            child: Center(
                              child: Text('Floating', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isFloating ? theme.primaryText : theme.secondaryText)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Slider Rounded Corner
                  Slider(
                    value: displayState.cardBorderRadius,
                    min: 0,
                    max: 22,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    label: 'Card radius',
                    // divisions: 22,
                    onChanged: (double newRadius) => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(cardBorderRadius: newRadius),
                  ),

                  /// Slider opacity
                  Slider(
                    value: displayState.cardOpacity,
                    min: 0,
                    max: 1,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    label: 'Card opacity',
                    // divisions: 10,
                    onChanged: (double newOpacity) => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(cardOpacity: newOpacity),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return Drawer(
      backgroundColor: theme.secondaryBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              /// Profile
              Container(
                height: 70,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.account_circle_rounded, size: 36, color: theme.primaryText),
                    Text('Followers 0', style: Theme.of(context).textTheme.bodySmall),
                    Text('Followings 0', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

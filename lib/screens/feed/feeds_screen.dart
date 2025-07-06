import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/riverpod/feed/feed_notification_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/feed/feed_notification_widget.dart';
import 'package:kronk/widgets/navbar.dart';

final feedsScreenTabIndexProvider = StateProvider<int>((ref) => 0);

/// FeedsScreen
class FeedsScreen extends ConsumerWidget {
  const FeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
    final Dimensions dimensions = Dimensions.of(context);

    final double screenWidth = dimensions.screenWidth;
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - kBottomNavigationBarHeight;
    final double radius1 = dimensions.radius1;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            ref.read(feedsScreenTabIndexProvider.notifier).state = tabController.index;
          });
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: MainAppBar(titleText: 'Feeds', tabText1: 'discover', tabText2: 'following', onTap: () => showFeedScreenSettingsDialog(context)),
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
                  final currentIndex = ref.read(feedsScreenTabIndexProvider);
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
    _scrollController = ScrollController()..addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void scrollListener() {
    ref.read(scrollPositionProvider.notifier).state = _scrollController.position.pixels;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(timelineNotifierProvider(widget.timelineType).notifier).loadMore(timelineType: widget.timelineType);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<List<FeedModel>> feeds = ref.watch(timelineNotifierProvider(widget.timelineType));

    final double radius1 = dimensions.radius1;
    ref.listen(feedNotificationNotifierProvider, (_, next) {
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
          onRefresh: () => ref.read(timelineNotifierProvider(widget.timelineType).notifier).refresh(timelineType: widget.timelineType),
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
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    myLogger.i('FeedListWidget is building...');

    return Scrollbar(
      controller: controller,
      child: CustomScrollView(
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
      ),
    );
  }
}

void showFeedScreenSettingsDialog(BuildContext context) {
  const List<String> backgroundImages = [
    '0.jpg',
    '1.jpg',
    '2.jpg',
    '3.jpg',
    '4.jpg',
    '5.jpg',
    '6.jpeg',
    '7.jpeg',
    '8.jpeg',
    '9.jpeg',
    '10.jpeg',
    '11.jpeg',
    '12.jpeg',
    '13.jpeg',
    '14.jpeg',
    '15.jpeg',
    '16.jpeg',
    '17.jpeg',
    '18.jpeg',
    '19.jpg',
    '20.jpg',
    '21.jpg',
    '22.jpg',
    '23.jpg',
    '24.jpg',
    '25.jpg',
    '26.jpg',
    '27.jpg',
    '28.jpg',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final Dimensions dimensions = Dimensions.of(context);
          final theme = ref.watch(themeNotifierProvider);
          final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
          final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

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
                        final String imageName = 'assets/images/${backgroundImages.elementAt(index)}';
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Images list
                            ClipRRect(
                              borderRadius: BorderRadius.circular(radius2),
                              child: GestureDetector(
                                onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(backgroundImagePath: imageName),
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
                          onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.edgeToEdge),
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
                          onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.floating),
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
                    onChanged: (double newRadius) => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardBorderRadius: newRadius),
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
                    onChanged: (double newOpacity) => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardOpacity: newOpacity),
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

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titleText;
  final String tabText1;
  final String tabText2;
  final void Function()? onTap;

  const MainAppBar({super.key, required this.titleText, required this.tabText1, required this.tabText2, required this.onTap});

  @override
  Size get preferredSize => const Size.fromHeight(48 + 40 + 4 + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;
    final double radius3 = dimensions.radius3;
    final double iconSize2 = dimensions.iconSize2;
    final double textSize3 = dimensions.textSize3;
    final double tabHeight1 = dimensions.tabHeight1;
    final double appBarHeight = dimensions.appBarHeight;
    final double bottomHeight = dimensions.bottomHeight;
    final double spacing2 = dimensions.spacing2;
    return CustomAppBar(
      appBarHeight: appBarHeight,
      bottomHeight: bottomHeight,
      bottomGap: 4,
      actionsSpacing: spacing2,
      appBarPadding: EdgeInsets.only(left: margin3, right: margin3 - 6),
      bottomPadding: EdgeInsets.only(left: margin3, right: margin3, bottom: 4),
      leading: Builder(
        builder: (context) => GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Icon(Icons.menu_rounded, color: theme.primaryText, size: iconSize2),
        ),
      ),
      title: Text(
        titleText,
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: iconSize2, fontWeight: FontWeight.w600),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.go('/search'),
          child: Icon(Icons.search_rounded, color: theme.primaryText, size: iconSize2),
        ),
        GestureDetector(
          onTap: onTap,
          child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: iconSize2),
        ),
      ],
      bottom: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius3)),
        child: TabBar(
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(radius3 - 2)),
          labelStyle: GoogleFonts.quicksand(
            textStyle: TextStyle(fontSize: textSize3, color: theme.primaryText, fontWeight: FontWeight.w500),
          ),
          unselectedLabelStyle: GoogleFonts.quicksand(
            textStyle: TextStyle(fontSize: textSize3, color: theme.secondaryText, fontWeight: FontWeight.w500),
          ),
          indicatorAnimation: TabIndicatorAnimation.elastic,
          tabs: [
            Tab(height: tabHeight1, text: tabText1),
            Tab(height: tabHeight1, text: tabText2),
          ],
        ),
      ),
    );
  }
}

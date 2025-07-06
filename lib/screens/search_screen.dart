import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/general/search_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/navbar.dart';

final searchScreenTabIndexProvider = StateProvider<int>((ref) => 0);

/// SearchScreen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref.read(searchScreenTabIndexProvider.notifier).state = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);

    final double margin3 = dimensions.margin3;
    final double radius3 = dimensions.radius3;
    final double textSize3 = dimensions.textSize3;
    final double iconSize2 = dimensions.iconSize2;
    final double tabHeight1 = dimensions.tabHeight1;
    final double appBarHeight = dimensions.appBarHeight;
    final double bottomHeight = dimensions.bottomHeight;
    final double spacing2 = dimensions.spacing2;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
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
        actions: [
          GestureDetector(
            onTap: () => showSearchScreenSettingsDialog(context),
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: iconSize2),
          ),
        ],
        title: Text(
          'Search',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: iconSize2, fontWeight: FontWeight.w600),
        ),
        bottom: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius3)),
          child: TabBar(
            controller: _tabController,
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
              Tab(height: tabHeight1, text: 'feed'),
              Tab(height: tabHeight1, text: 'user'),
            ],
          ),
        ),
      ),
      body: TabBarView(controller: _tabController, children: [const FeedSearchWidget(), const UserSearchWidget()]),
      bottomNavigationBar: const Navbar(),
    );
  }
}

/// FeedSearchWidget
class FeedSearchWidget extends ConsumerStatefulWidget {
  const FeedSearchWidget({super.key});

  @override
  ConsumerState<FeedSearchWidget> createState() => _FeedSearchWidgetState();
}

class _FeedSearchWidgetState extends ConsumerState<FeedSearchWidget> {
  late ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(feedSearchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<List<FeedModel>> asyncFeeds = ref.watch(feedSearchNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final screenWidth = dimensions.screenWidth;
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - 88 - kBottomNavigationBarHeight;
    final double margin3 = dimensions.margin3;
    final BorderRadius borderRadius = BorderRadius.circular(isFloating ? displayState.cardBorderRadius : 0);
    final double iconSize3 = dimensions.iconSize2;
    final double textSize3 = dimensions.textSize3;
    final BorderSide borderSide = BorderSide(color: theme.secondaryBackground, width: 0.5);
    myLogger.d('FeedSearchWidget is building');
    return Stack(
      children: [
        /// Static background images
        if (isFloating)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(displayState.backgroundImagePath, fit: BoxFit.cover, cacheHeight: screenHeight.cacheSize(context), cacheWidth: screenWidth.cacheSize(context)),
            ),
          ),

        /// Content
        CustomScrollView(
          slivers: [
            /// Search field
            SliverToBoxAdapter(
              child: Container(
                height: 40,
                margin: EdgeInsets.only(left: margin3, top: margin3, right: margin3),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: textSize3, fontWeight: FontWeight.w500),
                  cursorColor: theme.primaryText,
                  cursorWidth: 1,
                  cursorRadius: const Radius.circular(0.5),
                  cursorHeight: 20,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.primaryBackground.withValues(alpha: displayState.cardOpacity),
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    hint: Text(
                      'Search',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.secondaryText, fontWeight: FontWeight.w700),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: (40 - 20) / 2, horizontal: 20),
                    prefixIcon: Icon(Icons.search_rounded, size: iconSize3, color: theme.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty == true
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.invalidate(feedSearchNotifierProvider);
                            },
                            icon: Icon(Icons.clear_rounded, size: iconSize3, color: theme.secondaryText),
                          )
                        : null,
                  ),
                  onChanged: (String searchQuery) => ref.read(feedSearchNotifierProvider.notifier).fetchSearchQueryResult(searchQuery: searchQuery),
                ),
              ),
            ),

            /// Feeds list
            asyncFeeds.when(
              data: (List<FeedModel> feeds) {
                myLogger.d('feeds.isEmpty: ${feeds.isEmpty}');
                if (feeds.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('No results found. 🔍', style: Theme.of(context).textTheme.bodyLarge)),
                  );
                }

                if (feeds.isNotEmpty) {
                  return SliverFillRemaining(
                    child: ListView.separated(
                      padding: EdgeInsets.all(margin3),
                      itemCount: feeds.length,
                      separatorBuilder: (context, index) => SizedBox(height: margin3),
                      itemBuilder: (context, index) => FeedCard(initialFeed: feeds.elementAt(index), isRefreshing: false),
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox.shrink());
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ],
    );
  }
}

/// UserSearchWidget
class UserSearchWidget extends ConsumerStatefulWidget {
  const UserSearchWidget({super.key});

  @override
  ConsumerState<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends ConsumerState<UserSearchWidget> {
  late ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent) {
      ref.read(userSearchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final asyncUsers = ref.watch(userSearchNotifierProvider);
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final screenWidth = dimensions.screenWidth;
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - 88 - kBottomNavigationBarHeight;
    final double margin3 = dimensions.margin3;
    final BorderRadius borderRadius = BorderRadius.circular(isFloating ? displayState.tileBorderRadius : 0);
    final double iconSize3 = dimensions.iconSize2;
    final double textSize3 = dimensions.textSize3;
    final BorderSide borderSide = BorderSide(color: theme.secondaryBackground, width: 0.5);
    myLogger.d('UserSearchWidget is building');
    return Stack(
      children: [
        /// Static background images
        if (isFloating)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(displayState.backgroundImagePath, fit: BoxFit.cover, cacheHeight: screenHeight.cacheSize(context), cacheWidth: screenWidth.cacheSize(context)),
            ),
          ),

        /// Content
        CustomScrollView(
          slivers: [
            /// Search field
            SliverToBoxAdapter(
              child: Container(
                height: 40,
                margin: EdgeInsets.only(left: margin3, top: margin3, right: margin3),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: textSize3, fontWeight: FontWeight.w500),
                  cursorColor: theme.primaryText,
                  cursorWidth: 1,
                  cursorRadius: const Radius.circular(0.5),
                  cursorHeight: 20,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.primaryBackground.withValues(alpha: displayState.tileOpacity),
                    border: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: borderSide),
                    hint: Text(
                      'Search',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.secondaryText, fontWeight: FontWeight.w700),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: (40 - 20) / 2, horizontal: 20),
                    prefixIcon: Icon(Icons.search_rounded, size: iconSize3, color: theme.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty == true
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.invalidate(userSearchNotifierProvider);
                            },
                            icon: Icon(Icons.clear_rounded, size: iconSize3, color: theme.secondaryText),
                          )
                        : null,
                  ),
                  onChanged: (String searchQuery) => ref.read(userSearchNotifierProvider.notifier).fetchSearchQueryResult(searchQuery: searchQuery),
                ),
              ),
            ),

            /// Profile lists
            asyncUsers.when(
              data: (List<UserModel> userSearchResultList) {
                if (userSearchResultList.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('No results found. 🔍', style: Theme.of(context).textTheme.bodyLarge)),
                  );
                }

                if (userSearchResultList.isNotEmpty) {
                  return SliverFillRemaining(
                    child: ListView.separated(
                      padding: EdgeInsets.all(margin3),
                      itemCount: userSearchResultList.length,
                      separatorBuilder: (context, index) => SizedBox(height: margin3),
                      itemBuilder: (context, index) {
                        final user = userSearchResultList.elementAt(index);
                        return ProfileSearchCard(user: user);
                      },
                    ),
                  );
                }
                return const SliverFillRemaining(child: SizedBox.shrink());
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                myLogger.e('Error: $e, StackTrace: $st');
                return SliverFillRemaining(child: Center(child: Text('Error: $e, StackTrace: $st')));
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// ProfileSearchCard
class ProfileSearchCard extends ConsumerWidget {
  final UserModel user;

  const ProfileSearchCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);

    final double margin3 = dimensions.margin3;
    final devicePixelRatio = View.of(context).devicePixelRatio;
    return Card(
      color: theme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(margin3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: user.avatarUrl != null
                  ? Image.network('${constants.bucketEndpoint}/${user.avatarUrl}', width: 60, height: 60, fit: BoxFit.cover, cacheWidth: (60 * devicePixelRatio).round())
                  : Icon(Icons.account_circle_rounded, size: 60, color: theme.primaryText),
            ),
            SizedBox(width: margin3),

            // Info + Buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.primaryText),
                  ),
                  Text('@${user.username}', style: TextStyle(fontSize: 12, color: theme.secondaryText)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${user.followingsCount} following', style: TextStyle(fontSize: 10, color: theme.primaryText)),
                      const SizedBox(width: 8),
                      Text('${user.followersCount} followers', style: TextStyle(fontSize: 10, color: theme.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (user.isFollowing != null)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => ref.read(userSearchNotifierProvider.notifier).toggleFollow(userId: user.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isFollowing! ? theme.secondaryText : theme.secondaryBackground,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            user.isFollowing! ? 'Following' : 'Follow',
                            style: TextStyle(fontSize: 12, color: user.isFollowing! ? theme.primaryText : theme.secondaryText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            context.push('/chats/chat', extra: user);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.outline),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text('Chat', style: TextStyle(fontSize: 12, color: theme.primaryText)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showSearchScreenSettingsDialog(BuildContext context) {
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
          final tabIndex = ref.watch(searchScreenTabIndexProvider);
          final FeedScreenDisplayState feedsScreenDisplayState = ref.watch(feedsScreenStyleProvider);
          final ChatsScreenDisplayState chatsScreenDisplayState = ref.watch(chatsScreenStyleProvider);
          final bool isFloating = (tabIndex == 0 ? feedsScreenDisplayState.screenStyle : chatsScreenDisplayState.screenStyle) == ScreenStyle.floating;

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
                                onTap: () {
                                  switch (tabIndex) {
                                    case 0:
                                      ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(backgroundImagePath: imageName);
                                    case 1:
                                      ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(backgroundImagePath: imageName);
                                  }
                                },
                                child: Image.asset(imageName, height: height, width: width, cacheHeight: height.cacheSize(context), cacheWidth: width.cacheSize(context)),
                              ),
                            ),

                            /// Selected background image indicator
                            if ((tabIndex == 0 ? feedsScreenDisplayState.backgroundImagePath : chatsScreenDisplayState.backgroundImagePath) == imageName)
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
                          onTap: () {
                            switch (tabIndex) {
                              case 0:
                                ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.floating);
                              case 1:
                                ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(screenStyle: ScreenStyle.floating);
                            }
                          },
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
                    value: tabIndex == 0 ? feedsScreenDisplayState.cardBorderRadius : chatsScreenDisplayState.tileBorderRadius,
                    min: 0,
                    max: 22,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    label: 'Card radius',
                    // divisions: 22,
                    onChanged: (double newRadius) {
                      switch (tabIndex) {
                        case 0:
                          ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardBorderRadius: newRadius);
                        case 1:
                          ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(tileBorderRadius: newRadius);
                      }
                    },
                  ),

                  /// Slider opacity
                  Slider(
                    value: tabIndex == 0 ? feedsScreenDisplayState.cardOpacity : chatsScreenDisplayState.tileOpacity,
                    min: 0,
                    max: 1,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    label: 'Card and Tile opacity',
                    // divisions: 10,
                    onChanged: (double newOpacity) {
                      switch (tabIndex) {
                        case 0:
                          ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(cardOpacity: newOpacity);
                        case 1:
                          ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(tileOpacity: newOpacity);
                      }
                    },
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

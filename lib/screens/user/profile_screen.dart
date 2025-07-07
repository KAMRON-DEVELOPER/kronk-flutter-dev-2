import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/riverpod/profile/engagement_feeds.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/navbar.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';
import 'package:tuple/tuple.dart';

/// ProfileScreen
class ProfileScreen extends ConsumerWidget {
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    myLogger.d('building profile screen...');
    return DefaultTabController(
      length: EngagementType.values.length,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            /// static image
            if (isFloating)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    displayState.backgroundImagePath,
                    fit: BoxFit.cover,
                    cacheWidth: Sizes.screenWidth.cacheSize(context),
                    cacheHeight: Sizes.screenHeight.cacheSize(context),
                  ),
                ),
              ),

            /// Content
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [SliverToBoxAdapter(child: ProfileHeaderWidget(targetUserId: targetUserId))],
              body: TabBarView(
                children: EngagementType.values.map((type) => EngagementTab(targetUserId: targetUserId, engagementType: type)).toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const Navbar(),
      ),
    );
  }
}

/// ProfileHeaderWidget
class ProfileHeaderWidget extends ConsumerStatefulWidget {
  final String? targetUserId;

  const ProfileHeaderWidget({super.key, this.targetUserId});

  @override
  ConsumerState<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends ConsumerState<ProfileHeaderWidget> {
  late UserModel? cachedUser;
  late Storage storage;

  @override
  void initState() {
    super.initState();
    storage = Storage();
    cachedUser = storage.getUser();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserModel> asyncUser = ref.watch(profileNotifierProvider(widget.targetUserId));
    return asyncUser.when(
      data: (UserModel user) => ProfileCard(user: user),
      loading: () => cachedUser != null ? ProfileCard(user: cachedUser!) : const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}

/// ProfileCard
class ProfileCard extends ConsumerWidget {
  final UserModel user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final bool isFollowing = user.isFollowing ?? false;
    final bool isFollowingNull = user.isFollowing == null;

    final double bannerHeight = 170.dp;
    final double avatarHeight = 96.dp;
    final double avatarRadius = avatarHeight / 2;
    return Container(
      color: theme.primaryBackground,
      child: Stack(
        children: [
          Column(
            children: [
              /// Banner
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Image.network(
                  '${constants.bucketEndpoint}/${user.bannerUrl}',
                  width: double.infinity,
                  height: bannerHeight,
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                  cacheHeight: bannerHeight.cacheSize(context),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: double.infinity, height: bannerHeight, color: theme.secondaryBackground),
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null ? child : Container(width: double.infinity, height: bannerHeight, color: theme.secondaryBackground),
                ),
              ),

              /// Message, edit profile, follow, following
              Container(
                height: avatarRadius,
                margin: EdgeInsets.symmetric(horizontal: 12.dp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12.dp,
                  children: [
                    /// Message
                    if (!isFollowingNull)
                      GestureDetector(
                        onTap: () => context.go('/chats/chat', extra: user),
                        child: Container(
                          width: 100.dp,
                          height: 36.dp,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(16.dp)),
                          child: Icon(KronkIcon.messageCircleLeftOutline, size: 24.dp, color: theme.primaryText),
                        ),
                      ),

                    /// Edit profile, Follow, Following
                    GestureDetector(
                      onTap: () {
                        if (isFollowingNull) {
                          context.go('/profile/edit');
                        } else {
                          ref.read(profileNotifierProvider(user.id).notifier).toggleFollow(userId: user.id);
                        }
                      },
                      child: Container(
                        height: 32.dp,
                        padding: EdgeInsets.symmetric(horizontal: 12.dp),
                        decoration: BoxDecoration(
                          color: !isFollowingNull && !isFollowing ? theme.primaryText : theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(16.dp),
                        ),
                        child: Row(
                          spacing: 4.dp,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isFollowingNull && !isFollowing) Icon(Icons.add_rounded, size: 24.dp, color: theme.primaryBackground),
                            Text(
                              isFollowingNull ? 'Edit Profile' : (isFollowing ? 'Following' : 'Follow'),
                              style: GoogleFonts.quicksand(
                                color: isFollowing || isFollowingNull ? theme.primaryText : theme.primaryBackground,
                                fontSize: 16.dp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isFollowingNull && !isFollowing) SizedBox(width: 2.dp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Name, username
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 12.dp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 28.dp, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.dp),

              /// Bio
              if (user.bio != null) ProfileBioWidget(bio: user.bio!),

              if (user.bio != null) SizedBox(height: 12.dp),

              /// Followers & followings count
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 12.dp),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12.dp,
                  children: [
                    Row(
                      spacing: 4.dp,
                      children: [
                        Text(
                          '${user.followersCount}',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp),
                        ),
                        Text(
                          'followers',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4.dp,
                      children: [
                        Text(
                          '${user.followingsCount}',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp),
                        ),
                        Text(
                          'followings',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4.dp,
                      children: [
                        Text(
                          '0',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp),
                        ),
                        Text(
                          'feeds',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// TabBar
              TabBar(
                isScrollable: true,
                dividerHeight: 1.dp,
                dividerColor: theme.outline,
                tabAlignment: TabAlignment.start,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: theme.primaryText, width: 2.dp),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(1.dp), topRight: Radius.circular(1.dp)),
                ),
                labelStyle: GoogleFonts.quicksand(
                  textStyle: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                ),
                unselectedLabelStyle: GoogleFonts.quicksand(
                  textStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16.dp, fontWeight: FontWeight.w500),
                ),
                indicatorAnimation: TabIndicatorAnimation.elastic,
                tabs: EngagementType.values.map((e) => Tab(text: e.name)).toList(),
              ),
            ],
          ),

          /// Avatar
          Positioned(
            top: bannerHeight - avatarRadius,
            left: 16.dp,
            height: avatarHeight,
            child: CustomPaint(
              painter: AvatarPainter(borderColor: theme.primaryBackground, borderWidth: 8.dp),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(avatarRadius),
                child: Image.network(
                  '${constants.bucketEndpoint}/${user.avatarUrl}',
                  width: avatarHeight,
                  height: avatarHeight,
                  cacheWidth: avatarHeight.cacheSize(context),
                  cacheHeight: avatarHeight.cacheSize(context),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: avatarHeight,
                    decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                  ),
                  loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                      ? child
                      : Container(
                          width: avatarHeight,
                          decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EngagementTab
class EngagementTab extends ConsumerStatefulWidget {
  final String? targetUserId;
  final EngagementType engagementType;

  const EngagementTab({super.key, this.targetUserId, required this.engagementType});

  @override
  ConsumerState<EngagementTab> createState() => _EngagementTabState();
}

class _EngagementTabState extends ConsumerState<EngagementTab> with AutomaticKeepAliveClientMixin {
  List<FeedModel> _previousFeeds = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AsyncValue<List<FeedModel>> asyncFeeds = ref.watch(engagementFeedNotifierProvider(Tuple2(widget.targetUserId, widget.engagementType)));
    return asyncFeeds.when(
      error: (error, stackTrace) {
        if (error is DioException) return Center(child: Text('${error.message}'));
        return Center(child: Text('$error'));
      },
      loading: () => EngagementFeedList(feeds: _previousFeeds, targetUserId: widget.targetUserId, engagementType: widget.engagementType, isRefreshing: true),
      data: (List<FeedModel> feeds) {
        _previousFeeds = feeds;
        return EngagementFeedList(feeds: feeds, targetUserId: widget.targetUserId, engagementType: widget.engagementType);
      },
    );
  }
}

/// EngagementFeedList
class EngagementFeedList extends ConsumerWidget {
  final List<FeedModel> feeds;
  final String? targetUserId;
  final EngagementType engagementType;
  final bool isRefreshing;

  const EngagementFeedList({super.key, required this.feeds, this.targetUserId, required this.engagementType, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final double margin3 = dimensions.margin3;
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.read(engagementFeedNotifierProvider(Tuple2(targetUserId, engagementType)).notifier).refresh(key: Tuple2(targetUserId, engagementType)),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          final bool shouldLoadMore = notification.metrics.pixels >= notification.metrics.maxScrollExtent - 50;
          if (shouldLoadMore) {
            ref.read(engagementFeedNotifierProvider(Tuple2(targetUserId, engagementType)).notifier).loadMore(key: Tuple2(targetUserId, engagementType));
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.all(isFloating ? margin3 : 0),
          itemCount: feeds.length,
          separatorBuilder: (context, index) => SizedBox(height: margin3),
          itemBuilder: (context, index) => FeedCard(key: ValueKey(feeds.elementAt(index).id), initialFeed: feeds.elementAt(index), isRefreshing: isRefreshing),
        ),
      ),
    );
  }
}

class ProfileBioWidget extends ConsumerStatefulWidget {
  final String bio;

  const ProfileBioWidget({super.key, required this.bio});

  @override
  ConsumerState<ProfileBioWidget> createState() => _ProfileBioWidgetState();
}

class _ProfileBioWidgetState extends ConsumerState<ProfileBioWidget> {
  bool isBioExpanded = false;
  bool isOverflowing = false;

  final int maxBioLines = 3;

  @override
  Widget build(BuildContext context) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final double textSize4 = dimensions.textSize4;
    final double margin3 = dimensions.margin3;

    final textStyle = GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.bio, style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr, maxLines: maxBioLines)..layout(maxWidth: constraints.maxWidth);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && tp.didExceedMaxLines != isOverflowing) {
            setState(() => isOverflowing = tp.didExceedMaxLines);
          }
        });

        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: margin3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.bio, style: textStyle, maxLines: isBioExpanded ? null : maxBioLines, overflow: isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis),
              if (isOverflowing)
                GestureDetector(
                  onTap: () => setState(() => isBioExpanded = !isBioExpanded),
                  child: Text(
                    isBioExpanded ? 'Show less' : 'Show more',
                    style: GoogleFonts.quicksand(fontSize: textSize4, color: theme.secondaryText, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

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
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/profile/engagement_feeds.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
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
    final Dimensions dimensions = Dimensions.of(context);
    final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final double screenWidth = dimensions.screenWidth;
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - kBottomNavigationBarHeight;
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
                  child: Image.asset(displayState.backgroundImagePath, fit: BoxFit.cover, cacheHeight: screenHeight.cacheSize(context), cacheWidth: screenWidth.cacheSize(context)),
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
class ProfileHeaderWidget extends ConsumerWidget {
  final String? targetUserId;

  const ProfileHeaderWidget({super.key, this.targetUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserModel> asyncUser = ref.watch(profileNotifierProvider(targetUserId));
    return asyncUser.when(
      data: (UserModel user) => ProfileCard(user: user),
      loading: () => const CircularProgressIndicator(),
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
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final bool isFollowing = user.isFollowing ?? false;
    final bool isFollowingNull = user.isFollowing == null;

    final double screenWidth = dimensions.screenWidth;
    final double margin3 = dimensions.margin3;
    final double textSize3 = dimensions.textSize3;
    final double textSize4 = dimensions.textSize4;
    final double iconSize4 = dimensions.iconSize4;
    final double iconSize6 = dimensions.iconSize6;
    final double buttonHeight5 = dimensions.buttonHeight5;
    final double bannerHeight = dimensions.bannerHeight;
    final double avatarHeight = dimensions.avatarHeight;
    final double avatarRadius = dimensions.avatarRadius;
    final double padding1 = dimensions.padding1;
    final double padding2 = dimensions.padding2;
    final double padding3 = dimensions.padding3;
    myLogger.i('ProfileCard | user.avatarUrl: ${user.avatarUrl}, user.bannerUrl: ${user.bannerUrl}');
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
                  cacheWidth: screenWidth.cacheSize(context),
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
                margin: EdgeInsets.symmetric(horizontal: margin3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: padding3,
                  children: [
                    /// Message
                    if (!isFollowingNull)
                      GestureDetector(
                        onTap: () => context.go('/chats/chat', extra: user),
                        child: Container(
                          width: buttonHeight5,
                          height: buttonHeight5,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(buttonHeight5 / 2)),
                          child: Icon(KronkIcon.messageCircleLeftOutline, size: iconSize6, color: theme.primaryText),
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
                        height: buttonHeight5,
                        decoration: BoxDecoration(
                          color: !isFollowingNull && !isFollowing ? theme.primaryText : theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(buttonHeight5 / 2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: padding2),
                        child: Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isFollowingNull && !isFollowing) Icon(Icons.add_rounded, size: iconSize4, color: theme.primaryBackground),
                            Text(
                              isFollowingNull ? 'Edit Profile' : (isFollowing ? 'Following' : 'Follow'),
                              style: GoogleFonts.quicksand(
                                color: isFollowing || isFollowingNull ? theme.primaryText : theme.primaryBackground,
                                fontSize: textSize4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isFollowingNull && !isFollowing) const SizedBox(width: 2),
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
                margin: EdgeInsets.symmetric(horizontal: margin3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize3, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: textSize4, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              SizedBox(height: padding3),

              /// Bio
              if (user.bio != null) ProfileBioWidget(bio: user.bio!),

              if (user.bio != null) SizedBox(height: padding3),

              /// Followers & followings count
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: margin3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: padding1,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          '${user.followersCount}',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize4),
                        ),
                        Text(
                          'followers',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: textSize4, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          '${user.followingsCount}',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize4),
                        ),
                        Text(
                          'followings',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: textSize4, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text(
                          '14',
                          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize4),
                        ),
                        Text(
                          'feeds',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: textSize4, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// TabBar
              TabBar(
                isScrollable: true,
                dividerHeight: 1,
                dividerColor: theme.outline,
                tabAlignment: TabAlignment.start,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: theme.primaryText, width: 2),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(1), topRight: Radius.circular(1)),
                ),
                labelStyle: GoogleFonts.quicksand(
                  textStyle: TextStyle(fontSize: textSize3, color: theme.primaryText, fontWeight: FontWeight.w500),
                ),
                unselectedLabelStyle: GoogleFonts.quicksand(
                  textStyle: TextStyle(fontSize: textSize3, color: theme.secondaryText, fontWeight: FontWeight.w500),
                ),
                indicatorAnimation: TabIndicatorAnimation.elastic,
                tabs: EngagementType.values.map((e) => Tab(text: e.name)).toList(),
              ),
            ],
          ),

          /// Avatar
          Positioned(
            top: bannerHeight - avatarRadius,
            left: margin3 + 4,
            height: avatarHeight,
            child: CustomPaint(
              painter: AvatarPainter(borderColor: theme.primaryBackground, borderWidth: 8),
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

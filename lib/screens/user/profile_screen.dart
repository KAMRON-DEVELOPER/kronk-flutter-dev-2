import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/profile/engagement_feeds.dart';
import 'package:kronk/riverpod/profile/user_provider.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/navbar.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    myLogger.d('building profile screen...');
    return Scaffold(
      body: DefaultTabController(
        length: EngagementType.values.length,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [const ProfileWidget(), const SliverToBoxAdapter(child: EngagementTabs())],
          body: TabBarView(children: EngagementType.values.map((EngagementType engagementType) => EngagementTab(engagementType: engagementType)).toList()),
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}

/// ProfileWidget
class ProfileWidget extends ConsumerWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserModel> asyncUser = ref.watch(profileNotifierProvider);
    return asyncUser.when(
      data: (UserModel user) => ProfileCard(user: user),
      loading: () => const SliverToBoxAdapter(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => SliverToBoxAdapter(
        child: Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent)),
        ),
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
    final bannerHeight = 180.0;

    final double screenWidth = dimensions.screenWidth;
    final double margin3 = dimensions.margin3;
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Column(
            children: [
              /// Banner 180
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Image.network(
                  '${constants.bucketEndpoint}/defaults/default-banner-island-night.jpg',
                  width: double.infinity,
                  height: bannerHeight,
                  cacheWidth: screenWidth.cacheSize(context),
                  cacheHeight: bannerHeight.cacheSize(context),
                  fit: BoxFit.cover,
                ),
              ),

              /// Message, edit profile, follow, following 52
              Container(
                height: 52,
                margin: EdgeInsets.symmetric(horizontal: margin3),
                decoration: BoxDecoration(color: theme.primaryBackground, border: Border.all()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    /// Message 36
                    if (!isFollowingNull)
                      GestureDetector(
                        onTap: () {
                          myLogger.d('Edit profile');
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(18)),
                          child: Icon(KronkIcon.messageCircleLeftOutline, size: 22, color: theme.primaryText),
                        ),
                      ),

                    /// Edit profile, Follow, Following 36
                    GestureDetector(
                      onTap: () {
                        myLogger.d('Edit profile');
                      },
                      child: Container(
                        width: 100,
                        height: 36,
                        decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isFollowingNull && !isFollowing) Icon(Icons.add_rounded, size: 18, color: theme.primaryBackground),
                            Text(
                              isFollowingNull ? 'Edit Profile' : (isFollowing ? 'Following' : 'Follow'),
                              style: GoogleFonts.quicksand(color: isFollowing ? theme.primaryText : theme.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Name, username 59
              Container(
                width: double.infinity,
                height: 59,
                margin: EdgeInsets.symmetric(horizontal: margin3),
                decoration: BoxDecoration(color: theme.primaryBackground, border: Border.all()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name}',
                      style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user.username}',
                      style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              /// Followers & followings count 39
              Container(
                width: double.infinity,
                height: 39,
                margin: EdgeInsets.symmetric(horizontal: margin3),
                decoration: BoxDecoration(color: theme.primaryBackground, border: Border.all()),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Text('${user.followersCount}', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18)),
                        Text(
                          'followers',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text('${user.followingsCount}', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18)),
                        Text(
                          'followings',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 4,
                      children: [
                        Text('14', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18)),
                        Text(
                          'feeds',
                          style: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// Avatar
          Positioned(
            top: 132,
            left: margin3 + 4,
            height: 96,
            child: CustomPaint(
              painter: AvatarPainter(borderColor: theme.primaryBackground, borderWidth: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(48),
                child: Image.network(
                  '${constants.bucketEndpoint}/${user.avatarUrl ?? 'defaults/default-avatar.jpg'}',
                  width: 96,
                  height: 96,
                  cacheWidth: (96 * 2.75).toInt(),
                  cacheHeight: (96 * 2.75).toInt(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EngagementWidget
class EngagementTabs extends ConsumerWidget {
  const EngagementTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);

    final double margin3 = dimensions.margin3;
    final double textSize3 = dimensions.textSize3;
    final double radius3 = dimensions.radius3;
    final double tabHeight1 = dimensions.tabHeight1;
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: margin3),
      decoration: BoxDecoration(border: Border.all()),
      child: TabBar(
        isScrollable: true,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius3 - 2)),
        labelStyle: GoogleFonts.quicksand(
          textStyle: TextStyle(fontSize: textSize3, color: theme.primaryText, fontWeight: FontWeight.w500),
        ),
        unselectedLabelStyle: GoogleFonts.quicksand(
          textStyle: TextStyle(fontSize: textSize3, color: theme.secondaryText, fontWeight: FontWeight.w500),
        ),
        indicatorAnimation: TabIndicatorAnimation.elastic,
        tabs: EngagementType.values.map((e) => Tab(text: e.name, height: tabHeight1)).toList(),
      ),
    );
  }
}

/// EngagementTabView
class EngagementTab extends ConsumerStatefulWidget {
  final EngagementType engagementType;

  const EngagementTab({super.key, required this.engagementType});

  @override
  ConsumerState<EngagementTab> createState() => _EngagementTabState();
}

class _EngagementTabState extends ConsumerState<EngagementTab> {
  List<FeedModel> _previousFeeds = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    final AsyncValue<List<FeedModel>> asyncFeeds = ref.watch(engagementFeedNotifierProvider(widget.engagementType));
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.read(engagementFeedNotifierProvider(widget.engagementType).notifier).refresh(engagementType: widget.engagementType),
      child: asyncFeeds.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => FeedListWidget(feeds: _previousFeeds, isRefreshing: true),
        data: (List<FeedModel> feeds) {
          _previousFeeds = feeds;
          return FeedListWidget(feeds: feeds);
        },
      ),
    );
  }
}

// class EngagementFeedList extends ConsumerWidget {
//   final List<FeedModel> feeds;
//   final bool isRefreshing;
//
//   const EngagementFeedList({super.key, required this.feeds, this.isRefreshing = false});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final Dimensions dimensions = Dimensions.of(context);
//     final FeedScreenDisplayState displayState = ref.watch(feedsScreenStyleProvider);
//     final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
//
//     final double margin3 = dimensions.margin3;
//     return Scrollbar(
//       child: CustomScrollView(
//         slivers: [
//           if (feeds.isEmpty && !isRefreshing)
//             SliverFillRemaining(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('No feeds yet. 🦄', style: Theme.of(context).textTheme.bodyLarge),
//                     Text('You can add the first!', style: Theme.of(context).textTheme.displaySmall),
//                   ],
//                 ),
//               ),
//             ),
//
//           if (feeds.isNotEmpty)
//             SliverPadding(
//               padding: EdgeInsets.all(isFloating ? margin3 : 0),
//               sliver: SliverList.separated(
//                 itemCount: feeds.length,
//                 separatorBuilder: (context, index) => SizedBox(height: margin3),
//                 itemBuilder: (context, index) => FeedCard(key: ValueKey(feeds.elementAt(index).id), initialFeed: feeds.elementAt(index), isRefreshing: isRefreshing),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

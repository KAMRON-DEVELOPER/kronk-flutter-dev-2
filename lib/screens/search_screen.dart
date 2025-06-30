import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/search_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/feed/feed_card.dart';
import 'package:kronk/widgets/navbar.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin<SearchScreen> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);
    final tabIndex = ref.watch(tabIndexProvider);

    final double margin3 = dimensions.margin3;
    final double radius1 = dimensions.radius1;
    final double iconSize3 = dimensions.iconSize2;
    final double textSize3 = dimensions.textSize3;
    final double tabHeight1 = dimensions.tabHeight1;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: margin3,
          automaticallyImplyLeading: false,
          title: const Text('Search'),
          bottom: PreferredSize(
            preferredSize: const Size(100, 50.2),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.outline, width: 1)),
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: margin3),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius1)),
                child: TabBar(
                  onTap: (int tabIndex) {
                    ref.read(tabIndexProvider.notifier).state = tabIndex;
                    ref.read(searchQueryStateProvider.notifier).state = '';
                    searchController.text = '';
                  },
                  tabs: [
                    Tab(height: tabHeight1, text: 'posts'),
                    Tab(height: tabHeight1, text: 'users'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            /// Search field
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  margin: EdgeInsets.only(top: margin3),
                  padding: EdgeInsets.symmetric(horizontal: margin3),
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(fontSize: textSize3, fontWeight: FontWeight.w500),
                    cursorColor: theme.primaryText,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.secondaryBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius1), borderSide: BorderSide.none),
                      hint: Text(
                        'Search',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: theme.secondaryText, fontWeight: FontWeight.w700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: (40 - 20) / 2, horizontal: 20),
                      prefixIcon: Icon(Icons.search_rounded, size: iconSize3, color: theme.secondaryText),
                      suffixIcon: searchController.text.isNotEmpty == true
                          ? IconButton(
                              onPressed: () => searchController.text = '',
                              icon: Icon(Icons.clear_rounded, size: iconSize3, color: theme.secondaryText),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      myLogger.w('onChanged value: $value, tabIndex: $tabIndex');
                      ref.read(searchQueryStateProvider.notifier).state = value;
                      switch (tabIndex) {
                        case 0:
                          ref.read(feedSearchNotifierProvider.notifier).fetchSearchQueryResult();
                          break;
                        case 1:
                          ref.read(userSearchNotifierProvider.notifier).fetchSearchQueryResult();
                          break;
                      }
                    },
                  ),
                ),
              ),
            ),

            SliverFillRemaining(
              child: TabBarView(
                children: [
                  FeedSearchWidget(searchController: searchController),
                  UserSearchWidget(searchController: searchController),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const Navbar(),
      ),
    );
  }
}

class FeedSearchWidget extends ConsumerWidget {
  final TextEditingController searchController;

  const FeedSearchWidget({super.key, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final AsyncValue<List<FeedModel>> feedsAsync = ref.watch(feedSearchNotifierProvider);

    final double margin3 = dimensions.margin3;
    myLogger.d('FeedSearchWidget is building');
    return feedsAsync.when(
      data: (List<FeedModel> feeds) {
        myLogger.d('feeds.isEmpty: ${feeds.isEmpty}');
        if (feeds.isEmpty) {
          return Center(child: Text('No results found. 🔍', style: Theme.of(context).textTheme.bodyLarge));
        }

        if (feeds.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.all(margin3),
            child: ListView.separated(
              itemCount: feeds.length,
              separatorBuilder: (context, index) => SizedBox(height: margin3),
              itemBuilder: (context, index) => FeedCard(initialFeed: feeds.elementAt(index), isRefreshing: false),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class UserSearchWidget extends ConsumerWidget {
  final TextEditingController searchController;

  const UserSearchWidget({super.key, required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final userSearchAsync = ref.watch(userSearchNotifierProvider);

    final double margin3 = dimensions.margin3;
    myLogger.d('UserSearchWidget is building');
    return userSearchAsync.when(
      data: (List<UserSearchModel> userSearchResultList) {
        if (userSearchResultList.isEmpty) {
          return Center(child: Text('No results found. 🔍', style: Theme.of(context).textTheme.bodyLarge));
        }

        if (userSearchResultList.isNotEmpty) {
          return Padding(
            padding: EdgeInsets.all(margin3),
            child: ListView.separated(
              itemCount: userSearchResultList.length,
              separatorBuilder: (context, index) => SizedBox(height: margin3),
              itemBuilder: (context, index) {
                final user = userSearchResultList.elementAt(index);
                return ProfileSearchCard(user: user);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        myLogger.e('Error: $e, StackTrace: $st');
        return Center(child: Text('Error: $e, StackTrace: $st'));
      },
    );
  }
}

class ProfileSearchCard extends ConsumerWidget {
  final UserSearchModel user;

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
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => ref.read(userSearchNotifierProvider.notifier).toggleFollow(userId: user.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isFollowing ? theme.secondaryText : theme.secondaryBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(user.isFollowing ? 'Following' : 'Follow', style: TextStyle(fontSize: 12, color: user.isFollowing ? theme.primaryText : theme.secondaryText)),
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

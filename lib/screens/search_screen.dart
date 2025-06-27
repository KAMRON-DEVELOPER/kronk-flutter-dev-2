import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/search_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/my_logger.dart';
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
    final activeTheme = ref.watch(themeNotifierProvider);
    final tabIndex = ref.watch(tabIndexProvider);
    final dimensions = Dimensions.of(context);

    // final double screenWidth = dimensions.screenWidth;
    final double globalMargin2 = dimensions.margin2;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: SearchBar(
                  constraints: const BoxConstraints(maxHeight: 40, minHeight: 40),
                  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
                  backgroundColor: WidgetStatePropertyAll(activeTheme.tertiaryBackground),
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  controller: searchController,
                  onChanged: (value) {
                    myLogger.w('onChanged value: $value, tabIndex: $tabIndex');
                    ref.read(searchQueryStateProvider.notifier).state = value;
                    switch (tabIndex) {
                      case 0:
                        ref.read(postSearchNotifierProvider.notifier).fetchSearchQueryResult();
                        break;
                      case 1:
                        ref.read(userSearchNotifierProvider.notifier).fetchSearchQueryResult();
                        break;
                    }
                  },
                  hintText: 'Search Kronk',
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 20)),
                  hintStyle: WidgetStatePropertyAll(TextStyle(fontSize: 16, color: activeTheme.primaryText.withAlpha(128))),
                ),
                centerTitle: true,
                titleSpacing: globalMargin2,
                automaticallyImplyLeading: false,
                pinned: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: globalMargin2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: activeTheme.tertiaryBackground, borderRadius: BorderRadius.circular(12)),
                    child: TabBar(
                      onTap: (int tabIndex) {
                        ref.read(tabIndexProvider.notifier).state = tabIndex;
                        ref.read(searchQueryStateProvider.notifier).state = '';
                        searchController.text = '';
                      },
                      tabs: [
                        const Tab(height: 32, text: 'Posts'),
                        const Tab(height: 32, text: 'Users'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(children: [PostSearchWidget(), UserSearchWidget()]),
        ),
        bottomNavigationBar: const Navbar(),
      ),
    );
  }
}

/// Post Search -----------------------------------------------------------
class PostSearchWidget extends ConsumerWidget {
  const PostSearchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final AsyncValue<List<FeedSearchResultModel>> postSearchAsync = ref.watch(postSearchNotifierProvider);

    final double globalMargin2 = dimensions.margin2;
    myLogger.d('PostSearchWidget is building');
    return postSearchAsync.when(
      data: (List<FeedSearchResultModel> postSearchResultList) {
        if (postSearchResultList.isEmpty) return const Center(child: Text('No results found.'));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: globalMargin2),
          itemCount: postSearchResultList.length,
          itemBuilder: (context, index) {
            final post = postSearchResultList.elementAt(index);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.body, style: const TextStyle()),
                    const SizedBox(height: 8),
                    Text('By: ${post.authorId}', style: const TextStyle()),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

/// User Search -----------------------------------------------------------
class UserSearchWidget extends ConsumerWidget {
  const UserSearchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);
    final userSearchAsync = ref.watch(userSearchNotifierProvider);

    final double globalMargin2 = dimensions.margin2;
    myLogger.d('UserSearchWidget is building');
    return userSearchAsync.when(
      data: (List<UserSearchModel> userSearchResultList) {
        if (userSearchResultList.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: globalMargin2),
          itemCount: userSearchResultList.length,
          itemBuilder: (context, index) {
            final user = userSearchResultList.elementAt(index);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: theme.primaryBackground,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider('${constants.bucketEndpoint}/defaults/default-avatar.jpg', maxHeight: 60, maxWidth: 60),
                ),
                title: Text(user.username, style: TextStyle(fontSize: 12, color: theme.primaryText)),
                subtitle: Row(
                  spacing: 8,
                  children: [
                    Text('${user.followingsCount} followings', style: TextStyle(fontSize: 8, color: theme.primaryText)),
                    Text('${user.followersCount} followers', style: TextStyle(fontSize: 8, color: theme.secondaryText)),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => ref.read(userSearchNotifierProvider.notifier).toggleFollow(userId: user.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing ? theme.secondaryText : theme.secondaryBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(user.isFollowing ? 'Following' : 'Follow', style: TextStyle(color: user.isFollowing ? theme.primaryText : theme.secondaryText, fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        myLogger.e('Error: $e, StackTrace: $st');
        return Center(child: Text('Error: $e, StackTrace: $st'));
      },
    );
  }
}

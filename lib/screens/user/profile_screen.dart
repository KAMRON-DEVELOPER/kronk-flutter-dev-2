import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/profile/user_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/widgets/navbar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme activeTheme = ref.watch(themeNotifierProvider);
    final AsyncValue<UserModel?> asyncUser = ref.watch(profileProvider);
    myLogger.d('building profile screen...');
    return SafeArea(
      child: Scaffold(
        backgroundColor: activeTheme.primaryBackground.withValues(alpha: 0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: activeTheme.primaryText),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: asyncUser.when(
          data: (UserModel? user) {
            myLogger.d('user: ${user?.username}');
            return user != null ? ProfileWidget(user: user) : const ProfileSkeletonWidget();
          },
          loading: () => const ProfileSkeletonWidget(),
          error: (Object error, StackTrace _) => Center(
            child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
        bottomNavigationBar: const Navbar(),
      ),
    );
  }
}

class ProfileWidget extends ConsumerStatefulWidget {
  final UserModel user;

  const ProfileWidget({super.key, required this.user});

  @override
  ConsumerState<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends ConsumerState<ProfileWidget> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme activeTheme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);

    //final double contentWidth1 = dimensions.contentWidth1;
    final double contentWidth2 = dimensions.with2;
    //final double globalMargin1 = dimensions.globalMargin1;
    //final double buttonHeight1 = dimensions.buttonHeight1;
    //final double textSize1 = dimensions.textSize1;
    //final double textSize2 = dimensions.textSize2;
    final double textSize3 = dimensions.textSize3;
    final double cornerRadius1 = dimensions.radius1;
    myLogger.i('3. building profile widgets. username: ${widget.user.username}');
    return Center(
      child: RefreshIndicator(
        onRefresh: () async => ref.read(profileProvider.notifier).fetchProfile(),
        color: activeTheme.primaryText,
        backgroundColor: activeTheme.secondaryBackground,
        child: Column(
          children: [
            // profile info
            Container(
              width: contentWidth2,
              decoration: BoxDecoration(color: activeTheme.secondaryBackground, borderRadius: BorderRadius.circular(cornerRadius1)),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    child: CachedNetworkImage(
                      imageUrl: '${constants.bucketEndpoint}/${widget.user.avatarUrl ?? 'defaults/default-avatar.jpg'}',
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                      memCacheHeight: (96 * 2.75).toInt(),
                      memCacheWidth: (96 * 2.75).toInt(),
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover, isAntiAlias: true),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(color: activeTheme.primaryText, strokeWidth: 2),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 98, color: Colors.redAccent),
                    ),
                  ),
                  Text(
                    widget.user.username,
                    style: GoogleFonts.quicksand(color: activeTheme.primaryText, fontSize: textSize3 * 0.8, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.user.email,
                    style: GoogleFonts.quicksand(color: activeTheme.primaryText, fontSize: textSize3 * 0.8, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // TabBar
            // TabBar(
            //   controller: tabController,
            //   indicator: UnderlineTabIndicator(
            //     borderSide: BorderSide(width: 4, color: activeTheme.primaryText),
            //     borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            //   ),
            //   dividerColor: activeTheme.primaryText.withAlpha(128),
            //   dividerHeight: 0,
            //   tabs: [
            //     Tab(icon: Icon(Icons.image_rounded, color: activeTheme.primaryText, size: 32), height: 56),
            //     Tab(icon: Icon(Icons.bookmark_rounded, color: activeTheme.primaryText, size: 32), height: 56),
            //     Tab(icon: Icon(Iconsax.message_search_bold, color: activeTheme.primaryText, size: 32), height: 56),
            //     Tab(icon: Icon(Icons.comment_rounded, color: activeTheme.primaryText, size: 32), height: 56),
            //   ],
            // ),

            // TabBarView
            // Expanded(
            //   child: TabBarView(
            //     physics: const BouncingScrollPhysics(),
            //     controller: tabController,
            //     children: [const MediaTabWidget(), const BookmarksTabWidget(), const PostsTabWidget(), const CommentsTabWidget()],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class MediaTabWidget extends ConsumerWidget {
  const MediaTabWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme currentTheme = ref.watch(themeNotifierProvider);
    //final dimensions = Dimensions.of(context);

    //final double contentWidth1 = dimensions.contentWidth1;
    //final double contentWidth2 = dimensions.contentWidth2;
    //final double globalMargin1 = dimensions.globalMargin1;
    //final double buttonHeight1 = dimensions.buttonHeight1;
    //final double textSize1 = dimensions.textSize1;
    //final double textSize2 = dimensions.textSize2;
    //final double textSize3 = dimensions.textSize3;
    //final double cornerRadius1 = dimensions.cornerRadius1;
    myLogger.d('building MediaTabWidget widgets...');
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverGrid.builder(
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 0, mainAxisSpacing: 0),
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: currentTheme.secondaryBackground,
                border: Border.all(color: currentTheme.primaryText.withAlpha(64), width: 0.1),
              ),
              child: Icon(Icons.image_rounded, color: currentTheme.primaryText, size: 36),
            );
          },
        ),
      ],
    );
  }
}

class BookmarksTabWidget extends ConsumerWidget {
  const BookmarksTabWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme currentTheme = ref.watch(themeNotifierProvider);
    //final dimensions = Dimensions.of(context);

    //final double contentWidth1 = dimensions.contentWidth1;
    //final double contentWidth2 = dimensions.contentWidth2;
    //final double globalMargin1 = dimensions.globalMargin1;
    //final double buttonHeight1 = dimensions.buttonHeight1;
    //final double textSize1 = dimensions.textSize1;
    //final double textSize2 = dimensions.textSize2;
    //final double textSize3 = dimensions.textSize3;
    //final double cornerRadius1 = dimensions.cornerRadius1;
    myLogger.d('building BookmarksTabWidget widgets...');
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverGrid.builder(
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 0, mainAxisSpacing: 0),
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: currentTheme.secondaryBackground,
                border: Border.all(color: currentTheme.primaryText.withAlpha(64), width: 0.1),
              ),
              child: Icon(Icons.bookmark_rounded, color: currentTheme.primaryText, size: 36),
            );
          },
        ),
      ],
    );
  }
}

class PostsTabWidget extends ConsumerWidget {
  const PostsTabWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme currentTheme = ref.watch(themeNotifierProvider);
    //final dimensions = Dimensions.of(context);

    //final double contentWidth1 = dimensions.contentWidth1;
    //final double contentWidth2 = dimensions.contentWidth2;
    //final double globalMargin1 = dimensions.globalMargin1;
    //final double buttonHeight1 = dimensions.buttonHeight1;
    //final double textSize1 = dimensions.textSize1;
    //final double textSize2 = dimensions.textSize2;
    //final double textSize3 = dimensions.textSize3;
    //final double cornerRadius1 = dimensions.cornerRadius1;
    myLogger.d('building PostsTabWidget widgets...');
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverGrid.builder(
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 0, mainAxisSpacing: 0),
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: currentTheme.secondaryBackground,
                border: Border.all(color: currentTheme.primaryText.withAlpha(64), width: 0.1),
              ),
              child: Icon(Icons.message_rounded, color: currentTheme.primaryText, size: 36),
            );
          },
        ),
      ],
    );
  }
}

class CommentsTabWidget extends ConsumerWidget {
  const CommentsTabWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme currentTheme = ref.watch(themeNotifierProvider);
    //final dimensions = Dimensions.of(context);

    //final double contentWidth1 = dimensions.contentWidth1;
    //final double contentWidth2 = dimensions.contentWidth2;
    //final double globalMargin1 = dimensions.globalMargin1;
    //final double buttonHeight1 = dimensions.buttonHeight1;
    //final double textSize1 = dimensions.textSize1;
    //final double textSize2 = dimensions.textSize2;
    //final double textSize3 = dimensions.textSize3;
    //final double cornerRadius1 = dimensions.cornerRadius1;
    myLogger.d('building CommentsTabWidget widgets...');
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverGrid.builder(
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 0, mainAxisSpacing: 0),
          itemBuilder: (context, index) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: currentTheme.secondaryBackground,
                border: Border.all(color: currentTheme.primaryText.withAlpha(64), width: 0.1),
              ),
              child: Icon(Icons.comment_rounded, color: currentTheme.primaryText, size: 36),
            );
          },
        ),
      ],
    );
  }
}

class ProfileSkeletonWidget extends ConsumerWidget {
  const ProfileSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    myLogger.d('building skeleton widgets...');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/auth/login'), child: const Text('Sign In')),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/auth/register'), child: const Text('Sign Up')),
          ],
        ),
      ],
    );
  }
}

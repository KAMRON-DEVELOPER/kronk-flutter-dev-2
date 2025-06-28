import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_tile_model.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_ws_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/navbar.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
    final bool isFloating = displayState.feedScreenDisplayStyle == ScreenStyle.floating;
    final Dimensions dimensions = Dimensions.of(context);

    final double screenWidth = dimensions.screenWidth;
    final double appBarHeight = 56; // Title
    final screenHeight = dimensions.screenHeight - MediaQuery.of(context).padding.top - appBarHeight - kBottomNavigationBarHeight;

    final AsyncValue<String> chats = ref.watch(chatsWSNotifierProvider);

    chats.when(
      data: (data) {
        myLogger.d('data: $data type: ${data.runtimeType}');
      },
      error: (error, stackTrace) {
        myLogger.d('data: $error type: ${error.runtimeType}');
      },
      loading: () {
        myLogger.d('loading');
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Feeds'),
        leading: Builder(
          builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        actions: [IconButton(onPressed: () => showFeedScreenSettingsDialog(context, ref), icon: const Icon(Icons.display_settings_rounded))],
      ),
      body: Stack(
        children: [
          /// Static background images
          if (isFloating)
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(displayState.backgroundImagePath, fit: BoxFit.cover, cacheHeight: screenHeight.cacheSize(context), cacheWidth: screenWidth.cacheSize(context)),
              ),
            ),

          const ChatTilesWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add_rounded)),
      bottomNavigationBar: const Navbar(),
      drawer: const CustomDrawer(),
    );
  }
}

class ChatTilesWidget extends ConsumerStatefulWidget {
  const ChatTilesWidget({super.key});

  @override
  ConsumerState<ChatTilesWidget> createState() => _ChatTilesWidgetState();
}

class _ChatTilesWidgetState extends ConsumerState<ChatTilesWidget> {
  List<ChatTileModel> _previousChatTiles = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    final AsyncValue<List<ChatTileModel>> chatTiles = ref.watch(chatTileNotifierProvider);
    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      // onRefresh: () => ref.refresh(timelineNotifierProvider(widget.timelineType).future),
      onRefresh: () => ref.refresh(chatTileNotifierProvider.notifier).refresh(),
      child: chatTiles.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => ChatTileListWidget(chatTiles: _previousChatTiles, isRefreshing: true),
        data: (List<ChatTileModel> chatTiles) {
          _previousChatTiles = chatTiles;
          return ChatTileListWidget(chatTiles: chatTiles, isRefreshing: false);
        },
      ),
    );
  }
}

class ChatTileListWidget extends ConsumerWidget {
  final List<ChatTileModel> chatTiles;
  final bool isRefreshing;

  const ChatTileListWidget({super.key, required this.chatTiles, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;
    final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
    final bool isFloating = displayState.feedScreenDisplayStyle == ScreenStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (chatTiles.isEmpty && !isRefreshing)
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

        if (chatTiles.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? margin3 : 0),
            sliver: SliverList.separated(
              itemCount: chatTiles.length,
              separatorBuilder: (context, index) => SizedBox(height: margin3),
              itemBuilder: (context, index) => ChatTile(key: ValueKey(chatTiles.elementAt(index).id), initialChatTile: chatTiles.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

class ChatTile extends ConsumerWidget {
  final ChatTileModel initialChatTile;
  final bool isRefreshing;

  const ChatTile({super.key, required this.initialChatTile, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return ListTile(
      tileColor: theme.secondaryBackground,
      leading: const Icon(Icons.account_circle_rounded),
      title: Text(initialChatTile.participant.name, style: TextStyle(fontSize: 12, color: theme.primaryText)),
      subtitle: Text('@${initialChatTile.participant.username}', style: TextStyle(fontSize: 8, color: theme.secondaryText)),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_tile_model.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
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
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
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
        title: const Text('Chats'),
        leading: Builder(
          builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
        actions: [IconButton(onPressed: () => showChatsScreenSettingsDialog(context, ref), icon: const Icon(Icons.display_settings_rounded))],
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
      onRefresh: () => ref.watch(chatTileNotifierProvider.notifier).refresh(),
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
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
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
                  Text('No chats yet. 💬', style: Theme.of(context).textTheme.bodyLarge),
                  Text('Find people to chat.', style: Theme.of(context).textTheme.displaySmall),
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

void showChatsScreenSettingsDialog(BuildContext context, WidgetRef ref) {
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
          final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
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
                        final String imageName = 'assets/images/feed/${backgroundImages.elementAt(index)}';
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Images list
                            ClipRRect(
                              borderRadius: BorderRadius.circular(radius2),
                              child: GestureDetector(
                                onTap: () => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(backgroundImagePath: imageName),
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
                          onTap: () => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.edgeToEdge),
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
                          onTap: () => ref.read(feedScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.floating),
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
                    value: displayState.tileBorderRadius,
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
                    value: displayState.tileOpacity,
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

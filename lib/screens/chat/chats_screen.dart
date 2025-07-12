import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/chat/chats_ws_provider.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_drawer.dart';
import 'package:kronk/widgets/main_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    final AsyncValue<Map<String, dynamic>> chats = ref.watch(chatsWSNotifierProvider);

    chats.when(
      data: (data) {
        myLogger.w('data: $data type: ${data.runtimeType}');
        final ChatEvent event = data['type'] ?? ChatEvent.wrongType;
        switch (event) {
          case ChatEvent.typingStart:
            throw UnimplementedError();
          case ChatEvent.typingStop:
            throw UnimplementedError();
          case ChatEvent.goesOnline:
            throw UnimplementedError();
          case ChatEvent.goesOffline:
            throw UnimplementedError();
          case ChatEvent.enterChat:
            throw UnimplementedError();
          case ChatEvent.exitChat:
            throw UnimplementedError();
          case ChatEvent.createdChat:
            throw UnimplementedError();
          case ChatEvent.sentMessage:
            throw UnimplementedError();
          case ChatEvent.heartbeatAck:
            throw UnimplementedError();
          case ChatEvent.heartbeat:
            throw UnimplementedError();
          case ChatEvent.wrongType:
            throw UnimplementedError();
        }
      },
      error: (error, stackTrace) {
        myLogger.d('data: $error type: ${error.runtimeType}');
      },
      loading: () {
        myLogger.d('loading');
      },
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: MainAppBar(titleText: 'Chats', tabText1: 'chats', tabText2: 'groups', onTap: () => showChatsScreenSettingsDialog(context)),
        body: Stack(
          children: [
            /// Static background images
            if (isFloating)
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top - 52.dp,
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    displayState.backgroundImagePath,
                    fit: BoxFit.cover,
                    cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 52.dp).cacheSize(context),
                    cacheWidth: Sizes.screenWidth.cacheSize(context),
                  ),
                ),
              ),

            const TabBarView(children: [ChatsWidget(), GroupsWidget()]),
          ],
        ),
        bottomNavigationBar: const Navbar(),
        drawer: const CustomDrawer(),
      ),
    );
  }
}

class ChatsWidget extends ConsumerStatefulWidget {
  const ChatsWidget({super.key});

  @override
  ConsumerState<ChatsWidget> createState() => _ChatsWidgetState();
}

class _ChatsWidgetState extends ConsumerState<ChatsWidget> {
  List<ChatModel> _previousChats = [];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<List<ChatModel>> chats = ref.watch(chatsNotifierProvider);

    return RefreshIndicator(
      color: theme.primaryText,
      backgroundColor: theme.secondaryBackground,
      onRefresh: () => ref.watch(chatsNotifierProvider.notifier).refresh(),
      child: chats.when(
        error: (error, stackTrace) {
          if (error is DioException) return Center(child: Text('${error.message}'));
          return Center(child: Text('$error'));
        },
        loading: () => ChatListWidget(chats: _previousChats, isRefreshing: true),
        data: (List<ChatModel> chatTiles) {
          _previousChats = chatTiles;
          return ChatListWidget(chats: chatTiles, isRefreshing: false);
        },
      ),
    );
  }
}

class ChatListWidget extends ConsumerWidget {
  final List<ChatModel> chats;
  final bool isRefreshing;

  const ChatListWidget({super.key, required this.chats, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (chats.isEmpty && !isRefreshing)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No chats yet. 💬',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Find people to chat.',
                    style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 32.dp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        if (chats.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.all(isFloating ? 12.dp : 0),
            sliver: SliverList.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.dp),
              itemBuilder: (context, index) => ChatTile(key: ValueKey(chats.elementAt(index).id), chat: chats.elementAt(index), isRefreshing: isRefreshing),
            ),
          ),
      ],
    );
  }
}

class ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final bool isRefreshing;

  const ChatTile({super.key, required this.chat, required this.isRefreshing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return ListTile(
      tileColor: theme.secondaryBackground,
      leading: const Icon(Icons.account_circle_rounded),
      title: Text(chat.participant.name, style: TextStyle(fontSize: 12, color: theme.primaryText)),
      subtitle: Text('@${chat.participant.username}', style: TextStyle(fontSize: 8, color: theme.secondaryText)),
    );
  }
}

class GroupsWidget extends ConsumerWidget {
  const GroupsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return Center(
      child: Text(
        'Will be available soon, ⌛',
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24.dp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

void showChatsScreenSettingsDialog(BuildContext context) {
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
          final theme = ref.watch(themeNotifierProvider);
          final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
          final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

          final double width = 96.dp;
          final double height = 16 / 9 * width;
          return Dialog(
            backgroundColor: theme.tertiaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
            child: Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8.dp,
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
                              borderRadius: BorderRadius.circular(8.dp),
                              child: GestureDetector(
                                onTap: () => ref.read(chatsScreenStyleProvider.notifier).updateChatsScreenStyle(backgroundImagePath: imageName),
                                child: Image.asset(imageName, height: height, width: width, cacheHeight: height.cacheSize(context), cacheWidth: width.cacheSize(context)),
                              ),
                            ),

                            /// Selected background image indicator
                            if (displayState.backgroundImagePath == imageName)
                              Positioned(
                                bottom: 8,
                                child: Icon(Icons.check_circle_rounded, color: theme.secondaryText, size: 32.dp),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: 8.dp),
                    ),
                  ),

                  /// Toggle button
                  Row(
                    spacing: 8.dp,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(feedsScreenStyleProvider.notifier).updateFeedScreenStyle(screenStyle: ScreenStyle.edgeToEdge),
                          child: Container(
                            height: 64.dp,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8.dp),
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
                    value: displayState.tileBorderRadius,
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
                    value: displayState.tileOpacity,
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_message_model.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chat_messages_provider.dart';
import 'package:kronk/riverpod/chat/chat_state_provider.dart';
import 'package:kronk/riverpod/chat/chats_provider.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/chat/chats_ws_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chats_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';

final messageInputProvider = StateProvider<String>((ref) => '');

class ChatScreen extends ConsumerWidget {
  final ChatModel initialChat;

  const ChatScreen({super.key, required this.initialChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatStateProvider(initialChat));
    final notifier = ref.watch(chatStateProvider(initialChat).notifier);
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: ChatAppBar(chat: chat),
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
                  cacheHeight: (Sizes.screenHeight - MediaQuery.of(context).padding.top - 56.dp).cacheSize(context),
                  cacheWidth: Sizes.screenWidth.cacheSize(context),
                ),
              ),
            ),

          /// Content
          Column(
            children: [
              /// messages
              Expanded(
                child: chat.id != null ? ChatMessagesWidget(chat: chat, notifier: notifier) : const InitialMessageWidget(),
              ),

              /// input bar
              ChatInputWidget(chat: chat, notifier: notifier),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessagesWidget extends ConsumerWidget {
  final ChatModel chat;
  final ChatStateStateNotifier notifier;

  const ChatMessagesWidget({super.key, required this.chat, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final messages = ref.watch(chatMessagesProvider(chat.id!));
    return messages.when(
      data: (List<ChatMessageModel> messages) => ListView.separated(
        padding: EdgeInsets.all(12.dp),
        itemBuilder: (context, index) => MessageBubble(message: messages.elementAt(index)),
        separatorBuilder: (context, index) => SizedBox(height: 12.dp),
        itemCount: messages.length,
      ),
      error: (error, stackTrace) => Text(
        error.toString(),
        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      loading: () => SizedBox(
        width: 64.dp,
        height: 64.dp,
        child: const FittedBox(child: CircularProgressIndicator()),
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final ChatMessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = ref.watch(themeNotifierProvider);
    return Text(
      message.message,
      style: GoogleFonts.quicksand(fontSize: 16.dp, fontWeight: FontWeight.w600),
    );
  }
}

class ChatInputWidget extends ConsumerStatefulWidget {
  final ChatModel chat;
  final ChatStateStateNotifier notifier;

  const ChatInputWidget({super.key, required this.chat, required this.notifier});

  @override
  ConsumerState<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends ConsumerState<ChatInputWidget> {
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final String messageInput = ref.watch(messageInputProvider);
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 6.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(
            top: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
          ),
        ),
        child: Row(
          spacing: 16.dp,
          children: [
            Icon(Icons.emoji_emotions_rounded, size: 26.dp),
            Expanded(
              child: TextField(
                controller: messageController,
                onChanged: (value) {
                  ref.read(messageInputProvider.notifier).state = value;
                  ref.read(chatsWSNotifierProvider.notifier).handleTyping(chatId: widget.chat.id!, text: value);
                },
                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
                cursorColor: theme.primaryText,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: GoogleFonts.quicksand(color: theme.secondaryText, fontSize: 18.dp, fontWeight: FontWeight.w600),
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
              ),
            ),

            if (messageInput.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  try {
                    if (widget.chat.id == null) {
                      final ChatModel chat = await ref.read(chatsNotifierProvider.notifier).createChatMessage(message: messageInput);
                      myLogger.w('1 chat.id: ${chat.id}, chat.participant.name: ${chat.participant.name}, chat.lastMessage: ${chat.lastMessage}');
                      widget.notifier.updateField(chat: chat);
                      await ref.read(chatMessagesProvider(chat.id!).notifier).addMessage(message: chat.lastMessage!);
                    } else {
                      ref.read(chatsWSNotifierProvider.notifier).sendMessage(chatId: widget.chat.id!, message: messageInput);
                      await ref.read(chatMessagesProvider(widget.chat.id!).notifier).addMessage(message: widget.chat.lastMessage!);
                    }

                    messageController.clear();
                    ref.read(messageInputProvider.notifier).state = '';
                  } catch (error) {
                    if (!context.mounted) return;
                    if (GoRouterState.of(context).path == 'chat') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: theme.secondaryBackground,
                          behavior: SnackBarBehavior.floating,
                          dismissDirection: DismissDirection.horizontal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
                          margin: EdgeInsets.only(left: 28.dp, right: 28.dp, bottom: Sizes.screenHeight - 96.dp),
                          content: Text(
                            error.toString(),
                            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, height: 0),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Icon(Icons.send_rounded, size: 26.dp),
              )
            else ...[
              Icon(Icons.attach_file_rounded, size: 26.dp),
              Icon(Icons.mic_rounded, size: 26.dp),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ChatModel chat;

  const ChatAppBar({required this.chat, super.key});

  @override
  Size get preferredSize => Size(double.infinity, 56.5.dp);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return SafeArea(
      child: Container(
        height: 56.dp,
        padding: EdgeInsets.only(left: 12.dp, right: 12.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: Border(
            bottom: BorderSide(color: theme.secondaryBackground, width: 0.5.dp),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// Left back button
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back_rounded, size: 28.dp, color: theme.primaryText),
              ),
            ),

            /// Avatar, name, last seen at, online status
            Align(
              alignment: const Alignment(-0.5, 0),
              child: Row(
                spacing: 8.dp,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  /// Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22.dp),
                    child: CachedNetworkImage(
                      imageUrl: '${constants.bucketEndpoint}/${chat.participant.avatarUrl}',
                      fit: BoxFit.cover,
                      width: 44.dp,
                      memCacheWidth: 44.cacheSize(context),
                      placeholder: (context, url) => Icon(Icons.account_circle_rounded, size: 44.dp, color: theme.primaryText),
                      errorWidget: (context, url, error) => Icon(Icons.account_circle_rounded, size: 44.dp, color: theme.primaryText),
                    ),
                  ),

                  /// Name, last seen at, online status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.participant.name,
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500, height: 0),
                      ),
                      if (chat.participant.isOnline != null)
                        Text(
                          chat.participant.isOnline! ? 'Online' : 'Offline',
                          style: GoogleFonts.quicksand(
                            color: chat.participant.isOnline! ? Colors.deepOrangeAccent : theme.secondaryText,
                            fontSize: 12.dp,
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => showChatsScreenSettingsDialog(context),
                child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 28.dp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialMessageWidget extends ConsumerWidget {
  const InitialMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = ref.watch(themeNotifierProvider);
    return Center(
      child: Text(
        'Send Message 💬',
        style: GoogleFonts.quicksand(fontSize: 24.dp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

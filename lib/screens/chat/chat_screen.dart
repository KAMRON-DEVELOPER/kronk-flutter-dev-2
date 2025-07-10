import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/riverpod/chat/chats_screen_style_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/chat/chats_screen.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

class ChatScreen extends ConsumerWidget {
  final ParticipantModel participant;

  const ChatScreen({super.key, required this.participant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatsScreenDisplayState displayState = ref.watch(chatsScreenStyleProvider);
    final bool isFloating = displayState.screenStyle == ScreenStyle.floating;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: ChatAppBar(participant: participant),
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
                child: ListView(padding: EdgeInsets.all(12.dp), children: []),
              ),

              /// input bar
              const ChatInputWidget(),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatInputWidget extends ConsumerStatefulWidget {
  const ChatInputWidget({super.key});

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
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 6.dp),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          border: BoxBorder.all(color: theme.secondaryBackground, width: 0.5.dp),
        ),
        child: Row(
          spacing: 16.dp,
          children: [
            Icon(Icons.emoji_emotions_rounded, size: 26.dp),
            Expanded(
              child: TextField(
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

            if (messageController.text.isNotEmpty)
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.send_rounded, size: 26.dp),
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
  final ParticipantModel participant;

  const ChatAppBar({required this.participant, super.key});

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
                      imageUrl: '${constants.bucketEndpoint}/${participant.avatarUrl}',
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
                        participant.name,
                        style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16.dp, fontWeight: FontWeight.w500, height: 0),
                      ),
                      if (participant.isOnline != null)
                        Text(
                          participant.isOnline! ? 'Online' : 'Offline',
                          style: GoogleFonts.quicksand(
                            color: participant.isOnline! ? Colors.deepOrangeAccent : theme.secondaryText,
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

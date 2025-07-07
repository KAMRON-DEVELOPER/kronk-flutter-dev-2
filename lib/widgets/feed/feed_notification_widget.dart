import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/feed/feed_notification_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';

class FeedNotificationWidget extends ConsumerWidget {
  final ScrollController scrollController;
  final GlobalKey<RefreshIndicatorState> refreshKey;

  const FeedNotificationWidget({required this.scrollController, required this.refreshKey, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(feedNotificationNotifierProvider);
    final scrollPosition = ref.watch(scrollPositionProvider);
    final activeTheme = ref.watch(themeNotifierProvider);

    return notificationState.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (avatarUrls) {
        if (avatarUrls.isEmpty) return const SizedBox.shrink();

        final avatarSize = 32.dp;
        final overlap = 16.dp;
        final visibleAvatars = avatarUrls.take(3).toList();

        // Calculate dynamic width
        final totalWidth = 32.0 + 8 + (visibleAvatars.length * avatarSize) - ((visibleAvatars.length - 1) * overlap) + 8 + 64.0;

        // Only show if user has scrolled down
        final showBubble = scrollPosition > 100;

        return AnimatedOpacity(
          opacity: showBubble ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            top: 16.dp,
            left: (Sizes.screenWidth - totalWidth) / 2,
            child: GestureDetector(
              onTap: () async {
                scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

                // Trigger refresh after scroll completes
                await Future.delayed(const Duration(milliseconds: 300), () {
                  refreshKey.currentState?.show();
                  ref.read(feedNotificationNotifierProvider.notifier).clearNotifications();
                });
              },
              child: AnimatedContainer(
                padding: EdgeInsets.symmetric(horizontal: 12.dp, vertical: 4.dp),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: activeTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(22.dp),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.dp, offset: Offset(0, 2.dp))],
                ),
                child: Row(
                  spacing: 8.dp,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 18.dp),
                    SizedBox(
                      width: (visibleAvatars.length * avatarSize) - ((visibleAvatars.length - 1) * overlap),
                      height: avatarSize,
                      child: Stack(
                        children: List.generate(
                          visibleAvatars.length,
                          (index) => Positioned(
                            left: index * (avatarSize - overlap),
                            child: CircleAvatar(radius: avatarSize / 2, backgroundImage: NetworkImage('${constants.bucketEndpoint}/${visibleAvatars[index]}')),
                          ),
                        ),
                      ),
                    ),
                    Text('posted', style: TextStyle(fontSize: 18.dp)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

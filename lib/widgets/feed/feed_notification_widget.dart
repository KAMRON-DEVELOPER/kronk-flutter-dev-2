import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/feed/timeline_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';

class FeedNotificationWidget extends ConsumerWidget {
  final ScrollController scrollController;
  final GlobalKey<RefreshIndicatorState> refreshKey;

  const FeedNotificationWidget({required this.scrollController, required this.refreshKey, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(feedNotificationStateProvider);
    final scrollPosition = ref.watch(scrollPositionProvider);
    final activeTheme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);

    return notificationState.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (avatarUrls) {
        if (avatarUrls.isEmpty) return const SizedBox.shrink();

        final double screenWidth = dimensions.screenWidth;
        const avatarSize = 32.0;
        const overlap = 16.0;
        final visibleAvatars = avatarUrls.take(3).toList();

        // Calculate dynamic width
        final totalWidth = 32.0 + 8 + (visibleAvatars.length * avatarSize) - ((visibleAvatars.length - 1) * overlap) + 8 + 64.0;

        // Only show if user has scrolled down
        final showBubble = scrollPosition > 100;

        return AnimatedOpacity(
          opacity: showBubble ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Positioned(
            top: 16,
            left: (screenWidth - totalWidth) / 2,
            child: GestureDetector(
              onTap: () {
                scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);

                // Trigger refresh after scroll completes
                Future.delayed(const Duration(milliseconds: 500), () {
                  refreshKey.currentState?.show();
                  ref.read(feedNotificationStateProvider.notifier).clearNotifications();
                });
              },
              child: AnimatedContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: activeTheme.secondaryBackground,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 18),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    const Text('posted', style: TextStyle(fontSize: 18)),
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

/*

return Positioned(
      top: 16,
      left: (screenWidth - totalWidth) / 2,
      child: GestureDetector(
        onTap: () async {
          myLogger.d('Tapped to new post notification capsule.');
          scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
          refreshKey.currentState?.show();
          ref.read(feedNotificationNotifierProvider.notifier).clear();

          final tabController = DefaultTabController.of(context);
          int currentIndex = tabController.index;
          if (currentIndex == 0) {
            context.read<FeedBloc>().add(FetchHomeTimelineEvent());
          } else {
            context.read<FeedBloc>().add(FetchGlobalTimelineEvent());
          }
        },
        child: AnimatedContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: activeTheme.background2,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 12,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Icon(Icons.arrow_upward_rounded, color: activeTheme.text2),
                ),
              ),
              SizedBox(
                width: (visibleAvatars.length * avatarSize) - ((visibleAvatars.length - 1) * overlap),
                height: avatarSize,
                child: Stack(
                  children: List.generate(
                    visibleAvatars.length,
                    (index) => Positioned(
                      left: index * (avatarSize - overlap),
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(avatarSize / 2),
                          border: Border.all(width: 1, color: activeTheme.background2),
                          color: activeTheme.text1,
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2,
                          backgroundImage: CachedNetworkImageProvider(
                            '${constants.bucketEndpoint}/${visibleAvatars.elementAt(index)}',
                            maxWidth: (avatarSize * 2.75).toInt(),
                            maxHeight: (avatarSize * 2.75).toInt(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Text('posted', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );

*/

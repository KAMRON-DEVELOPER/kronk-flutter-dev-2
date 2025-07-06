import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/extensions.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return Drawer(
      backgroundColor: theme.secondaryBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              /// Title
              Text('Quick Settings', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 36)),

              /// Profile
              const ProfileDrawerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDrawerWidget extends ConsumerWidget {
  const ProfileDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final AsyncValue<UserModel?> asyncUser = ref.watch(profileNotifierProvider((null)));
    return asyncUser.when(
      data: (UserModel? user) {
        if (user == null) return const SizedBox.shrink();
        return Container(
          height: 100,
          decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              /// Avatar + follower/ing count
              Row(
                children: [
                  /// Avatar
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: user.avatarUrl != null
                          ? Image.network('${constants.bucketEndpoint}/${user.avatarUrl}', fit: BoxFit.cover, width: 32, cacheWidth: 32.cacheSize(context))
                          : Icon(Icons.account_circle_rounded, size: 32, color: theme.primaryText),
                    ),
                  ),

                  /// Follower/ing count
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        /// Follower count
                        Text('${user.followersCount}', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12)),

                        /// Following count
                        Text('${user.followingsCount}', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              /// Name
              Text(user.name, style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12)),

              /// Username
              Text('@${user.username}', style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 12)),
            ],
          ),
        );
      },
      error: (error, stackTrace) => Container(
        height: 100,
        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
        child: Text(error.toString(), style: GoogleFonts.quicksand(color: Colors.redAccent, fontSize: 12)),
      ),
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(12)),
        child: CircularProgressIndicator(color: theme.primaryText, constraints: const BoxConstraints(maxHeight: 50, maxWidth: 50)),
      ),
    );
  }
}

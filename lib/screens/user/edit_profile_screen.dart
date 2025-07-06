import 'dart:math';

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/image_cropper_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/general/update_data_provider.dart';
import 'package:kronk/riverpod/profile/profile_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/date_selector.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';

/// EditProfileScreen
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);

    final userAsync = ref.watch(profileNotifierProvider(null));
    final user = userAsync.asData?.value;
    if (user == null) return const SizedBox.shrink();
    final updateData = ref.watch(updateDataNotifierProvider);
    final ImageCropperState imageCropperState = ref.watch(imageCropperNotifierProvider);

    final double margin3 = dimensions.margin3;
    final double avatarRadius = dimensions.avatarRadius;
    final double appBarHeight = dimensions.appBarHeight;
    final double spacing2 = dimensions.spacing2;
    final double iconSize2 = dimensions.iconSize2;
    final double textSize6 = dimensions.textSize6;
    return Scaffold(
      appBar: CustomAppBar(
        appBarHeight: appBarHeight,
        bottomHeight: 0,
        bottomGap: 4,
        actionsSpacing: spacing2,
        appBarPadding: EdgeInsets.only(left: margin3, right: margin3 - 6),
        bottomPadding: EdgeInsets.only(left: margin3, right: margin3, bottom: 4),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: textSize6, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: iconSize2, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(profileNotifierProvider(null).notifier).updateProfile(user: user, updateData: updateData, imageCropperState: imageCropperState),
            child: Text(
              'Save',
              style: GoogleFonts.quicksand(color: theme.tertiaryBackground, fontSize: textSize6, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          spacing: avatarRadius + margin3,
          children: [
            /// Banner & avatar
            EditProfileImages(user: user),

            /// Fields
            EditProfileFields(user: user),
          ],
        ),
      ),
    );
  }
}

/// EditProfileImages
class EditProfileImages extends ConsumerWidget {
  final UserModel user;

  const EditProfileImages({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final updateData = ref.watch(updateDataNotifierProvider);
    final ImageCropperState imageCropperState = ref.watch(imageCropperNotifierProvider);

    final double screenWidth = dimensions.screenWidth;
    final bannerHeight = screenWidth * 9 / 20;
    final double avatarHeight = dimensions.avatarHeight;
    final double avatarRadius = dimensions.avatarRadius;

    final double margin3 = dimensions.margin3;
    final double buttonHeight5 = dimensions.buttonHeight5;

    myLogger.i('EditProfileImages | imageCropperState.: ${imageCropperState.croppedAvatarBytes?.length}');
    myLogger.i('EditProfileImages | user.avatarUrl.: ${user.avatarUrl}');
    myLogger.i('EditProfileImages | updateData.removeAvatar.: ${updateData.removeAvatar}');
    return DeferredPointerHandler(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Banner
          SizedBox(
            height: bannerHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => context.push('/image_cropper/banner'),
              child: updateData.removeBanner
                  ? Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground)
                  : imageCropperState.croppedBannerBytes != null
                  ? Image.memory(
                      imageCropperState.croppedBannerBytes!,
                      width: screenWidth,
                      height: bannerHeight,
                      cacheWidth: screenWidth.cacheSize(context),
                      cacheHeight: bannerHeight.cacheSize(context),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                    )
                  : Image.network(
                      '${constants.bucketEndpoint}/${user.bannerUrl}',
                      width: screenWidth,
                      height: bannerHeight,
                      cacheWidth: screenWidth.cacheSize(context),
                      cacheHeight: bannerHeight.cacheSize(context),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null ? child : Container(width: screenWidth, height: bannerHeight, color: theme.secondaryBackground),
                    ),
            ),
          ),

          /// Avatar
          Positioned(
            top: bannerHeight - avatarRadius,
            left: margin3 + 4,
            height: avatarHeight,
            child: CustomPaint(
              painter: AvatarPainter(borderColor: theme.primaryBackground, borderWidth: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(avatarRadius),
                child: DeferPointer(
                  child: GestureDetector(
                    onTap: () => context.push('/image_cropper/avatar'),
                    child: updateData.removeAvatar
                        ? Container(
                            width: avatarHeight,
                            height: avatarHeight,
                            decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                          )
                        : imageCropperState.croppedAvatarBytes != null
                        ? Image.memory(
                            imageCropperState.croppedAvatarBytes!,
                            width: avatarHeight,
                            height: avatarHeight,
                            cacheWidth: avatarHeight.cacheSize(context),
                            cacheHeight: avatarHeight.cacheSize(context),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: avatarHeight,
                              width: avatarHeight,
                              decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                            ),
                          )
                        : Image.network(
                            '${constants.bucketEndpoint}/${user.avatarUrl}',
                            width: avatarHeight,
                            height: avatarHeight,
                            cacheWidth: avatarHeight.cacheSize(context),
                            cacheHeight: avatarHeight.cacheSize(context),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: avatarHeight,
                              width: avatarHeight,
                              decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                            ),
                            loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                                ? child
                                : Container(
                                    height: avatarHeight,
                                    width: avatarHeight,
                                    decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
                                  ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          /// Banner delete
          Positioned(
            top: margin3,
            right: margin3,
            child: GestureDetector(
              onTap: () {
                if (imageCropperState.pickedAvatarBytes != null) {
                  ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedBannerBytes: null));
                } else {
                  if (user.bannerUrl != null) {
                    ref.read(updateDataNotifierProvider.notifier).updateField(user: updateData.copyWith(removeBanner: !(updateData.removeBanner)));
                  }
                }
              },
              child: Container(
                height: buttonHeight5,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.primaryBackground, shape: BoxShape.circle),
                child: FittedBox(
                  child: Icon(
                    user.bannerUrl != null
                        ? (updateData.removeBanner ? Icons.undo_rounded : Icons.delete_outline_rounded)
                        : imageCropperState.croppedBannerBytes != null
                        ? Icons.delete_outline_rounded
                        : Icons.add_rounded,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ),
          ),

          /// Avatar delete
          Positioned(
            left: margin3 + 4 + avatarRadius + (avatarRadius * cos(pi / 4)) - buttonHeight5 / 2,
            bottom: (avatarRadius * sin(pi / 4)) - buttonHeight5 / 2,
            child: DeferPointer(
              child: GestureDetector(
                onTap: () {
                  if (imageCropperState.pickedAvatarBytes != null) {
                    ref.read(imageCropperNotifierProvider.notifier).updateField(imageCropperState: imageCropperState.copyWith(croppedAvatarBytes: null));
                  } else {
                    if (user.avatarUrl != null) {
                      myLogger.i('user.avatarUrl is not null | removeAvatar: ${!(updateData.removeAvatar)}');
                      ref.read(updateDataNotifierProvider.notifier).updateField(user: updateData.copyWith(removeAvatar: !(updateData.removeAvatar)));
                    }
                  }
                },
                child: Container(
                  height: buttonHeight5,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.primaryBackground, shape: BoxShape.circle),
                  child: FittedBox(
                    child: Icon(
                      user.avatarUrl != null
                          ? (updateData.removeAvatar ? Icons.undo_rounded : Icons.delete_outline_rounded)
                          : imageCropperState.croppedAvatarBytes != null
                          ? Icons.delete_outline_rounded
                          : Icons.add_rounded,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EditProfileFields
class EditProfileFields extends ConsumerWidget {
  final UserModel user;

  const EditProfileFields({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final updateData = ref.watch(updateDataNotifierProvider);
    final updateNotifier = ref.read(updateDataNotifierProvider.notifier);

    final double padding1 = dimensions.padding1;
    final double margin3 = dimensions.margin3;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding1),
      child: Column(
        spacing: margin3,
        children: [
          /// Name
          EditProfileField(
            initialValue: user.name,
            hintText: 'name',
            onChanged: (name) => updateNotifier.updateField(user: updateData.copyWith(name: name)),
            autofillHints: AutofillHints.name,
          ),

          /// Username
          EditProfileField(
            initialValue: user.username,
            hintText: 'username',
            onChanged: (username) => updateNotifier.updateField(user: updateData.copyWith(username: username)),
            autofillHints: AutofillHints.newUsername,
          ),

          /// Email
          EditProfileField(
            initialValue: user.email,
            hintText: 'email',
            onChanged: (email) => updateNotifier.updateField(user: updateData.copyWith(email: email)),
            autofillHints: AutofillHints.email,
          ),

          /// Password
          EditProfileField(
            hintText: 'password',
            onChanged: (password) => updateNotifier.updateField(user: updateData.copyWith(password: password)),
            autofillHints: AutofillHints.newPassword,
          ),

          /// bio
          EditProfileField(
            initialValue: user.bio,
            hintText: 'bio',
            onChanged: (bio) => updateNotifier.updateField(user: updateData.copyWith(bio: bio)),
            isBio: true,
          ),

          /// country
          EditProfileField(
            initialValue: user.country,
            hintText: 'country',
            onChanged: (country) => updateNotifier.updateField(user: updateData.copyWith(country: country)),
            autofillHints: AutofillHints.countryName,
          ),

          /// city
          EditProfileField(
            initialValue: user.city,
            hintText: 'city',
            onChanged: (city) => updateNotifier.updateField(user: updateData.copyWith(city: city)),
            autofillHints: AutofillHints.addressCity,
          ),

          /// birthdate
          DatePicker(
            initialValue: user.birthdate,
            onDatePicked: (DateTime? birthdate) {
              updateNotifier.updateField(user: updateData.copyWith(birthdate: birthdate));
            },
          ),

          /// Bottom gap
          SizedBox(height: margin3),
        ],
      ),
    );
  }
}

/// FieldLabel
class FieldLabel extends ConsumerWidget {
  final String label;

  const FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final double textSize4 = dimensions.textSize4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(fontSize: textSize4, color: theme.secondaryText),
        ),
      ],
    );
  }
}

/// EditProfileField
class EditProfileField extends ConsumerStatefulWidget {
  final String? initialValue;
  final String hintText;
  final void Function(String)? onChanged;
  final String? autofillHints;
  final bool isPassword;
  final bool isBio;

  const EditProfileField({super.key, this.initialValue, required this.hintText, required this.onChanged, this.autofillHints, this.isPassword = false, this.isBio = false});

  @override
  ConsumerState<EditProfileField> createState() => _EditProfileFieldState();
}

class _EditProfileFieldState extends ConsumerState<EditProfileField> {
  late TextEditingController _controller;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Dimensions dimensions = Dimensions.of(context);
    final theme = ref.watch(themeNotifierProvider);
    final double padding1 = dimensions.padding1;
    return Column(
      children: [
        FieldLabel(label: widget.hintText),
        TextFormField(
          controller: _controller,
          style: Theme.of(context).textTheme.bodyMedium,
          cursorColor: theme.primaryText,
          onChanged: widget.onChanged,
          autofillHints: [?widget.autofillHints],
          obscureText: widget.isPassword ? !isPasswordVisible : false,
          maxLines: widget.isBio ? 4 : 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.secondaryBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            hintText: widget.hintText,
            errorText: null,
            errorStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
            contentPadding: EdgeInsets.symmetric(vertical: padding1, horizontal: padding1),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(isPasswordVisible ? Iconsax.eye_outline : Iconsax.eye_slash_outline, color: theme.primaryText.withAlpha(64)),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

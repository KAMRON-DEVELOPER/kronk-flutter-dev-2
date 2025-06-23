import 'package:flutter/material.dart';

class Dimensions {
  final BuildContext context;
  final double screenWidth;
  final double screenHeight;
  final double with1;
  final double with2;
  final double margin1;
  final double margin2;
  final double margin3;
  final double margin4;
  final double padding1;
  final double padding2;
  final double padding3;
  final double padding4;
  final double buttonHeight1;
  final double buttonHeight2;
  final double buttonHeight3;
  final double buttonHeight4;
  final double textSize1;
  final double textSize2;
  final double textSize3;
  final double textSize4;
  final double radius1;
  final double radius2;
  final double radius3;
  final double radius4;
  final double iconSize1;
  final double iconSize2;
  final double iconSize3;
  final double iconSize4;
  final double height1;
  final double height2;
  final double themeCircleRadius;
  final double bodyMedium;
  final double feedImageSelectorWidth;
  final double tabHeight1;

  Dimensions({
    required this.context,
    required this.screenWidth,
    required this.screenHeight,
    required this.with1,
    required this.with2,
    required this.margin1,
    required this.margin2,
    required this.margin3,
    required this.margin4,
    required this.padding1,
    required this.padding2,
    required this.padding3,
    required this.padding4,
    required this.buttonHeight1,
    required this.buttonHeight2,
    required this.buttonHeight3,
    required this.buttonHeight4,
    required this.textSize1,
    required this.textSize2,
    required this.textSize3,
    required this.textSize4,
    required this.radius1,
    required this.radius2,
    required this.radius3,
    required this.radius4,
    required this.iconSize1,
    required this.iconSize2,
    required this.iconSize3,
    required this.iconSize4,
    required this.height1,
    required this.height2,
    required this.themeCircleRadius,
    required this.bodyMedium,
    required this.feedImageSelectorWidth,
    required this.tabHeight1,
  });

  /// Factory constructor to calculate values based on the screen size.
  factory Dimensions.of(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final screenWidth = size.width;
    final screenHeight = size.height;

    final with1 = screenWidth * 0.94; // 392px
    final with2 = screenWidth * 0.86;

    final margin1 = screenWidth / 10;
    final margin2 = screenWidth * 0.07;
    final margin3 = screenWidth / 28;
    final margin4 = screenWidth / 36;

    final padding1 = screenWidth / 24; // 16px
    final padding2 = screenWidth / 32; // 12px
    final padding3 = screenWidth / 48; // 8px
    final padding4 = screenWidth / 98; // 4px

    final buttonHeight1 = screenHeight / 16;
    final buttonHeight2 = screenHeight / 18;
    final buttonHeight3 = screenHeight / 20;
    final buttonHeight4 = screenHeight / 28;

    final textSize1 = screenWidth / 8;
    final textSize2 = screenWidth / 12;
    final double bodyMedium = screenWidth / 22;
    final textSize3 = screenWidth / 20;
    final textSize4 = screenWidth / 32;

    final double cornerRadius1 = screenWidth / 30;
    final double cornerRadius2 = screenWidth / 32;
    final double cornerRadius3 = screenWidth / 34;
    final double cornerRadius4 = screenWidth / 36;

    final double iconSize1 = screenWidth / 12;
    final double iconSize2 = screenWidth / 16;
    final double iconSize3 = screenWidth / 20;
    final double iconSize4 = screenWidth / 24;

    final height1 = screenHeight / 7.5;
    final double height2 = screenWidth / 9;

    final themeCircleRadius = screenWidth / 7;

    final feedImageSelectorWidth = screenWidth / 4;

    final tabHeight1 = screenWidth / 14;

    return Dimensions(
      context: context,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      with1: with1,
      with2: with2,
      margin1: margin1,
      margin2: margin2,
      margin3: margin3,
      margin4: margin4,
      padding1: padding1,
      padding2: padding2,
      padding3: padding3,
      padding4: padding4,
      buttonHeight1: buttonHeight1,
      buttonHeight2: buttonHeight2,
      buttonHeight3: buttonHeight3,
      buttonHeight4: buttonHeight4,
      textSize1: textSize1,
      textSize2: textSize2,
      textSize3: textSize3,
      textSize4: textSize4,
      bodyMedium: bodyMedium,
      radius1: cornerRadius1,
      radius2: cornerRadius2,
      radius3: cornerRadius3,
      radius4: cornerRadius4,
      iconSize1: iconSize1,
      iconSize2: iconSize2,
      iconSize3: iconSize3,
      iconSize4: iconSize4,
      height1: height1,
      height2: height2,
      themeCircleRadius: themeCircleRadius,
      feedImageSelectorWidth: feedImageSelectorWidth,
      tabHeight1: tabHeight1,
    );
  }
}

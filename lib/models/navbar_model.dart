import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/kronk_icon.dart';

class NavbarModel extends HiveObject {
  @HiveField(0)
  String route;

  @HiveField(1)
  bool isEnabled;

  @HiveField(2)
  bool isUpcoming;

  @HiveField(3)
  bool isPending;

  NavbarModel({required this.route, this.isEnabled = false, this.isUpcoming = false, this.isPending = false});

  IconData getIconData({required bool isActive}) => getNavbarIconByName(route: route, isActive: isActive);
}

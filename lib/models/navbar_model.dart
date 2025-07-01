import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/constants/kronk_icon.dart';

// @HiveType(typeId: 0, adapterName: 'NavbarAdapter')
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

  NavbarModel copyWith({bool? isEnabled, bool? isUpcoming, bool? isPending}) {
    return NavbarModel(route: route, isEnabled: isEnabled ?? this.isEnabled, isUpcoming: isUpcoming ?? this.isUpcoming, isPending: isPending ?? this.isPending);
  }

  // @override
  // List<Object?> get props => [route, isEnabled, isUpcoming, isPending];
}

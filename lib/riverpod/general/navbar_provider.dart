import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/utility/storage.dart';

final navbarProvider = NotifierProvider<NavbarNotifier, List<NavbarModel>>(() => NavbarNotifier());

class NavbarNotifier extends Notifier<List<NavbarModel>> {
  final Storage _storage = Storage();

  @override
  List<NavbarModel> build() => _storage.getNavbarItems();

  Future<void> toggleNavbarItem({required int index}) async {
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    NavbarModel navbarItem = navbarItems.elementAt(index);

    if (navbarItem.isEnabled) {
      navbarItem.isEnabled = false;
      await navbarItem.save();
    } else {
      navbarItem.isEnabled = true;
      await navbarItem.save();
    }

    state = _storage.getNavbarItems();
  }

  Future<void> reorderNavbarItem({required int oldIndex, required int newIndex}) async {
    // Update state immediately
    List<NavbarModel> navbarItems = <NavbarModel>[...state];
    final NavbarModel reorderedItem = navbarItems.removeAt(oldIndex);
    navbarItems.insert(newIndex, reorderedItem);
    state = navbarItems;

    final navbarItemsToPrint = navbarItems.map((item) => item.route).toList();
    log('!!! navbarItemsToPrint in navbarNotifierProvider: $navbarItemsToPrint', level: 800);

    // Persist the updated order asynchronously
    await _storage.updateNavbarItemOrder(oldIndex: oldIndex, newIndex: newIndex);
  }
}

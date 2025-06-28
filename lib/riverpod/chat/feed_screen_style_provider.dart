import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/storage.dart';

final chatsScreenStyleProvider = NotifierProvider<ChatsScreenStyleNotifier, ChatsScreenDisplayState>(ChatsScreenStyleNotifier.new);

class ChatsScreenStyleNotifier extends Notifier<ChatsScreenDisplayState> {
  final Storage _storage = Storage();

  @override
  ChatsScreenDisplayState build() => _storage.getChatsScreenDisplayStyle();

  Future<void> updateFeedScreenStyle({ScreenStyle? screenStyle, double? tileOpacity, double? tileBorderRadius, String? backgroundImagePath}) async {
    final newState = state.copyWith(screenStyle: screenStyle, tileOpacity: tileOpacity, tileBorderRadius: tileBorderRadius, backgroundImagePath: backgroundImagePath);
    state = newState;

    await _storage.setSettingsAllAsync({
      'chatsScreenDisplayStyle': newState.screenStyle.name,
      'chatsScreenBackgroundImagePath': newState.backgroundImagePath,
      'chatsScreenCardOpacity': newState.tileOpacity,
      'chatsScreenCardBorderRadius': newState.tileBorderRadius,
    });
  }
}

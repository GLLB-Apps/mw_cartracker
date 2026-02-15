import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class BackgroundHotkeyService {
  static final BackgroundHotkeyService _instance = BackgroundHotkeyService._internal();
  factory BackgroundHotkeyService() => _instance;
  BackgroundHotkeyService._internal();

  final List<HotKey> _registeredHotKeys = [];
  bool _isRegistered = false;

  bool get supportsSystemHotkeys =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> register({
    required Future<void> Function(int slotIndex) onFavoriteSlot,
  }) async {
    if (!supportsSystemHotkeys || _isRegistered) {
      return;
    }

    try {
      final favoriteKeys = [
        PhysicalKeyboardKey.digit1,
        PhysicalKeyboardKey.digit2,
        PhysicalKeyboardKey.digit3,
        PhysicalKeyboardKey.digit4,
        PhysicalKeyboardKey.digit5,
        PhysicalKeyboardKey.digit6,
        PhysicalKeyboardKey.digit7,
        PhysicalKeyboardKey.digit8,
        PhysicalKeyboardKey.digit9,
        PhysicalKeyboardKey.digit0,
      ];

      for (var i = 0; i < favoriteKeys.length; i++) {
        final hotKey = HotKey(
          key: favoriteKeys[i],
          modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
        );

        await hotKeyManager.register(
          hotKey,
          keyDownHandler: (_) async {
            await onFavoriteSlot(i);
          },
        );

        _registeredHotKeys.add(hotKey);
      }

      _isRegistered = true;
    } on MissingPluginException {
      // Keep app functional when plugin isn't linked in the current runtime.
      _isRegistered = false;
    } on PlatformException {
      _isRegistered = false;
    }
  }

  Future<void> unregisterAll() async {
    for (final hotKey in _registeredHotKeys) {
      await hotKeyManager.unregister(hotKey);
    }
    _registeredHotKeys.clear();
    _isRegistered = false;
  }
}

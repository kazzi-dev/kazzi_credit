import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Follows the system setting until the user picks a mode in Settings.
// TODO(kazzi): persist the choice once the storage layer lands.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  ThemeMode get mode => state;
  set mode(ThemeMode value) => state = value;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

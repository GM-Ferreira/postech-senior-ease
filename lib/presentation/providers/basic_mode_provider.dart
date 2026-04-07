import 'package:flutter_riverpod/flutter_riverpod.dart';

class BasicModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool enabled}) => state = enabled;
}

final basicModeProvider = NotifierProvider<BasicModeNotifier, bool>(
  BasicModeNotifier.new,
);

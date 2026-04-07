import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool enabled}) => state = enabled;
}

final confirmActionsProvider = NotifierProvider<ConfirmActionsNotifier, bool>(
  ConfirmActionsNotifier.new,
);

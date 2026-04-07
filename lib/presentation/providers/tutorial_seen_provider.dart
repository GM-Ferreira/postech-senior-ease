import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorialSeenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool seen}) => state = seen;
}

final tutorialSeenProvider = NotifierProvider<TutorialSeenNotifier, bool>(
  TutorialSeenNotifier.new,
);

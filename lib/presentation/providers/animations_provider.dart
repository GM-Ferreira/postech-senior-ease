import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReduceAnimationsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void set({required bool reduce}) {
    state = reduce;
  }
}

final reduceAnimationsProvider =
    NotifierProvider<ReduceAnimationsNotifier, bool>(
      ReduceAnimationsNotifier.new,
    );

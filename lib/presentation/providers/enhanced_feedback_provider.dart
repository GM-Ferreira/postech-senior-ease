import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnhancedFeedbackNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool enabled}) => state = enabled;
}

final enhancedFeedbackProvider =
    NotifierProvider<EnhancedFeedbackNotifier, bool>(
      EnhancedFeedbackNotifier.new,
    );

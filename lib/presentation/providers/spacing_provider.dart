import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpacingScaleNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void setScale(double scale) {
    state = scale.clamp(0.8, 2.0);
  }
}

final spacingScaleProvider = NotifierProvider<SpacingScaleNotifier, double>(
  SpacingScaleNotifier.new,
);

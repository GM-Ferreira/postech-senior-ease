import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontScaleNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void setScale(double scale) {
    state = scale.clamp(0.8, 2.5);
  }
}

final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ContrastLevel {
  normal(0.0),
  high(0.5),
  veryHigh(1.0);

  const ContrastLevel(this.value);
  final double value;
}

class ContrastLevelNotifier extends Notifier<ContrastLevel> {
  @override
  ContrastLevel build() => ContrastLevel.normal;

  void setLevel(ContrastLevel level) {
    state = level;
  }
}

final contrastLevelProvider =
    NotifierProvider<ContrastLevelNotifier, ContrastLevel>(
      ContrastLevelNotifier.new,
    );

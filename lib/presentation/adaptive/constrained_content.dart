import 'package:flutter/material.dart';

/// Limita a largura do conteúdo em telas largas, centralizando-o.
/// No mobile, ocupa toda a largura disponível.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

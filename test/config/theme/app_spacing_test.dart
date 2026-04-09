import 'package:flutter_test/flutter_test.dart';
import 'package:senior_ease/config/theme/app_spacing.dart';

void main() {
  // ─── AppSpacing.scaled ───

  group('AppSpacing.scaled', () {
    // A factory recebe um fator e multiplica os valores base
    // Base: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
    test('fator 1.0 retorna valores base', () {
      final spacing = AppSpacing.scaled(1.0);

      expect(spacing.xs, 4.0);
      expect(spacing.sm, 8.0);
      expect(spacing.md, 16.0);
      expect(spacing.lg, 24.0);
      expect(spacing.xl, 32.0);
      expect(spacing.xxl, 48.0);
    });

    test('fator 2.0 dobra todos os valores', () {
      final spacing = AppSpacing.scaled(2.0);

      expect(spacing.xs, 8.0);
      expect(spacing.sm, 16.0);
      expect(spacing.md, 32.0);
      expect(spacing.lg, 48.0);
      expect(spacing.xl, 64.0);
      expect(spacing.xxl, 96.0);
    });

    test('fator 0.5 reduz pela metade', () {
      final spacing = AppSpacing.scaled(0.5);

      expect(spacing.xs, 2.0);
      expect(spacing.sm, 4.0);
      expect(spacing.md, 8.0);
    });
  });

  // ─── AppSpacing.copyWith ───

  group('AppSpacing.copyWith', () {
    final original = AppSpacing.scaled(1.0);

    test('altera apenas o campo especificado', () {
      final alterado = original.copyWith(md: 99.0);

      expect(alterado.md, 99.0); // mudou
      expect(alterado.xs, original.xs); // preservou
      expect(alterado.sm, original.sm); // preservou
      expect(alterado.lg, original.lg); // preservou
    });

    test('sem argumentos retorna cópia idêntica', () {
      final copia = original.copyWith();

      expect(copia.xs, original.xs);
      expect(copia.sm, original.sm);
      expect(copia.md, original.md);
      expect(copia.lg, original.lg);
      expect(copia.xl, original.xl);
      expect(copia.xxl, original.xxl);
    });
  });

  // ─── AppSpacing.lerp ───

  group('AppSpacing.lerp', () {
    // lerp interpola entre dois AppSpacing (usado em animações de tema)
    test('t=0 retorna valores de a, t=1 retorna valores de b', () {
      final a = AppSpacing.scaled(1.0); // xs=4
      final b = AppSpacing.scaled(2.0); // xs=8

      final noInicio = a.lerp(b, 0.0);
      expect(noInicio.xs, 4.0);

      final noFim = a.lerp(b, 1.0);
      expect(noFim.xs, 8.0);
    });

    test('t=0.5 retorna valor intermediário', () {
      final a = AppSpacing.scaled(1.0); // md=16
      final b = AppSpacing.scaled(2.0); // md=32

      final meio = a.lerp(b, 0.5);
      expect(meio.md, 24.0); // (16+32)/2
    });

    test('lerp com null retorna this', () {
      final spacing = AppSpacing.scaled(1.0);
      final resultado = spacing.lerp(null, 0.5);

      expect(resultado.xs, spacing.xs);
      expect(resultado.md, spacing.md);
    });
  });
}

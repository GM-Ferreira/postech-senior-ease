import 'package:flutter_test/flutter_test.dart';
import 'package:senior_ease/core/entities/app_user.dart';

void main() {
  // ─── AppUser ───

  final original = AppUser(
    uid: 'abc123',
    email: 'joao@email.com',
    createdAt: DateTime(2026, 1, 1),
    displayName: 'João Silva',
    photoUrl: 'https://example.com/photo.jpg',
  );

  group('AppUser.copyWith', () {
    test('altera apenas o campo especificado', () {
      final alterado = original.copyWith(displayName: 'Maria');

      expect(alterado.displayName, 'Maria'); // mudou
      expect(alterado.uid, original.uid); // preservou
      expect(alterado.email, original.email); // preservou
      expect(alterado.photoUrl, original.photoUrl); // preservou
      expect(alterado.createdAt, original.createdAt); // preservou
    });

    test('altera múltiplos campos de uma vez', () {
      final novaData = DateTime(2026, 6, 15);

      final alterado = original.copyWith(
        uid: 'novo_id',
        email: 'novo@email.com',
        createdAt: novaData,
      );

      expect(alterado.uid, 'novo_id');
      expect(alterado.email, 'novo@email.com');
      expect(alterado.createdAt, novaData);
      // Campos não alterados preservados
      expect(alterado.displayName, original.displayName);
      expect(alterado.photoUrl, original.photoUrl);
    });

    test('preserva campos opcionais nulos quando não especificados', () {
      final semFoto = AppUser(
        uid: 'x',
        email: 'x@x.com',
        createdAt: DateTime(2026, 1, 1),
      );

      final alterado = semFoto.copyWith(email: 'novo@x.com');

      expect(alterado.displayName, isNull); // continua null
      expect(alterado.photoUrl, isNull); // continua null
      expect(alterado.email, 'novo@x.com'); // mudou
    });
  });
}

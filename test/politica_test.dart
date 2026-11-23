import 'package:flutter_test/flutter_test.dart';
import 'package:notificaciones/dominio/politica.dart';

void main() {
  const politica = PoliticaNotificaciones();

  test('el silencio comprende desde las diez de la noche hasta antes de las ocho', () {
    expect(politica.enSilencio(DateTime(2026, 11, 12, 23)), isTrue);
    expect(politica.enSilencio(DateTime(2026, 11, 12, 7, 59)), isTrue);
    expect(politica.enSilencio(DateTime(2026, 11, 12, 8)), isFalse);
    expect(politica.enSilencio(DateTime(2026, 11, 12, 12)), isFalse);
  });

  test('un aviso nocturno se mueve a las ocho del día siguiente', () {
    expect(
      politica.ajustar(DateTime(2026, 11, 12, 23)),
      DateTime(2026, 11, 13, 8),
    );
  });

  test('un aviso de madrugada se mueve a las ocho del mismo día', () {
    expect(politica.ajustar(DateTime(2026, 11, 12, 3)), DateTime(2026, 11, 12, 8));
  });
}

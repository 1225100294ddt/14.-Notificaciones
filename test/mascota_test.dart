import 'package:flutter_test/flutter_test.dart';
import 'package:notificaciones/dominio/mascota.dart';

void main() {
  final inicio = DateTime(2026, 11, 12, 10);

  test('la saciedad baja diez puntos por hora', () {
    final mascota = Mascota.nueva('Xólotl', inicio);
    expect(mascota.saciedadEn(inicio), 100);
    expect(mascota.saciedadEn(inicio.add(const Duration(hours: 3))), 70);
  });

  test('el ajolote tiene hambre a las seis horas', () {
    final mascota = Mascota.nueva('Xólotl', inicio);
    expect(mascota.humorEn(inicio.add(const Duration(hours: 6))), Humor.hambriento);
  });

  test('alimentar recupera 35 puntos sin superar cien', () {
    final mascota = Mascota.nueva('Xólotl', inicio);
    final momento = inicio.add(const Duration(hours: 6));
    expect(mascota.alimentar(momento).saciedadEn(momento), 75);
  });

  test('se puede guardar y recuperar la mascota', () {
    final original = Mascota.nueva('Xólotl', inicio);
    final recuperada = Mascota.desdeTexto(original.aTexto());
    expect(recuperada?.nombre, 'Xólotl');
    expect(recuperada?.saciedadBase, 100);
  });
}

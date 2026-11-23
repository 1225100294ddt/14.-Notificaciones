import 'dart:convert';
import 'dart:math' as math;

enum Humor { feliz, hambriento, famelico }

class Mascota {
  const Mascota({
    required this.nombre,
    required this.saciedadBase,
    required this.desde,
    this.puntosPorHora = 10,
  });

  factory Mascota.nueva(String nombre, DateTime ahora, {double puntosPorHora = 10}) {
    return Mascota(
      nombre: nombre,
      saciedadBase: 100,
      desde: ahora,
      puntosPorHora: puntosPorHora,
    );
  }

  static const double maxSaciedad = 100;
  static const double umbralHambre = 40;
  static const double umbralCritico = 15;
  static const double porcion = 35;

  final String nombre;
  final double saciedadBase;
  final DateTime desde;
  final double puntosPorHora;

  double saciedadEn(DateTime momento) {
    if (!momento.isAfter(desde)) return saciedadBase;
    final horas = momento.difference(desde).inMicroseconds / Duration.microsecondsPerHour;
    return math.max(0, saciedadBase - horas * puntosPorHora);
  }

  Humor humorEn(DateTime momento) {
    final valor = saciedadEn(momento);
    if (valor <= umbralCritico) return Humor.famelico;
    if (valor <= umbralHambre) return Humor.hambriento;
    return Humor.feliz;
  }

  DateTime momentoEnQueBajaA(double umbral) {
    if (saciedadBase <= umbral) return desde;
    final horas = (saciedadBase - umbral) / puntosPorHora;
    return desde.add(Duration(microseconds: (horas * Duration.microsecondsPerHour).round()));
  }

  Mascota alimentar(DateTime momento) {
    final actual = saciedadEn(momento);
    if (actual >= 90) throw StateError('Tu ajolotito todavía está lleno.');
    return Mascota(
      nombre: nombre,
      saciedadBase: math.min(100, actual + porcion),
      desde: momento,
      puntosPorHora: puntosPorHora,
    );
  }

  Mascota conRitmo(DateTime momento, double ritmo) => Mascota(
        nombre: nombre,
        saciedadBase: saciedadEn(momento),
        desde: momento,
        puntosPorHora: ritmo,
      );

  Map<String, Object> toJson() => {
        'nombre': nombre,
        'saciedadBase': saciedadBase,
        'desde': desde.toIso8601String(),
        'puntosPorHora': puntosPorHora,
      };

  String aTexto() => jsonEncode(toJson());

  static Mascota? desdeTexto(String? texto) {
    if (texto == null) return null;
    try {
      final json = jsonDecode(texto);
      if (json is! Map<String, dynamic>) return null;
      final nombre = json['nombre'];
      final saciedad = json['saciedadBase'];
      final fecha = json['desde'];
      final ritmo = json['puntosPorHora'];
      if (nombre is! String || nombre.isEmpty || saciedad is! num || fecha is! String || ritmo is! num) {
        return null;
      }
      final desde = DateTime.tryParse(fecha);
      if (desde == null || saciedad < 0 || saciedad > 100 || ritmo <= 0) return null;
      return Mascota(
        nombre: nombre,
        saciedadBase: saciedad.toDouble(),
        desde: desde,
        puntosPorHora: ritmo.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class PoliticaNotificaciones {
  const PoliticaNotificaciones({this.silencioDesde = 22, this.silencioHasta = 8});

  final int silencioDesde;
  final int silencioHasta;

  bool enSilencio(DateTime momento) {
    if (silencioDesde == silencioHasta) return false;
    if (silencioDesde > silencioHasta) {
      return momento.hour >= silencioDesde || momento.hour < silencioHasta;
    }
    return momento.hour >= silencioDesde && momento.hour < silencioHasta;
  }

  DateTime ajustar(DateTime momento) {
    if (!enSilencio(momento)) return momento;
    final finHoy = DateTime(momento.year, momento.month, momento.day, silencioHasta);
    return momento.isBefore(finHoy)
        ? finHoy
        : DateTime(momento.year, momento.month, momento.day + 1, silencioHasta);
  }
}

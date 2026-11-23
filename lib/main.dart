import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dominio/mascota.dart';
import 'dominio/politica.dart';
import 'infra/notificaciones_locales.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final avisos = NotificacionesLocales.instancia;
  await avisos.inicializar();
  final preferencias = await SharedPreferences.getInstance();
  runApp(AjolotitoApp(preferencias: preferencias, avisos: avisos));
}

class AjolotitoApp extends StatelessWidget {
  const AjolotitoApp({super.key, required this.preferencias, required this.avisos});
  final SharedPreferences preferencias;
  final NotificacionesLocales avisos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notificaciones',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF168C83)),
        scaffoldBackgroundColor: const Color(0xFFF4FAF8),
        fontFamily: 'Roboto',
      ),
      home: PantallaAjolotito(preferencias: preferencias, avisos: avisos),
    );
  }
}

class PantallaAjolotito extends StatefulWidget {
  const PantallaAjolotito({super.key, required this.preferencias, required this.avisos});
  final SharedPreferences preferencias;
  final NotificacionesLocales avisos;

  @override
  State<PantallaAjolotito> createState() => _PantallaAjolotitoState();
}

class _PantallaAjolotitoState extends State<PantallaAjolotito> with WidgetsBindingObserver {
  late Mascota mascota;
  bool hambreActiva = true;
  bool sorpresasActivas = true;
  bool modoClase = false;
  bool permisoConcedido = false;
  bool resaltarComer = false;
  bool cargando = true;
  final PoliticaNotificaciones politica = const PoliticaNotificaciones();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.avisos.alTocar = _alTocarNotificacion;
    _cargar();
  }

  void _alTocarNotificacion(String? payload, String? accion) {
    if (!mounted) return;
    setState(() => resaltarComer = payload == 'v1:alimentar' || payload == 'v1:alimentarYa');
    if (payload == 'v1:alimentarYa' || accion == 'alimentar') _alimentar();
  }

  Future<void> _cargar() async {
    final prefs = widget.preferencias;
    mascota = Mascota.desdeTexto(prefs.getString('mascota')) ?? Mascota.nueva('Xólotl', DateTime.now());
    hambreActiva = prefs.getBool('hambreActiva') ?? true;
    sorpresasActivas = prefs.getBool('sorpresasActivas') ?? true;
    modoClase = prefs.getBool('modoClase') ?? false;
    final payload = await widget.avisos.payloadInicial();
    if (!mounted) return;
    setState(() {
      cargando = false;
      resaltarComer = payload == 'v1:alimentar' || payload == 'v1:alimentarYa';
    });
    if (payload == 'v1:alimentarYa') await _alimentar();
    await _reprogramar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _reprogramar(incluirHambre: true);
    } else if (state == AppLifecycleState.resumed && !cargando) {
      // En primer plano la información se muestra dentro de la app, no como aviso.
      _reprogramar(incluirHambre: false);
    }
  }

  double get saciedad => mascota.saciedadEn(DateTime.now());
  Humor get humor => mascota.humorEn(DateTime.now());

  Future<void> _guardar() async {
    await widget.preferencias.setString('mascota', mascota.aTexto());
    await widget.preferencias.setBool('hambreActiva', hambreActiva);
    await widget.preferencias.setBool('sorpresasActivas', sorpresasActivas);
    await widget.preferencias.setBool('modoClase', modoClase);
  }

  Future<void> _alimentar() async {
    try {
      setState(() {
        mascota = mascota.alimentar(DateTime.now());
        resaltarComer = false;
      });
      await _guardar();
      await _reprogramar();
      _mensaje('¡Ñam! ${mascota.nombre} recuperó energía.');
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _activarAvisos() async {
    final yaPregunto = widget.preferencias.getBool('yaPregunto') ?? false;
    if (yaPregunto) {
      _mensaje('Si no aparecen avisos, revisa los permisos de notificaciones en Ajustes del teléfono.');
      return;
    }
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Te avisamos cuando tenga hambre?'),
        content: const Text('Podemos enviarte un aviso cuando Xólotl necesite comer. Respetaremos el silencio de 10 p. m. a 8 a. m. y podrás apagar cada tipo de aviso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, avísame')),
        ],
      ),
    );
    if (aceptar != true) return;
    await widget.preferencias.setBool('yaPregunto', true);
    final resultado = await widget.avisos.pedirPermiso();
    if (!mounted) return;
    setState(() => permisoConcedido = resultado);
    if (resultado) {
      await _reprogramar(incluirHambre: true);
      _mensaje('¡Listo! Los avisos están activados.');
    } else {
      _mensaje('No se concedió el permiso. Puedes activarlo desde Ajustes del teléfono.');
    }
  }

  Future<void> _reprogramar({bool incluirHambre = false}) async {
    await widget.avisos.cancelarTodas();
    final ahora = DateTime.now();
    final ritmo = modoClase ? 600.0 : 10.0;
    final actual = mascota.conRitmo(ahora, ritmo);
    if (hambreActiva && incluirHambre) {
      final nivel = actual.saciedadEn(ahora);
      if (nivel > Mascota.umbralHambre) {
        final cuando = politica.ajustar(actual.momentoEnQueBajaA(40));
        await widget.avisos.programar(
          id: 1,
          titulo: '${mascota.nombre} tiene hambre 🍤',
          cuerpo: 'Un acocil, por favor. ¡Tu ajolotito necesita comer!',
          cuando: cuando.isAfter(ahora) ? cuando : ahora.add(const Duration(minutes: 1)),
          esHambre: true,
          payload: 'v1:alimentar',
        );
      }
      if (nivel > Mascota.umbralCritico) {
        final cuando = politica.ajustar(actual.momentoEnQueBajaA(15));
        await widget.avisos.programar(
          id: 2,
          titulo: '${mascota.nombre} necesita ayuda 🥺',
          cuerpo: 'Lleva mucho sin comer. ¡Dale una porción!',
          cuando: cuando.isAfter(ahora) ? cuando : ahora.add(const Duration(minutes: 1)),
          esHambre: true,
          payload: 'v1:alimentar',
        );
      }
    }
    if (sorpresasActivas) {
      for (var dia = 0; dia < 3; dia++) {
        final fecha = DateTime(ahora.year, ahora.month, ahora.day + dia, 18);
        final cuando = politica.ajustar(fecha);
        if (cuando.isAfter(ahora)) {
          await widget.avisos.programar(
            id: 100 + dia,
            titulo: '¡Una sorpresa para ti! 🎈',
            cuerpo: dia.isEven ? 'Los ajolotes pueden regenerar sus patitas.' : '${mascota.nombre} se peinó las branquias para saludarte.',
            cuando: cuando,
            esHambre: false,
            payload: 'v1:jugar',
          );
        }
      }
    }
  }

  Future<void> _probarAviso() async {
    await widget.avisos.mostrarPrueba();
    _mensaje('Se envió una notificación de prueba.');
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirAjustes() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de notificación'),
        content: const Text('Si rechazaste el permiso, abre Ajustes del teléfono → Aplicaciones → Notificaciones → Notificaciones y activa los avisos para esta app.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final valor = saciedad.clamp(0, 100);
    final textoHumor = switch (humor) {
      Humor.feliz => '¡Estoy feliz y lleno!',
      Humor.hambriento => 'Mi pancita está haciendo glub glub…',
      Humor.famelico => '¡Necesito comida, por favor!',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajolotito Hambriento', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(tooltip: 'Ajustes', onPressed: _mostrarAjustes, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD9F5ED), Color(0xFFE8F4FF)]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(children: [
                const Text('🫧', style: TextStyle(fontSize: 30)),
                const Text('🦎', style: TextStyle(fontSize: 104)),
                Text(mascota.nombre, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF155E59))),
                const SizedBox(height: 6),
                Text(textoHumor, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Nivel de saciedad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('${valor.round()} / 100', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: valor / 100, minHeight: 15, backgroundColor: const Color(0xFFE1EAE7), color: valor <= 15 ? Colors.redAccent : const Color(0xFF159B84)),
                  ),
                  const SizedBox(height: 8),
                  const Text('La saciedad disminuye con el paso del tiempo.'),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: resaltarComer ? const Color(0xFF159B84) : Colors.transparent, width: 3),
              ),
              child: FilledButton.icon(
                onPressed: _alimentar,
                icon: const Icon(Icons.restaurant),
                label: const Text('Dar de comer 🍤'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _activarAvisos,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Avísame cuando tenga hambre'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _probarAviso,
              icon: const Icon(Icons.notification_add_outlined),
              label: const Text('Probar una notificación ahora'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Reglas de notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                  const Text('🌙 Horas de silencio: 10:00 p. m. a 8:00 a. m.'),
                  const Text('🔔 Los avisos de hambre y sorpresas se controlan por separado.'),
                  const Text('📱 En primer plano, el estado se muestra aquí.'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarAjustes() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ajustes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hambre del ajolote'),
              subtitle: const Text('Avisos importantes cuando necesita comer.'),
              value: hambreActiva,
              onChanged: (v) async {
                actualizar(() => hambreActiva = v);
                setState(() => hambreActiva = v);
                await _guardar();
                await _reprogramar(incluirHambre: true);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sorpresas y juegos'),
              subtitle: const Text('Un mensaje discreto al día.'),
              value: sorpresasActivas,
              onChanged: (v) async {
                actualizar(() => sorpresasActivas = v);
                setState(() => sorpresasActivas = v);
                await _guardar();
                await _reprogramar(incluirHambre: true);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo clase (tiempo acelerado)'),
              subtitle: const Text('El hambre sube más rápido para probar en minutos.'),
              value: modoClase,
              onChanged: (v) async {
                actualizar(() => modoClase = v);
                setState(() => modoClase = v);
                mascota = mascota.conRitmo(DateTime.now(), v ? 600 : 10);
                await _guardar();
                await _reprogramar(incluirHambre: true);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Permisos del teléfono'),
              subtitle: const Text('Consulta cómo activar las notificaciones.'),
              onTap: () {
                Navigator.pop(context);
                _abrirAjustes();
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

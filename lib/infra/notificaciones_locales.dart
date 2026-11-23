import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacionesLocales {
  NotificacionesLocales._();
  static final NotificacionesLocales instancia = NotificacionesLocales._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  void Function(String?, String?)? alTocar;

  static const AndroidNotificationChannel hambreChannel = AndroidNotificationChannel(
    'hambre',
    'Hambre del ajolote',
    description: 'Avisos cuando tu ajolotito necesita comer.',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel sorpresaChannel = AndroidNotificationChannel(
    'sorpresas',
    'Sorpresas y juegos',
    description: 'Datos curiosos e invitaciones a jugar.',
    importance: Importance.low,
  );

  Future<void> inicializar() async {
    tz.initializeTimeZones();
    // Se utiliza la zona horaria de México centro.
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (respuesta) => this.alTocar?.call(respuesta.payload, respuesta.actionId),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(hambreChannel);
    await androidPlugin?.createNotificationChannel(sorpresaChannel);
  }

  Future<bool> pedirPermiso() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final resultado = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final permisoIos = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return resultado ?? permisoIos ?? true;
  }

  Future<void> mostrarPrueba() async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'hambre', 'Hambre del ajolote',
        channelDescription: 'Avisos cuando tu ajolotito necesita comer.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _plugin.show(
      id: 900,
      title: '¡Glub, glub! 🫧',
      body: 'Tu ajolotito te manda saludos. Las notificaciones funcionan.',
      notificationDetails: detalles,
      payload: 'v1:inicio',
    );
  }

  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
    required bool esHambre,
    required String payload,
  }) async {
    final detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        esHambre ? 'hambre' : 'sorpresas',
        esHambre ? 'Hambre del ajolote' : 'Sorpresas y juegos',
        channelDescription: esHambre
            ? 'Avisos cuando tu ajolotito necesita comer.'
            : 'Datos curiosos e invitaciones a jugar.',
        importance: esHambre ? Importance.high : Importance.low,
        priority: esHambre ? Priority.high : Priority.low,
        actions: esHambre
            ? const [AndroidNotificationAction('alimentar', 'Dar de comer', showsUserInterface: true)]
            : const [],
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: cuerpo,
      scheduledDate: tz.TZDateTime.from(cuando, tz.local),
      notificationDetails: detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelarTodas() => _plugin.cancelAll();

  Future<String?> payloadInicial() async {
    final detalle = await _plugin.getNotificationAppLaunchDetails();
    if (detalle?.didNotificationLaunchApp ?? false) {
      return detalle?.notificationResponse?.payload;
    }
    return null;
  }
}

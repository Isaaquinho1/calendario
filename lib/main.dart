import 'package:calendario/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/notification_service.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'notifiers/theme_notifier.dart'; // 👈 Necesitarás crear este archivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ORDEN CORRECTO DE INICIALIZACIÓN:

  // 1. INICIALIZAR HIVE PRIMERO (es fundamental)
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());

  // 2. INICIALIZAR NOTIFICACIONES ANTES DE ABRIR CAJAS
  await NotificationService.init();

  // 3. INICIALIZAR FIREBASE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 4. INICIALIZAR FORMATO DE FECHA
  await initializeDateFormatting('es', null); // 👈 Se mantiene tu 'es'

  // 5. ABRIR CAJAS DE HIVE
  await Hive.openBox<Task>('tasks');
  // 🔑 Guardamos la caja de usuario en una variable para leer el tema
  final userBox = await Hive.openBox('userBox');

  // 6. 🔑 LEER EL TEMA GUARDADO (NUEVA LÓGICA)
  final String savedTheme = userBox.get('theme', defaultValue: 'system');
  ThemeMode initialThemeMode;
  switch (savedTheme) {
    case 'light':
      initialThemeMode = ThemeMode.light;
      break;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    default:
      initialThemeMode = ThemeMode.system;
      break;
  }

  // 7. 🔑 ENVOLVER RUNAPP CON EL PROVIDER
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(initialThemeMode, userBox),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 8. 🔑 CONSUMIR EL NOTIFIER
    // Esto hace que la app se reconstruya cuando el tema cambia
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Configuración de Localización (Tu código)
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],

      home: const SplashScreen(), // Tu home
      // 9. 🔑 CONFIGURACIÓN DE TEMAS (ACTUALIZADO)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(255, 55, 78, 107),
        scaffoldBackgroundColor: const Color.fromARGB(255, 232, 232, 232),
        cardColor: const Color.fromARGB(255, 212, 212, 212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 55, 78, 107),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(
          255,
          114,
          153,
          204,
        ), // Tono azul claro para modo oscuro
        scaffoldBackgroundColor: const Color.fromARGB(
          255,
          18,
          18,
          18,
        ), // Fondo oscuro
        cardColor: const Color.fromARGB(255, 40, 40, 40), // Tarjetas oscuras
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 114, 153, 204),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // 10. 🔑 APLICAR EL MODO DE TEMA ACTUAL
      themeMode: themeNotifier.currentTheme,
    );
  }
}

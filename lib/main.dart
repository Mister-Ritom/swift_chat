import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swift_chat/app.dart';
import 'package:swift_chat/core/app_theme.dart';
import 'package:swift_chat/firebase_options.dart';
import 'package:swift_chat/utils/fcm_service.dart';
import 'package:swift_chat/utils/pb_utils.dart';

// Base navy color
const int _navyPrimaryValue = 0xFF001F54; // deep navy

// Custom MaterialColor for navy
const MaterialColor navyBlue = MaterialColor(_navyPrimaryValue, <int, Color>{
  50: Color(0xFFE6E8F3),
  100: Color(0xFFBCC4E0),
  200: Color(0xFF8EA0CC),
  300: Color(0xFF6080B8),
  400: Color(0xFF3E66A9),
  500: Color(_navyPrimaryValue), // main color
  600: Color(0xFF001C4D),
  700: Color(0xFF001842),
  800: Color(0xFF001538),
  900: Color(0xFF000E28),
});

const primaryColor = navyBlue;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    //for now persistence login is disabled on web
    final dir = await getApplicationDocumentsDirectory();
    Hive.defaultDirectory = dir.path;
    hiveAuthCheck();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Request iOS notification permissions
    await FirebaseMessaging.instance.requestPermission(provisional: true);
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      var initSettings = InitializationSettings(android: androidSettings);
      await flutterLocalNotificationsPlugin.initialize(initSettings);
      await FCMService.saveFCMToken();
      await FCMService.setupFCMListeners();
    }
  }

  runApp(const ProviderScope(child: SwiftChat()));
}

class SwiftChat extends StatelessWidget {
  const SwiftChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adda Chat',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(isDark: false),
      darkTheme: _buildTheme(isDark: true),
      home: const App(),
    );
  }

  ThemeData _buildTheme({required bool isDark}) {
    final base =
        isDark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);

    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white70 : Colors.black87;

    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      cardColor:
          isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF8F8F8), // 👈 Added
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: Colors.amberAccent,
      ),
      textTheme: buildTextTheme(textColor),
      iconTheme: IconThemeData(color: iconColor),
      appBarTheme: buildAppBarTheme(isDark: isDark),
      bottomNavigationBarTheme: buildBottomNavBarTheme(isDark: isDark),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black87 : Colors.white,
      ),
      elevatedButtonTheme: buildElevatedButtonTheme(isDark: isDark),
      textButtonTheme: buildTextButtonTheme(isDark: isDark),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swift_chat/app.dart';
import 'package:swift_chat/core/app_theme.dart';
import 'package:swift_chat/utils/auth_utils.dart';

const primaryColor = Colors.orange;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  Hive.defaultDirectory = dir.path;

  hiveAuthCheck();

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
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: Colors.amberAccent,
      ),
      textTheme: buildTextTheme(textColor),
      iconTheme: IconThemeData(color: iconColor),
      appBarTheme: buildAppBarTheme(isDark: isDark),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black87 : Colors.white,
      ),
      elevatedButtonTheme: buildElevatedButtonTheme(isDark: isDark),
      textButtonTheme: buildTextButtonTheme(isDark: isDark),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/calendar_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadThemePreference();
  runApp(
    ChangeNotifierProvider.value(
      value: themeNotifier,
      child: MainApp(),
    ),
  );
}

class ThemeNotifier with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.white,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
            ),
            fontFamily: 'Tenada',
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Tenada'),
              bodyMedium: TextStyle(fontFamily: 'Tenada'),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.grey[900],
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: Colors.grey[850],
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey[400],
            ),
            fontFamily: 'Tenada',
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Tenada'),
              bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Tenada'),
            ),
          ),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: CalendarScreen(),
        );
      },
    );
  }
}
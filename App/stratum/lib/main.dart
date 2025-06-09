import 'package:flutter/material.dart';
import 'package:stratum/CreateSerScreen.dart';
import 'HomeScreen.dart';
import 'SettingsScreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blueGrey,
          surface: Colors.blueGrey.shade700,
          primary: Colors.blueGrey.shade50,
        ),
        snackBarTheme: SnackBarThemeData(
          elevation: 10,
          backgroundColor: Colors.blueGrey[600],
          contentTextStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade600,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey.shade600,
        ),
        cardTheme: CardThemeData(
          color: Colors.blueGrey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        bottomAppBarTheme: BottomAppBarTheme(shape: CircularNotchedRectangle()),
      ),
      home: Home(),

      routes: {
        '/setting': (context) => Settings(),
        '/add': (context) => CreateSer(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

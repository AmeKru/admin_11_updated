import 'package:admin_11_updated/pages/auth.dart';
import 'package:admin_11_updated/pages/main_page.dart';
import 'package:admin_11_updated/utils/loading.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await loadData();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xff014689), // Global cursor color
        ),
      ),

      debugShowCheckedModeBanner: false,
      initialRoute: '/auth',
      routes: {
        '/': (context) => Loading(),
        '/home': (context) => MainPage(),
        '/auth': (context) => AuthPage(),
      },
    );
  }
}

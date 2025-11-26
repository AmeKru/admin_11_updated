import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/loading.dart';
import '../utils/text_sizing.dart';
import 'general_pages/auth_login_page.dart';
import 'general_pages/home_page.dart';

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
    if (kDebugMode) {
      print('rebuilt app');
    }
    // sets size at start so layout will scale accordingly
    TextSizing.setSize(context);
    return MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xff014689), // Global cursor color
        ),
      ),

      debugShowCheckedModeBanner: false,
      initialRoute: '/auth',
      routes: {
        '/': (context) => LoadingScreen(),
        '/home': (context) => HomePage(),
        '/auth': (context) => AuthPage(),
      },
    );
  }
}

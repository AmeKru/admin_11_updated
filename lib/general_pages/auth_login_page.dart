import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../amplifyconfiguration.dart';
import '../models/ModelProvider.dart';
import '../utils/text_sizing.dart';
import 'home_page.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Auth Login Page ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// AuthPage Class

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  ////////////////////////////////////////////////////////////////////////////////
  // Amplify configuration

  Future<void> _configureAmplify() async {
    try {
      if (!Amplify.isConfigured) {
        await Amplify.addPlugins([
          AmplifyAuthCognito(),
          AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider())),
        ]);
        await Amplify.configure(amplifyconfig);
        if (kDebugMode) {
          print('Amplify configured successfully.');
        }
      }
    } on AmplifyAlreadyConfiguredException {
      if (kDebugMode) {
        print('Amplify has already been configured.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error configuring Amplify: $e');
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////////
  // build function of login page

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      authenticatorBuilder: (BuildContext context, AuthenticatorState state) {
        if (state.currentStep == AuthenticatorStep.signIn) {
          return CustomScaffold(state: state, body: SignInForm());
        } else {
          return null;
        }
      },

      child: MaterialApp(
        builder: Authenticator.builder(),

        theme: ThemeData(
          // Core color palette used by buttons, inputs, links, etc.
          colorScheme: const ColorScheme.light(
            primary: Color(0xff014689), // accent (e.g., submit buttons)
            onPrimary: Colors.white, // text/icons on primary
            secondary: Color(0xffFFB300), // secondary accents
            surface: Colors.white, // cards, fields background
            onSurface: Colors.black87, // text on surface
          ),

          // Buttons in forms (Sign In, Create account, etc.)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff014689),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),

          // Text fields (email, password)
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xffEEF2F7),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xffC7D1E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff014689), width: 2),
            ),
            labelStyle: TextStyle(color: Color(0xff455A64)),
            hintStyle: TextStyle(color: Color(0xff78909C)),
          ),

          // Links like “Forgot password?”
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff014689),
            ),
          ),
        ),

        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You are logged in!',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.normal,
                    fontSize: TextSizing.fontSizeText(context),
                  ),
                ),
                SizedBox(height: TextSizing.fontSizeMiniText(context)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  child: Text(
                    'Go to Main Page',
                    style: TextStyle(
                      color: Color(0xff014689),
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: TextSizing.fontSizeText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// Custom Scaffold

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({super.key, required this.state, required this.body});

  final AuthenticatorState state;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Auth Login page built');
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(TextSizing.fontSizeText(context)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.2,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

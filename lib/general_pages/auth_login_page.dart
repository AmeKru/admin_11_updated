import 'package:admin_11_updated/utils/loading.dart';
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
          return CustomScaffold(
            state: state,
            body: CustomSignInForm(state: state),
          );
        }
        return null;
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

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Customized login UI ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// CustomSignInForm Class

class CustomSignInForm extends StatefulWidget {
  final AuthenticatorState state;
  const CustomSignInForm({super.key, required this.state});

  @override
  State<CustomSignInForm> createState() => _CustomSignInFormState();
}

class _CustomSignInFormState extends State<CustomSignInForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool signingIn = false;

  Future<void> _signIn() async {
    setState(() {
      signingIn = true;
    });
    try {
      final res = await Amplify.Auth.signIn(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (res.isSignedIn) {
        if (kDebugMode) {
          print("Signed in successfully");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Sign in failed: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Sign In failed. Check entered Email and Password.',
                ),
              ),
            ),
          );
        }
        setState(() {
          signingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              color: Colors.black,
              size: TextSizing.fontSizeHeading(context),
            ),
            SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
            Text(
              'MooBus Admin App',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black,
                fontSize: TextSizing.fontSizeHeading(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        SizedBox(height: TextSizing.fontSizeText(context)),

        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                20.0,
              ), // Adjust the value for roundness
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: Colors.grey,
              ), // Customize border color
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: const Color(0xff014689),
                width: 2.0,
              ), // Customize when focused
            ),
          ),
        ),

        SizedBox(height: TextSizing.fontSizeText(context)),

        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                20.0,
              ), // Adjust the value for roundness
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: Colors.grey,
              ), // Customize border color
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(
                color: const Color(0xff014689),
                width: 2.0,
              ), // Customize when focused
            ),
          ),
        ),

        SizedBox(height: TextSizing.fontSizeText(context)),

        signingIn
            ? LoadingScreen()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),

                  backgroundColor: const Color(0xff014689),
                  foregroundColor: Colors.white,
                ),
                onPressed: _signIn,
                child: const Text('Sign In'),
              ),
      ],
    );
  }
}

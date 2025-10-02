import 'package:admin_11_updated/amplifyconfiguration.dart';
import 'package:admin_11_updated/models/model_provider.dart';
import 'package:admin_11_updated/pages/main_page.dart';
import 'package:admin_11_updated/utils/text_sizing.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  //
  Future<void> _configureAmplify() async {
    try {
      if (!Amplify.isConfigured) {
        final auth = AmplifyAuthCognito();
        await Amplify.addPlugin(auth);

        final provider = ModelProvider();
        final amplifyApi = AmplifyAPI(
          options: APIPluginOptions(modelProvider: provider),
        );
        Amplify.addPlugin(amplifyApi);
        await Amplify.configure(amplifyconfig);
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
                      MaterialPageRoute(builder: (context) => MainPage()),
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

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({super.key, required this.state, required this.body});

  final AuthenticatorState state;
  final Widget body;

  @override
  Widget build(BuildContext context) {
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

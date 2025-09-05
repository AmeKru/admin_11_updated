import 'package:admin_11_updated/amplifyconfiguration.dart';
import 'package:admin_11_updated/models/ModelProvider.dart';
import 'package:admin_11_updated/pages/main_page.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/material.dart';

class Auth_Page extends StatefulWidget {
  const Auth_Page({super.key});

  @override
  State<Auth_Page> createState() => _Auth_PageState();
}

class _Auth_PageState extends State<Auth_Page> {
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
      print('Amplify has already been configured.');
    } catch (e) {
      print('Error configuring Amplify: $e');
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
                Text('You are logged in!'),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Main_Page()),
                    );
                  },
                  child: Text('Go to Main Page'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
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

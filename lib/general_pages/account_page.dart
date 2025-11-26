// Import necessary pages and packages
import 'package:admin_11_updated/utils/loading.dart';
import 'package:amplify_core/amplify_core.dart'; // Amplify Auth for sign-out functionality
import 'package:flutter/material.dart'; // Flutter UI components

import '../utils/text_sizing.dart';
import 'auth_login_page.dart'; // AuthPage for post-sign-out navigation

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Account Page ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// AccountPage displays user account info and provides sign-out functionality

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  ////////////////////////////////////////////////////////////////////////////////
  // Variables

  // save email of user to display
  String? userEmail;

  // used show loading state before everything is loaded properly
  bool loading = false;

  ////////////////////////////////////////////////////////////////////////////////
  // init State

  @override
  void initState() {
    super.initState();
    loadUserEmail();
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Functions ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Handles sign-out logic and navigation to AuthPage

  Future<void> _signOut(BuildContext context) async {
    // This avoids using BuildContext after an async gap, which can cause warnings/crashes
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Attempt to sign out using Amplify Auth
      await Amplify.Auth.signOut();

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false, // Prevent back navigation
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Center(child: Text('Error signing out: ${e.message}')),
        ),
      );
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // gets user email

  Future<void> loadUserEmail() async {
    loading = true;
    final attributes = await Amplify.Auth.fetchUserAttributes();
    final emailAttr = attributes.firstWhere(
      (attr) => attr.userAttributeKey.key == 'email',
    );
    setState(() {
      userEmail = emailAttr.value;
      loading = false;
    });
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Sign Out',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                navigator.pop();
                _signOut(context);
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Main build ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // === AppBar ===
      appBar: AppBar(
        toolbarHeight: TextSizing.fontSizeHeading(context) * 2.5,
        centerTitle: true,

        // define colours of appbar
        iconTheme: IconThemeData(
          color: Colors.white, // CHANGED: Customize back arrow color
          size: TextSizing.fontSizeHeading(context),
        ),

        // back button on the left
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: TextSizing.fontSizeHeading(context),
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); //  go back
          },
        ),

        // space on right to center title
        actions: [
          Icon(
            Icons.circle,
            size: TextSizing.fontSizeHeading(context),
            color: const Color(0xff002345),
          ),
        ],

        // title
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: TextSizing.fontSizeHeading(context),
              color: Colors.white,
            ),
            SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
            Text(
              'Account Details',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: TextSizing.fontSizeHeading(context),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xff002345), // Custom AppBar background
      ),

      // === Body Content ===
      body: loading
          ? LoadingScreen()
          : Padding(
              padding: EdgeInsets.all(
                TextSizing.fontSizeText(context),
              ), // Uniform padding around content
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email,
                        size: TextSizing.fontSizeText(context),
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: TextSizing.fontSizeMiniText(context) * 0.5,
                      ),
                      Text(
                        'email: ',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: TextSizing.fontSizeText(context),
                        ),
                      ),
                      SizedBox(
                        width: TextSizing.fontSizeMiniText(context) * 0.5,
                      ),
                      Text(
                        userEmail != null ? userEmail! : 'no email found :(',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.normal,
                          fontSize: TextSizing.fontSizeText(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: TextSizing.fontSizeHeading(context) * 2,
                  ), // Spacing before button
                  // === Sign Out Button ===
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(
                          0xff002345,
                        ), // Button background color
                        foregroundColor: Colors.white, // Text and icon color
                      ),
                      onPressed: () =>
                          _showSignOutDialog(context), // Trigger sign-out
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: TextSizing.fontSizeText(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

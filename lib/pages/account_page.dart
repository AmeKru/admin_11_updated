// Import necessary pages and packages
import 'package:admin_11_updated/pages/auth.dart'; // AuthPage for post-sign-out navigation
import 'package:admin_11_updated/utils/text_sizing.dart';
import 'package:amplify_core/amplify_core.dart'; // Amplify Auth for sign-out functionality
import 'package:flutter/material.dart'; // Flutter UI components

// AccountPage displays user account info and provides sign-out functionality
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Handles sign-out logic and navigation to AuthPage
  Future<void> _signOut(BuildContext context) async {
    /// CHANGE: Capture the ScaffoldMessenger and Navigator before any `await`
    // This avoids using BuildContext after an async gap, which can cause warnings/crashes
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Attempt to sign out using Amplify Auth
      await Amplify.Auth.signOut();

      /// CHANGE: Use the pre-captured navigator instead of Navigator.pushAndRemoveUntil(context, ...)
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false, // Prevent back navigation
      );
    } on AuthException catch (e) {
      /// CHANGE: Use the pre-captured messenger instead of ScaffoldMessenger.of(context)
      messenger.showSnackBar(
        SnackBar(
          content: Center(child: Text('Error signing out: ${e.message}')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // === AppBar ===
      appBar: AppBar(
        toolbarHeight: TextSizing.fontSizeHeading(context) * 2.5,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // CHANGED: Customize back arrow color
          size: TextSizing.fontSizeHeading(context),
        ),
        title: Text(
          'Account Details',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: TextSizing.fontSizeHeading(context),
          ),
        ),
        backgroundColor: Color(0xff002345), // Custom AppBar background
      ),

      // === Body Content ===
      body: Padding(
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
                  Icons.account_circle,
                  size: TextSizing.fontSizeText(context),
                  color: Colors.black,
                ),
                SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
                Text(
                  'Account Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
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
                  backgroundColor: Color(0xff002345), // Button background color
                  foregroundColor: Colors.white, // Text and icon color
                ),
                onPressed: () => _signOut(context), // Trigger sign-out
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

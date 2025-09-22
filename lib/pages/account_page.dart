// Import necessary pages and packages
import 'package:admin_11_updated/pages/auth.dart'; // AuthPage for post-sign-out navigation
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
        SnackBar(content: Text('Error signing out: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // === AppBar ===
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // CHANGED: Customize back arrow color
        ),
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xff002345), // Custom AppBar background
      ),

      // === Body Content ===
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Uniform padding around content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20), // Spacing before button

            const Spacer(), // Push button to bottom of screen
            // === Sign Out Button ===
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff002345), // Button background color
                  foregroundColor: Colors.white, // Text and icon color
                ),
                onPressed: () => _signOut(context), // Trigger sign-out
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

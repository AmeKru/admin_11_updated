import 'package:admin_11_updated/pages/Auth.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/material.dart';

class Account_Page extends StatefulWidget {
  const Account_Page({Key? key}) : super(key: key);

  @override
  State<Account_Page> createState() => _Account_PageState();
}

class _Account_PageState extends State<Account_Page> {
  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Auth_Page()),
        (Route<dynamic> route) => false,
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: Colors.yellow[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _signOut(context),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

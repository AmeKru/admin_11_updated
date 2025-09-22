// Import Flutter material components
import 'package:flutter/material.dart';

// SettingsPage displays app settings and preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// State class for SettingsPage
class _SettingsPageState extends State<SettingsPage> {
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
          'Settings',
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
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            // CHANGED: Placeholder for future settings options
            // add toggles, dropdowns, or other controls here
          ],
        ),
      ),
    );
  }
}

// Import Flutter material components
import 'package:admin_11_updated/utils/text_sizing.dart';
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
        toolbarHeight: TextSizing.fontSizeHeading(context) * 2.5,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // CHANGED: Customize back arrow color
          size: TextSizing.fontSizeHeading(context),
        ),
        title: Text(
          'Settings',
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
        padding: const EdgeInsets.all(16.0), // Uniform padding around content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings,
                  size: TextSizing.fontSizeText(context),
                  color: Colors.black,
                ),
                SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: TextSizing.fontSizeText(context),
                  ),
                ),
              ],
            ),

            // CHANGED: Placeholder for future settings options
            // add toggles, dropdowns, or other controls here
          ],
        ),
      ),
    );
  }
}

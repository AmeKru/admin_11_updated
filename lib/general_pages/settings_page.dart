// Import Flutter material components
import 'package:flutter/material.dart';

import '../utils/text_sizing.dart';

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

        // colours of appbar
        iconTheme: IconThemeData(
          color: Colors.white, // CHANGED: Customize back arrow color
          size: TextSizing.fontSizeHeading(context),
        ),

        // arrow at the left
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

        // on the right, just there to center the title, is camouflaged
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
              Icons.settings,
              size: TextSizing.fontSizeHeading(context),
              color: Colors.white,
            ),
            SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
            Text(
              'Settings',
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

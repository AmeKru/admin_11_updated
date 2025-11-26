import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../utils/text_sizing.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- loading widgets ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// A full-screen loading screen widget
// Displays a centered spinning lines animation while the app is busy
// (e.g., during initial data load or a blocking operation)
// The background color changes depending on whether dark mode is enabled

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Set background color
      color: Colors.white,

      // Center the loading animation in the middle of the screen
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.blueGrey[200]!, // Color of the wave animation
        ), // Spinner size in logical pixels
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// Used when choosing a button, whilst the Bus list loads (and routes)
// This is a smaller, inline loading indicator rather than a full-screen one

class LoadingScroll extends StatefulWidget {
  const LoadingScroll({super.key});

  @override
  State<LoadingScroll> createState() => _LoadingScrollState();
}

class _LoadingScrollState extends State<LoadingScroll> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add some vertical spacing above the loader
        SizedBox(height: TextSizing.fontSizeText(context)),

        // Container to hold the loading animation
        Container(
          // Background color
          color: Colors.white,

          // Center the loading animation horizontally
          child: Center(
            child: SpinKitWave(
              color: Colors.blueGrey[200], // Color of the wave animation
              size: TextSizing.fontSizeHeading(
                context,
              ), // Size of the animation
            ),
          ),
        ),
      ],
    );
  }
}

// Import necessary pages and Flutter material components
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ngee_ann_pages/ngee_ann.dart';
import '../other_organization_pages/organization_1.dart';
import '../other_organization_pages/organization_2.dart';
import '../utils/text_sizing.dart';
import 'account_page.dart';
import 'settings_page.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Home Page ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// HomePage class

// Main landing page of the admin app
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

////////////////////////////////////////////////////////////////////////////////
// State class for MainPage with animation support (for menu on the left)

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  //////////////////////////////////////////////////////////////////////////////
  // variables

  // Animation controller for sliding menu
  late AnimationController _controller;

  // Slide animation for the side menu
  late Animation<Offset> _slideAnimation;

  // Tracks whether the menu is currently open
  bool _isMenuOpen = false;

  //////////////////////////////////////////////////////////////////////////////
  // init state

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with 300ms duration
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Define slide animation from left off-screen to visible
    _slideAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0), // Start off-screen to the left
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  //////////////////////////////////////////////////////////////////////////////
  // dispose

  @override
  void dispose() {
    // Dispose animation controller to free resources
    _controller.dispose();
    super.dispose();
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Helpers---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Toggles the side menu open/closed with animation

  void _toggleMenu() {
    setState(() {
      if (_isMenuOpen) {
        _controller.reverse(); // Animate menu closing
      } else {
        _controller.forward(); // Animate menu opening
      }
      _isMenuOpen = !_isMenuOpen; // Flip the state
    });
  }

  //////////////////////////////////////////////////////////////////////////////
  // Builds a tappable card for each organization

  Widget _buildOrganizationButton(
    String name, // Display name of the organization
    Widget page, // Page to navigate to, on tap
    BuildContext context,
    String imagePath,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff014689),
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        if (_isMenuOpen) {
          // Closes menu if open
          _toggleMenu();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                page, // Navigate to the page passed as parameter
          ),
        );
      },
      child: Container(
        padding: EdgeInsetsGeometry.fromLTRB(
          0,
          TextSizing.fontSizeMiniText(context),
          0,
          TextSizing.fontSizeMiniText(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                imagePath,
                width: TextSizing.fontSizeHeading(context),
                height: TextSizing.fontSizeHeading(context),
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(
              width: TextSizing.fontSizeMiniText(context),
              height: TextSizing.fontSizeHeading(context),
            ),

            Flexible(
              child: Text(
                name,
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
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
    if (kDebugMode) {
      print('Home Page built');
    }
    return Scaffold(
      backgroundColor: Colors.white,
      // Top AppBar with custom layout
      appBar: AppBar(
        toolbarHeight: TextSizing.fontSizeHeading(context) * 2.5,
        automaticallyImplyLeading: false, // no default back arrow
        backgroundColor: const Color(0xff014689),

        // left aligned menu icon
        leading: IconButton(
          icon: Icon(
            _isMenuOpen ? Icons.close : Icons.menu,
            size: TextSizing.fontSizeHeading(context),
          ),
          color: Colors.white,
          onPressed: _toggleMenu,
        ),

        // space on the right to center title more easily
        actions: [
          Container(
            padding: EdgeInsetsGeometry.fromLTRB(
              0,
              0,
              TextSizing.fontSizeText(context),
              0,
            ),
            child: Icon(
              Icons.circle,
              size: TextSizing.fontSizeHeading(context),
              color: const Color(0xff014689),
            ),
          ),
        ],

        // title
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              color: Colors.white,
              size: TextSizing.fontSizeHeading(context),
            ),
            SizedBox(width: TextSizing.fontSizeMiniText(context) * 0.5),
            Text(
              'MooBus Admin App',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontSize: TextSizing.fontSizeHeading(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      // Main body with layered layout
      body: Stack(
        children: [
          // === Main content ===
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsetsGeometry.fromLTRB(
                TextSizing.fontSizeHeading(context) * 2,
                TextSizing.fontSizeHeading(context) * 2,
                TextSizing.fontSizeHeading(context) * 2,
                TextSizing.fontSizeHeading(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization selection section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Instruction text centered
                      Text(
                        'Choose organization\nto administrate:',
                        textAlign: TextAlign.center,
                        softWrap: true, //  limits to 1 lines
                        overflow:
                            TextOverflow.ellipsis, // clips text if not fitting
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.black,
                          fontSize: TextSizing.fontSizeHeading(context),
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      // Spacing before cards
                      SizedBox(height: TextSizing.fontSizeHeading(context)),

                      // Organization cards
                      _buildOrganizationButton(
                        "Ngee Ann",
                        NgeeAnnBusData(),
                        context,
                        'images/np_logo.png',
                      ),
                      SizedBox(height: TextSizing.fontSizeText(context)),
                      _buildOrganizationButton(
                        "Organization 2",
                        Org1(),
                        context,
                        'images/placeholder.png',
                      ),
                      SizedBox(height: TextSizing.fontSizeText(context)),
                      _buildOrganizationButton(
                        "Organization 3",
                        Org2(),
                        context,
                        'images/placeholder.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // === Sliding side menu on the left ===
          SlideTransition(
            position: _slideAnimation, // Controls slide-in animation
            child: Container(
              width: MediaQuery.of(context).size.width * 0.33, // Menu width
              color: const Color(0xff002345), // Menu background color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: TextSizing.fontSizeHeading(context)),

                  // Button to go to account details
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff002345),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.zero, // removes rounded corners
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AccountPage(), // Navigate to AccountPage
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsetsGeometry.fromLTRB(
                        0,
                        TextSizing.fontSizeMiniText(context),
                        0,
                        TextSizing.fontSizeMiniText(context),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: TextSizing.fontSizeHeading(context),
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: TextSizing.fontSizeMiniText(context),
                            height: TextSizing.fontSizeHeading(context),
                          ),

                          Flexible(
                            child: Text(
                              "Account",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: TextSizing.fontSizeHeading(context),
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // button to go to settings
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff002345),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.zero, // removes rounded corners
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        TextSizing.fontSizeMiniText(context),
                        0,
                        TextSizing.fontSizeMiniText(context),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.settings,
                            size: TextSizing.fontSizeHeading(context),
                            color: Colors.white,
                          ),
                          SizedBox(width: TextSizing.fontSizeMiniText(context)),

                          Flexible(
                            child: Text(
                              "Settings",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1, // important to enforce single line
                              style: TextStyle(
                                fontSize: TextSizing.fontSizeHeading(context),
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

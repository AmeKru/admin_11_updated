// Import necessary pages and Flutter material components
import 'package:admin_11_updated/pages/account_page.dart';
import 'package:admin_11_updated/pages/ngee_ann.dart';
import 'package:admin_11_updated/pages/organization_1.dart';
import 'package:admin_11_updated/pages/organization_2.dart';
import 'package:admin_11_updated/pages/settings_page.dart';
import 'package:flutter/material.dart';

// Main landing page of the admin app
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

// State class for MainPage with animation support
class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  // Animation controller for sliding menu
  late AnimationController _controller;

  // Slide animation for the side menu
  late Animation<Offset> _slideAnimation;

  // Tracks whether the menu is currently open
  bool _isMenuOpen = false;

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

  @override
  void dispose() {
    // Dispose animation controller to free resources
    _controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Top AppBar with custom layout
      appBar: AppBar(
        title: Stack(
          children: [
            // Left-aligned menu icon (changes between open/close)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
                color: Colors.white,
                onPressed: _toggleMenu, // Toggle menu on button press
              ),
            ),

            // Centered app title with bus icon
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MooBus Admin App',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        automaticallyImplyLeading:
            false, // Prevents default back arrow or drawer icon
        backgroundColor: Color(0xff014689), // Custom app bar color
      ),

      // Main body with layered layout
      body: Stack(
        children: [
          // === Main content ===
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top spacing
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Organization selection section
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instruction text centered
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.01,
                          ),
                          Text(
                            'Choose organization to administrate:',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 25,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      // Spacing before cards
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.04,
                      ),

                      // Organization cards
                      _buildOrganizationCard(
                        "Ngee Ann",
                        NgeeAnnBusData(),
                        context,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      _buildOrganizationCard("Organization 2", Org1(), context),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      _buildOrganizationCard("Organization 3", Org2(), context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === Sliding side menu ===
          SlideTransition(
            position: _slideAnimation, // Controls slide-in animation
            child: Container(
              width: MediaQuery.of(context).size.width * 0.33, // Menu width
              color: Color(0xff002345), // Menu background color
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),

                  // Account navigation tile
                  ListTile(
                    leading: Icon(
                      Icons.account_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 30,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AccountPage(), // Navigate to AccountPage
                        ),
                      );
                    },
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.008),

                  // Settings navigation tile
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      size: 40,
                      color: Colors.white,
                    ),
                    title: Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 30,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingsPage(), // Navigate to SettingsPage
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds a tappable card for each organization
  Widget _buildOrganizationCard(
    String name, // Display name of the organization
    Widget page, // Page to navigate to on tap
    BuildContext context,
  ) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // Card width
        child: Card(
          color: Color(0xff014689), // Card background color
          child: ListTile(
            title: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      page, // Navigate to the page passed as parameter
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

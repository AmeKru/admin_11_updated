import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:admin_11_updated/pages/Account_Page.dart';
import 'package:admin_11_updated/pages/NP.dart';
import 'package:admin_11_updated/pages/Org1.dart';
import 'package:admin_11_updated/pages/Org2.dart';

class Main_Page extends StatefulWidget {
  const Main_Page({super.key});

  @override
  State<Main_Page> createState() => _Main_PageState();
}

class _Main_PageState extends State<Main_Page> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      if (_isMenuOpen) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      _isMenuOpen = !_isMenuOpen;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content of the page
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.yellow[400], // Background color of the container
                  padding: const EdgeInsets.fromLTRB(0, 15, 0, 30), // Padding around the content
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu, size: 50),
                            onPressed: _toggleMenu, // Toggle menu on button press
                          ),
                        ],
                      ),
                      Center(
                        child: Text(
                          "MooBus Admin App",
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                          Text(
                            'Choose organization to administrate:',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      _buildOrganizationCard("Ngee Ann", NgeeAnnBusData(), context),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      _buildOrganizationCard("Organization 2", Org1(), context),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      _buildOrganizationCard("Organization 3", Org2(), context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sliding menu: Now only for account and settings
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.33,
              color: Colors.grey[300],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 0, 0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, size: 40),
                      onPressed: _toggleMenu, // Close menu when pressed
                      tooltip: 'Back',
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                  ListTile(
                    leading: Icon(Icons.account_circle, size: 50),
                    title: Text("Account",
                      style: TextStyle(
                        fontSize: 30,
                        fontFamily: 'Playfair',
                        fontWeight: FontWeight.w900
                      )
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Account_Page(), // Navigate to AccountPage
                        ),
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                  ListTile(
                    leading: Icon(Icons.settings, size: 50),
                    title: Text("Settings",
                        style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Playfair',
                            fontWeight: FontWeight.w900
                        )),
                    onTap: () {
                      // Add navigation or action for Settings
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

  Widget _buildOrganizationCard(String name, Widget page, BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6, // Set the width of the card
        height: 100,
        child: Card(
          color: Colors.red[100],
          elevation: 4,
          child: ListTile(
            title: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Aboreto',
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => page, // Navigate to the page passed as parameter
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}

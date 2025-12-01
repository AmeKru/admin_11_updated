// Import service widgets for each section of the bus data page
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/text_sizing.dart';
import 'announcements.dart';
import 'bus_stops.dart';
import 'export_data.dart';
import 'timings.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Ngee Ann page ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// NgeeAnnBusData class

// Main page for displaying Ngee Ann Polytechnic bus data
class NgeeAnnBusData extends StatefulWidget {
  const NgeeAnnBusData({super.key});

  @override
  State<NgeeAnnBusData> createState() => _NgeeAnnBusDataState();
}

class _NgeeAnnBusDataState extends State<NgeeAnnBusData> {
  //////////////////////////////////////////////////////////////////////////////
  // Variables

  // Scroll controller for potential scrollable content (currently unused)
  final ScrollController controller = ScrollController();

  // Optional filters (currently unused in this snippet)
  String? selectedMRT;
  String? selectedBusStop;

  // Tracks which section is currently selected:
  // 1 = KAP Timing, 2 = CLE Timing, 3 = Bus Stops, 4 = News, 5 = Download/Table
  int selectedBox = 1;

  //////////////////////////////////////////////////////////////////////////////
  // dispose

  @override
  void dispose() {
    // Dispose of any controllers or resources here if needed
    super.dispose();
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Some functions ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Updates the selected section and triggers a rebuild
  void updateSelectedBox(int box) {
    setState(() {
      selectedBox = box;
    });
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Section builder methods for cleaner code
  Widget _buildTable() => TableExport();
  Widget _buildKAPTiming() => TimingScreen(station: 'KAP');
  Widget _buildCLETiming() => TimingScreen(station: 'CLE');
  Widget _buildBusStops() => BusStop();
  Widget _buildNewsAnnouncement() => AnnouncementsPage();

  // Formats a DateTime as HH:mm
  String formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Formats a DateTime as HH:mm:ss
  String formatTimeSecond(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    String sec = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$sec';
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Main Build function ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // build

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Ngee Ann page built');
    }
    return Scaffold(
      backgroundColor: Colors.blue[50],
      // === AppBar ===
      appBar: AppBar(
        toolbarHeight: TextSizing.fontSizeHeading(context) * 2.5,
        centerTitle: true,
        backgroundColor: Color(0xff014689),

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

        // logo on the right
        actions: [
          ClipOval(
            child: Image.asset(
              'images/np_logo.png',
              width: TextSizing.fontSizeHeading(context),
              height: TextSizing.fontSizeHeading(context),
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: TextSizing.fontSizeText(context),
            height: TextSizing.fontSizeHeading(context),
          ),
        ],

        // title
        title: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Ngee Ann Bus Data',
                    maxLines: 1, //  limits to 1 lines
                    overflow:
                        TextOverflow.ellipsis, // clips text if not fitting
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: TextSizing.fontSizeHeading(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // === Body ===
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          TextSizing.fontSizeMiniText(context),
          TextSizing.fontSizeMiniText(context),
          TextSizing.fontSizeMiniText(context),
          TextSizing.fontSizeMiniText(context),
        ),
        child: Column(
          children: [
            // === First Row: Timing selection buttons (KAP, CLE, Bus Stops) ===
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KAP Timing Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(1); // Switch to KAP Timing
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: TextSizing.fontSizeHeading(context) * 1.75,
                      curve: Curves.easeOutCubic, // Smooth animation curve
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                        child: Container(
                          // Highlight if selected, otherwise light blue
                          color: selectedBox == 1
                              ? Color(0xff014689)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                            ),
                            child: Center(
                              child: Text(
                                'KAP Timing',
                                maxLines: 1, //  limits to 1 lines
                                overflow: TextOverflow
                                    .ellipsis, // clips text if not fitting
                                style: TextStyle(
                                  color: selectedBox == 1
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                  fontSize: TextSizing.fontSizeHeading(context),
                                  fontFamily: 'Roboto',
                                  fontWeight: selectedBox == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: TextSizing.fontSizeMiniText(context),
                ), // Space between buttons
                // CLE Timing Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(2); // Switch to KAP Timing
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: TextSizing.fontSizeHeading(context) * 1.75,
                      curve: Curves.easeOutCubic, // Smooth animation curve
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                        child: Container(
                          // Highlight if selected, otherwise light blue
                          color: selectedBox == 2
                              ? Color(0xff014689)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                            ),
                            child: Center(
                              child: Text(
                                'CLE Timing',
                                maxLines: 1, //  limits to 1 lines
                                overflow: TextOverflow
                                    .ellipsis, // clips text if not fitting
                                style: TextStyle(
                                  color: selectedBox == 2
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                  fontSize: TextSizing.fontSizeHeading(context),
                                  fontFamily: 'Roboto',
                                  fontWeight: selectedBox == 2
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  width: TextSizing.fontSizeMiniText(context),
                ), // Space between buttons
                // Bus Stops Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(3); // Switch to KAP Timing
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: TextSizing.fontSizeHeading(context) * 1.75,
                      curve: Curves.easeOutCubic, // Smooth animation curve
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                        child: Container(
                          // Highlight if selected, otherwise light blue
                          color: selectedBox == 3
                              ? Color(0xff014689)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                            ),
                            child: Center(
                              child: Text(
                                'Bus Stops',
                                maxLines: 1, //  limits to 1 lines
                                overflow: TextOverflow
                                    .ellipsis, // clips text if not fitting
                                style: TextStyle(
                                  color: selectedBox == 3
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                  fontSize: TextSizing.fontSizeHeading(context),
                                  fontFamily: 'Roboto',
                                  fontWeight: selectedBox == 3
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // === Second Row: News & Download Section ===
            SizedBox(
              height: TextSizing.fontSizeMiniText(context),
            ), // Add some spacing between rows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // News Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(4); // Switch to Announcements
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: TextSizing.fontSizeHeading(context) * 1.75,
                      curve: Curves.easeOutCubic, // Smooth animation curve
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                        child: Container(
                          // Highlight if selected, otherwise light blue
                          color: selectedBox == 4
                              ? Color(0xff014689)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                            ),
                            child: Center(
                              child: Text(
                                'Announcements',
                                maxLines: 1, //  limits to 1 lines
                                overflow: TextOverflow
                                    .ellipsis, // clips text if not fitting
                                style: TextStyle(
                                  color: selectedBox == 4
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                  fontSize: TextSizing.fontSizeHeading(context),
                                  fontFamily: 'Roboto',
                                  fontWeight: selectedBox == 4
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Space between News and Download buttons
                SizedBox(width: TextSizing.fontSizeMiniText(context)),

                // Download Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(5); // Switch to Download
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: TextSizing.fontSizeHeading(context) * 1.75,
                      curve: Curves.easeOutCubic, // Smooth animation curve
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                        child: Container(
                          // Highlight if selected, otherwise light blue
                          color: selectedBox == 5
                              ? Color(0xff014689)
                              : Colors.white,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                              TextSizing.fontSizeText(context) * 0.5,
                              0,
                            ),
                            child: Center(
                              child: Text(
                                'Download',
                                maxLines: 1, //  limits to 1 lines
                                overflow: TextOverflow
                                    .ellipsis, // clips text if not fitting
                                style: TextStyle(
                                  color: selectedBox == 5
                                      ? Colors.white
                                      : Colors.blueGrey[800],
                                  fontSize: TextSizing.fontSizeHeading(context),
                                  fontFamily: 'Roboto',
                                  fontWeight: selectedBox == 5
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(
              height: TextSizing.fontSizeMiniText(context),
            ), // Space before content section
            // === Content section based on selected item ===
            Expanded(
              child: IndexedStack(
                // Show the widget corresponding to the selectedBox value
                // selectedBox starts at 1, so subtract 1 for zero-based index
                index: selectedBox - 1,
                children: [
                  _buildKAPTiming(), // Index 0 → KAP Timing
                  _buildCLETiming(), // Index 1 → CLE Timing
                  _buildBusStops(), // Index 2 → Bus Stops
                  _buildNewsAnnouncement(), // Index 3 → News
                  _buildTable(), // Index 4 → Download/Table Export
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:admin_11_updated/API_Services/BusStops.dart';
import 'package:admin_11_updated/API_Services/CLE_Timing.dart';
import 'package:admin_11_updated/API_Services/KAP_Timing.dart';
import 'package:admin_11_updated/API_Services/News.dart';
import 'package:admin_11_updated/pages/Table_Export.dart';
import 'package:flutter/material.dart';

class NgeeAnnBusData extends StatefulWidget {
  const NgeeAnnBusData({super.key});

  @override
  State<NgeeAnnBusData> createState() => _NgeeAnnBusDataState();
}

class _NgeeAnnBusDataState extends State<NgeeAnnBusData> {
  final ScrollController controller = ScrollController();
  String? selectedMRT;
  String? selectedBusStop;
  int selectedBox = 1;

  void updateSelectedBox(int box) {
    setState(() {
      selectedBox = box;
    });
  }

  Widget _buildTable() {
    return TableExport();
  }

  Widget _buildKAPTiming() {
    return KAP_Timing();
  }

  Widget _buildCLETiming() {
    return CLE_Timing();
  }

  Widget _buildBusStops() {
    return BusStop();
  }

  Widget _buildNewsAnnouncement() {
    return News_Page();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatTimesecond(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    String sec = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$sec';
  }

  List<DataRow> _generateRows(List<DateTime> busTimes) {
    List<DataRow> rows = [];
    for (int i = 0; i < busTimes.length; i += 2) {
      DateTime time1 = busTimes[i];
      DateTime time2 = (i + 1 < busTimes.length)
          ? busTimes[i + 1]
          : DateTime.now(); // Fallback if there's no second entry

      rows.add(
        DataRow(
          cells: [
            DataCell(
              TextButton(onPressed: () {}, child: Text('Trip ${i + 1}')),
            ),
            DataCell(Text(formatTime(time1))),
            DataCell(
              TextButton(onPressed: () {}, child: Text('Trip ${i + 2}')),
            ),
            DataCell(Text(formatTime(time2))),
          ],
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[500],
        title: Text(
          'Ngee Ann Bus Data',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontSize: 40,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 40),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 30, 15, 0),
        child: Column(
          children: [
            // First Row: Timing selection buttons (KAP, CLE, Bus Stops)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(1);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: selectedBox == 1 ? 100 : 50,
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: selectedBox == 1
                              ? Colors.amber[500]
                              : Colors.grey,
                          child: Center(
                            child: Text(
                              'KAP Timing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontFamily: 'Tomorrow',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(2);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: selectedBox == 2 ? 100 : 50,
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: selectedBox == 2
                              ? Colors.amber[500]
                              : Colors.grey,
                          child: Center(
                            child: Text(
                              'CLE Timing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontFamily: 'Tomorrow',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(3);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: selectedBox == 3 ? 100 : 50,
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: selectedBox == 3
                              ? Colors.amber[500]
                              : Colors.grey,
                          child: Center(
                            child: Text(
                              'Bus Stops',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontFamily: 'Tomorrow',
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

            // Second Row: News Announcement Section
            SizedBox(height: 20), // Add some spacing between rows
            Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(4);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: selectedBox == 4 ? 100 : 50,
                      width: MediaQuery.of(context).size.width * 0.3,
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: selectedBox == 4
                              ? Colors.amber[500]
                              : Colors.grey,
                          child: Center(
                            child: Text(
                              'News ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontFamily: 'Tomorrow',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      updateSelectedBox(5);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: selectedBox == 5 ? 100 : 50,
                      width: MediaQuery.of(context).size.width * 0.3,
                      curve: Curves.easeOutCubic,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          color: selectedBox == 5
                              ? Colors.amber[500]
                              : Colors.grey,
                          child: Center(
                            child: Text(
                              'Download',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontFamily: 'Tomorrow',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.2),
              ],
            ),

            // Content section based on selected item
            Expanded(
              child: IndexedStack(
                index: selectedBox - 1,
                children: [
                  _buildKAPTiming(),
                  _buildCLETiming(),
                  _buildBusStops(),
                  _buildNewsAnnouncement(),
                  _buildTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

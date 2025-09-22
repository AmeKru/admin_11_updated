import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BusStop extends StatefulWidget {
  const BusStop({super.key});

  @override
  State<BusStop> createState() => _BusStopState();
}

class _BusStopState extends State<BusStop> {
  List<String> busStops = [];
  List<String> busStopsPositions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<dynamic> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PATCH':
          response = await http.patch(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Invalid HTTP method');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed request with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during HTTP request: $e');
      }
      rethrow;
    }
  }

  Future<void> getBusStops() async {
    try {
      busStops.clear();
      busStopsPositions.clear();

      var data = await _makeRequest(
        'GET',
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop?info=BusStops',
      );

      if (kDebugMode) {
        print("Raw data from API: $data");
      }

      if (data is Map && data.containsKey('positions')) {
        List<dynamic> positions = data['positions'];

        for (var position in positions) {
          String busStopId = position['id'];
          List<dynamic> pos = position['pos'];
          String busStopPos = '${pos[0]}, ${pos[1]}';

          busStops.add(busStopId);
          busStopsPositions.add(busStopPos);
        }

        if (kDebugMode) {
          print("Bus Stops captured: $busStops");
          print("Bus Stops positions captured: $busStopsPositions");
        }
      } else {
        if (kDebugMode) {
          print("Unexpected data format: $data");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in getBusStops: $e");
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    await Future.wait([getBusStops()]);
  }

  List<DataRow> _generateRows(
    List<String> busStops,
    List<String> busStopPositions,
  ) {
    List<DataRow> rows = [];
    for (int i = 0; i < busStops.length; i++) {
      rows.add(
        DataRow(
          cells: [
            // First column cell
            DataCell(
              Container(
                // Background color for this cell
                color: Color(0xff014689),
                // Make sure the container fills the cell
                width: double.infinity,
                //padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                    _showStopOptionsDialog(context, busStops[i]);
                    if (kDebugMode) {
                      print(busStops[i]);
                    }
                  },
                  child: Text(
                    busStops[i],
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Second column cell
            DataCell(
              Container(
                color: Colors.blue[100],
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  busStopPositions.length > i ? busStopPositions[i] : '',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return rows;
  }

  Future<void> _deleteStop(String busStop) async {
    setState(() {
      _isLoading = true; // Set loading to true before starting the deletion
    });

    try {
      await deleteData('BusStops', 'positions', busStop);
      await _loadData(); // Refresh data
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting trip: $e');
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String busStop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: TextStyle(fontSize: 35)),
          content: Text(
            'Are you sure you want to delete this stop?',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                await _deleteStop(busStop); // Perform the deletion
              },
              child: Text(
                'Yes',
                style: TextStyle(fontSize: 20, color: Colors.red[700]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: Text(
                'No',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModifyDialog(BuildContext context, String busStop) {
    final TextEditingController latController = TextEditingController();
    final TextEditingController langController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        /// CHANGE: renamed to dialogContext to avoid shadowing outer context
        return AlertDialog(
          title: Text(
            'Modify $busStop',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latController,
                decoration: InputDecoration(labelText: 'New Lat'),
              ),
              TextFormField(
                controller: langController,
                decoration: InputDecoration(labelText: 'New Lang'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xff014689))),
            ),
            TextButton(
              onPressed: () async {
                /// CHANGE: Capture Navigator before any await
                final navigator = Navigator.of(dialogContext);

                if ((latController.text).isNotEmpty &&
                    (langController.text).isNotEmpty) {
                  await patchData(
                    'BusStops',
                    'positions',
                    busStop,
                    latController.text,
                    langController.text, // Format as a string
                  );

                  await _loadData(); // Refresh data
                }

                /// CHANGE: Use pre-captured navigator instead of Navigator.of(context) after await
                navigator.pop();
              },
              child: Text('Submit', style: TextStyle(color: Color(0xff014689))),
            ),
          ],
        );
      },
    );
  }

  void _showStopOptionsDialog(BuildContext context, String busStop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Data Options',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Would you like to modify or delete this stop?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showModifyDialog(context, busStop);
              },
              child: Text('Modify', style: TextStyle(color: Color(0xff014689))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(context, busStop);
              },
              child: Text('Delete', style: TextStyle(color: Color(0xff014689))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Color(0xff014689))),
            ),
          ],
        );
      },
    );
  }

  void _showAddStopDialog(BuildContext context) {
    final TextEditingController latController = TextEditingController();
    final TextEditingController langController = TextEditingController();
    final TextEditingController stopController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        /// CHANGE: renamed to dialogContext to avoid shadowing outer context
        return AlertDialog(
          title: Text(
            'Add New Stop',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: stopController,
                  decoration: InputDecoration(labelText: 'New Stop'),
                ),
                TextFormField(
                  controller: latController,
                  decoration: InputDecoration(labelText: 'Latitude'),
                ),
                TextFormField(
                  controller: langController,
                  decoration: InputDecoration(labelText: 'Longitude'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xff014689)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    /// CHANGE: Capture Navigator before any await
                    final navigator = Navigator.of(dialogContext);

                    String lat = latController.text;
                    String lang = langController.text;
                    String stop = stopController.text;

                    if (lat.isNotEmpty && lang.isNotEmpty && stop.isNotEmpty) {
                      await submitStop(stop, lat, lang);
                      await _loadData(); // Refresh data
                      /// CHANGE: Use pre-captured navigator instead of Navigator.of(context) after await
                      navigator.pop();
                    }
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Color(0xff014689)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> submitStop(String stop, String lat, String lng) async {
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop',
    );
    final data = {
      'info': 'BusStops',
      'updateKey': 'positions',
      'id': stop,
      'newStop': [double.parse(lat), double.parse(lng)],
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Success: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  Future<void> patchData(
    String info,
    String updateKey,
    String id,
    String newLat,
    String newLang,
  ) async {
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop',
    );

    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
      'id': id,
      'newStop': [double.parse(newLat), double.parse(newLang)],
    });

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Data modified successfully: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Failed to modify data. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error modifying data: $error');
      }
    }
  }

  Future<void> deleteData(String info, String updateKey, String id) async {
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop',
    ); // Replace with your actual API endpoint

    final body = jsonEncode({'info': info, 'updateKey': updateKey, 'id': id});

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_AUTH_TOKEN', // Optional: include if your API requires authorization
        },
        body: body,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Data deleted successfully: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Failed to delete data. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error deleting data: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bus Stops and Positions',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: DataTable(
                          columns: [
                            DataColumn(
                              label: Text(
                                'Bus Stop',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  fontSize: 20,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Position [Lat, Lng]',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  fontSize: 20,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                            ),
                          ],
                          rows: _generateRows(busStops, busStopsPositions),
                          columnSpacing: 24.0,
                          headingRowHeight: 56.0,
                          border: TableBorder.all(
                            color: Colors.white, // Change to white
                            width: 6.0, // Make all lines thicker
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddStopDialog(context);
                      },
                      icon: Icon(Icons.add, color: Color(0xff014689)),
                      label: Text(
                        'Add New Stop',
                        style: TextStyle(color: Color(0xff014689)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

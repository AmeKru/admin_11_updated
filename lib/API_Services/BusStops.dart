import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BusStop extends StatefulWidget {
  const BusStop({super.key});

  @override
  State<BusStop> createState() => _BusStopState();
}

class _BusStopState extends State<BusStop> {
  List<String> BusStops = [];
  List<String> BusStopsPositions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<dynamic> _makeRequest(String method, String url, {Map<String, String>? headers, dynamic body}) async {
    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(Uri.parse(url), headers: headers, body: jsonEncode(body));
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
      print('Error during HTTP request: $e');
      rethrow;
    }
  }

  Future<void> getBusStops() async {
    try {
      BusStops.clear();
      BusStopsPositions.clear();

      var data = await _makeRequest(
          'GET',
          'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop?info=BusStops'
      );

      print("Raw data from API: $data");

      if (data is Map && data.containsKey('positions')) {
        List<dynamic> positions = data['positions'];

        for (var position in positions) {
          String busStopId = position['id'];
          List<dynamic> pos = position['pos'];
          String busStopPos = '${pos[0]}, ${pos[1]}';

          BusStops.add(busStopId);
          BusStopsPositions.add(busStopPos);
        }

        print("Bus Stops captured: $BusStops");
        print("Bus Stops positions captured: $BusStopsPositions");
      } else {
        print("Unexpected data format: $data");
      }
    } catch (e) {
      print("Error in getBusStops: $e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
    getBusStops()
    ]);
  }

  List<DataRow> _generateRows(List<String> busStops, List<String> busStopPositions) {
    List<DataRow> rows = [];
    for (int i = 0; i < busStops.length; i++) {
      rows.add(DataRow(cells: [
        DataCell(
          TextButton(
            onPressed: () { _showStopOptionsDialog(context, busStops[i]);
            print(busStops[i]);  },
            child: Text(busStops[i], style: TextStyle(
                fontSize: 20,
                color: Colors.deepPurple
            ),),
          ),
        ),
        DataCell(Text(busStopPositions.length > i ? busStopPositions[i] : '', style: TextStyle(
            fontSize: 20,
        ),)),
      ]));
    }
    return rows;
  }

  Future<void> _deleteStop(String busstop) async {
      setState(() {
        _isLoading = true; // Set loading to true before starting the deletion
      });

    try {
      await deleteData(
        'BusStops',
        'positions',
        busstop,
      );
      await _loadData(); // Refresh data
    } catch (e) {
      print('Error deleting trip: $e');
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String busStop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: TextStyle(fontSize: 35)),
          content: Text('Are you sure you want to delete this stop?', style: TextStyle(fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog
                await _deleteStop(busStop); // Perform the deletion
              },
              child: Text('Yes', style: TextStyle(fontSize: 20, color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: Text('No', style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
            ),
          ],
        );
      },
    );
  }

  void _showModifyDialog(BuildContext context, String busstop) {
    final TextEditingController latController = TextEditingController();
    final TextEditingController langController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modify ${busstop}', style: TextStyle(
              fontSize: 35
          ),),
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
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple
              ),),
            ),
            TextButton(
              onPressed: () async {
                if ((latController.text).isNotEmpty && (langController.text).isNotEmpty) {

                  await patchData(
                      'BusStops',
                      'positions',
                      busstop,
                      latController.text,
                    langController.text// Format as a string
                  );

                  await _loadData(); // Refresh data
                }
                Navigator.of(context).pop();
              },
              child: Text('Submit', style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple
              ),),
            ),
          ],
        );
      },
    );
  }

  void _showStopOptionsDialog(BuildContext context, String busstop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Data Options', style: TextStyle(
              fontSize: 35
          ),),
          content: Text('Would you like to modify or delete this stop?', style: TextStyle(
              fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showModifyDialog(context, busstop);
              },
              child: Text('Modify', style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple
              ),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(context, busstop);
              },
              child: Text('Delete', style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple
              ),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(
                  fontSize: 20,
                  color: Colors.deepPurple
              ),),
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
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Stop'),
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
                  decoration: InputDecoration(labelText: 'Longtitude'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String lat = latController.text;
                    String lang = langController.text;
                    String stop = stopController.text;

                    if (lat.isNotEmpty && lang.isNotEmpty && stop.isNotEmpty) {
                      await submitStop(stop, lat, lang);
                      await _loadData(); // Refresh data
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> submitStop(String stop, String lat, String lng) async {
    final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop');
    final data = {
      'info': 'BusStops',
      'updateKey': 'positions',
      'id': stop,
      'newStop': [double.parse(lat), double.parse(lng)],
    };
    try {
      final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        print('Success: ${response.body}');
      } else {
        print('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> patchData(String info, String updateKey, String id, String newlat, String newlang) async {
    final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop');

    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
      'id': id,
      'newStop': [double.parse(newlat), double.parse(newlang)],
    });

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Data modified successfully: ${response.body}');
      } else {
        print('Failed to modify data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error modifying data: $error');
    }
  }

  Future<void> deleteData(String info, String updateKey, String id) async {
    final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop'); // Replace with your actual API endpoint

    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
      'id': id,
    });

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN' // Optional: include if your API requires authorization
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Data deleted successfully: ${response.body}');
      } else {
        print('Failed to delete data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error deleting data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Bus Stops and Positions',style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Aboreto'
              ),
              ),
              SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: DataTable(
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Bus Stop',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontFamily: 'NewAmsterdam',
                              //fontWeight: FontWeight.bold,
                              fontSize: 35
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Position [Lat, Lng]',
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontFamily: 'NewAmsterdam',
                              //fontWeight: FontWeight.bold,
                              fontSize: 35
                          ),
                        ),
                      ),
                    ],
                    rows: _generateRows(BusStops, BusStopsPositions),
                    columnSpacing: 24.0,
                    dataRowHeight: 60.0,
                    headingRowHeight: 56.0,
                    border: TableBorder.all(color: Colors.black, width: 1.0),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _showAddStopDialog(context);
                },
                icon: Icon(Icons.add),
                label: Text('Add New Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
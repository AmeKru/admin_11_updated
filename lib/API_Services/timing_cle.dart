import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/format_time.dart';

class TimingCLE extends StatefulWidget {
  const TimingCLE({super.key});

  @override
  State<TimingCLE> createState() => _TimingCLEState();
}

class _TimingCLEState extends State<TimingCLE> {
  List<BusTimings> morningCLE = [];
  List<BusTimings> afternoonCLE = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data when the widget is first built
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

  Future<void> getMorningBusCLE() async {
    try {
      setState(() {
        _isLoading = true;
      });
      morningCLE.clear(); // Clear existing data
      var data = await _makeRequest(
        'GET',
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing?info=CLE_MorningBus',
      );
      // var data = await _makeRequest('GET', 'https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/timing?info=CLE_MorningBus');
      if (kDebugMode) {
        print("Raw data from API: $data");
      }

      if (data is Map && data.containsKey('times')) {
        // List<dynamic> times = data['times']['L'];
        // for (var timeData in times) {
        //   String timeStr = timeData['M']['time']['S'];
        //   String id = timeData['M']['id']['S'];
        List<dynamic> times = data['times'];
        for (var timeData in times) {
          String timeStr = timeData['time'];
          String id = timeData['id'];
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          morningCLE.add(
            BusTimings(
              id: id,
              time: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                hour,
                minute,
              ),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print("Unexpected data format: $data");
        }
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Error in getCLE_MorningBus: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getAfternoonBusCLE() async {
    try {
      setState(() {
        _isLoading = true;
      });
      afternoonCLE.clear(); // Clear existing data
      // var data = await _makeRequest('GET', 'https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/timing?info=CLE_AfternoonBus');
      var data = await _makeRequest(
        'GET',
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing?info=CLE_AfternoonBus',
      );
      if (kDebugMode) {
        print("Raw data from API: $data");
      }

      if (data is Map && data.containsKey('times')) {
        // List<dynamic> times = data['times']['L'];
        // for (var timeData in times) {
        //   String timeStr = timeData['M']['time']['S'];
        //   String id = timeData['M']['id']['S'];
        List<dynamic> times = data['times'];
        for (var timeData in times) {
          String timeStr = timeData['time'];
          String id = timeData['id'];
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          afternoonCLE.add(
            BusTimings(
              id: id,
              time: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                hour,
                minute,
              ),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print("Unexpected data format: $data");
        }
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Error in getCLE_AfternoonBus: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    await Future.wait([getMorningBusCLE(), getAfternoonBusCLE()]);
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    String info,
    BusTimings timing,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: TextStyle(fontSize: 35)),
          content: Text(
            'Are you sure you want to delete this trip?',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTrip(timing, info);
              },
              child: Text(
                'Yes',
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  Future<void> _deleteTrip(BusTimings timing, String info) async {
    try {
      await deleteData(info, 'times', timing.id);
      await _loadData(); // Refresh data
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting trip: $e');
      }
    }
  }

  void _showModifyDialog(BuildContext context, String info, BusTimings timing) {
    final TextEditingController timeController = TextEditingController(
      text: formatTime(timing.time),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Modify Trip ${timing.id}',
            style: TextStyle(fontSize: 35),
          ),
          content: TextFormField(
            controller: timeController,
            decoration: InputDecoration(labelText: 'New Time'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
            TextButton(
              onPressed: () async {
                String newTime = timeController.text;

                if (newTime.isNotEmpty) {
                  await patchData(info, 'times', timing.id, newTime);
                  await _loadData();
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Submit',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTripOptionsDialog(
    BuildContext context,
    String info,
    BusTimings timing,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Data Options', style: TextStyle(fontSize: 35)),
          content: Text(
            'Would you like to modify or delete this trip?',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showModifyDialog(context, info, timing);
              },
              child: Text(
                'Modify',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(context, info, timing);
              },
              child: Text(
                'Delete',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 20, color: Color(0xff014689)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTripDialog(
    BuildContext context,
    String partitionKey,
    String column,
  ) {
    final TextEditingController tripNoController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Trip'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: tripNoController,
                  decoration: InputDecoration(labelText: 'Trip No'),
                ),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Time'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String tripNo = tripNoController.text;
                    String time = timeController.text;

                    if (tripNo.isNotEmpty && time.isNotEmpty) {
                      await submitForm(partitionKey, column, tripNo, time);
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

  // Future<void> submitForm(String info, String updateKey, String id, String newTime) async {
  //   // final url = Uri.parse('https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/timing');
  //   final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing');
  //   final data = {
  //     // 'info': info,
  //     'info': {'S': info},
  //     // 'updateKey': updateKey,
  //     'updateKey': {'L': updateKey},
  //     // 'id': id,
  //     // 'newTime': newTime,
  //     'id': {'S': id},
  //     'newTime': {'S': newTime}
  //
  //     //
  //   };
  //   try {
  //     final response = await http.post(url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode(data),
  //     );
  //     if (response.statusCode == 200) {
  //       print('Success: ${response.body}');
  //     } else {
  //       print(data);
  //       print('Failed: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  Future<void> submitForm(
    String info,
    String updateKey,
    String id,
    String newTime,
  ) async {
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing',
    );

    final data = {
      'info': info, // Just send a string, not an object
      'updateKey': updateKey,
      'id': id,
      'newTime': newTime,
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
          print('Failed: ${response.statusCode},${response.body}');
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
    String newTime,
  ) async {
    // final url = Uri.parse('https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/timing');
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing',
    );
    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
      'id': id,
      'newTime': newTime,
    });

    try {
      // Send the PATCH request
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Check the status code and handle the response
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
    // final url = Uri.parse('https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/timing');
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing',
    );

    final body = jsonEncode({'info': info, 'updateKey': updateKey, 'id': id});

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN',
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

  List<DataRow> _generateRows(List<BusTimings> busTimings, String info) {
    List<DataRow> rows = [];
    for (int i = 0; i < busTimings.length; i += 2) {
      BusTimings timing1 = busTimings[i];
      BusTimings? timing2 = (i + 1 < busTimings.length)
          ? busTimings[i + 1]
          : null;

      rows.add(
        DataRow(
          cells: [
            DataCell(
              TextButton(
                onPressed: () => _showTripOptionsDialog(context, info, timing1),
                child: Text(
                  'Trip ${timing1.id}',
                  style: TextStyle(fontSize: 20, color: Color(0xff014689)),
                ),
              ),
            ),
            DataCell(
              Text(formatTime(timing1.time), style: TextStyle(fontSize: 20)),
            ),
            DataCell(
              timing2 != null
                  ? TextButton(
                      onPressed: () =>
                          _showTripOptionsDialog(context, info, timing2),
                      child: Text(
                        'Trip ${timing2.id}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xff014689),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            DataCell(
              timing2 != null
                  ? Text(
                      formatTime(timing2.time),
                      style: TextStyle(fontSize: 20),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return rows;
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
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Center(
                      child: Text(
                        'CLE Morning Bus',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.015,
                    ),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Trip No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Trip No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                          rows: _generateRows(morningCLE, 'CLE_MorningBus'),
                          columnSpacing: 24.0,
                          headingRowHeight: 56.0,
                          border: TableBorder.all(
                            color: Colors.black,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddTripDialog(context, 'CLE_MorningBus', 'times');
                      },
                      icon: Icon(Icons.add),
                      label: Text(
                        'Add New Trip',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xff014689),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Center(
                      child: Text(
                        'CLE Afternoon Bus',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.015,
                    ),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Trip No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Trip No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',

                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                          rows: _generateRows(afternoonCLE, 'CLE_AfternoonBus'),
                          columnSpacing: 24.0,
                          headingRowHeight: 56.0,
                          border: TableBorder.all(
                            color: Colors.black,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddTripDialog(
                          context,
                          'CLE_AfternoonBus',
                          'times',
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text(
                        'Add New Trip',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xff014689),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class BusTimings {
  final String id;
  final DateTime time;

  BusTimings({required this.id, required this.time});
}

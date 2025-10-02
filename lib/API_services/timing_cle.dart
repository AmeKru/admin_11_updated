import 'dart:convert';

import 'package:admin_11_updated/utils/format_time.dart';
import 'package:admin_11_updated/utils/text_sizing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  //////////////////////////////////////////////////////////////////////////////
  // Get Bus Trips and Times from Server

  Future<void> _fetchCleBusTimings({
    required String infoQueryValue,
    required List<BusTimings> targetList,
  }) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      targetList.clear();

      final uri = Uri.parse(
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/timing?info=$infoQueryValue',
      );
      final data = await _makeRequest('GET', uri.toString());

      if (kDebugMode) print('Raw data for $infoQueryValue: $data');

      if (data is! Map || !data.containsKey('times')) {
        if (kDebugMode) {
          print('Unexpected data format for $infoQueryValue: $data');
        }
        return;
      }

      final List<dynamic> times = data['times'] is List
          ? List.from(data['times'])
          : [];

      for (var idx = 0; idx < times.length; idx++) {
        final timeData = times[idx];
        try {
          if (timeData == null || timeData is! Map) {
            if (kDebugMode) {
              print('Skipping non-map time entry at $idx: $timeData');
            }
            continue;
          }

          final dynamic timeRaw = timeData['time'] ?? timeData['Time'];
          final dynamic idRaw =
              timeData['id'] ?? timeData['Id'] ?? timeData['ID'];

          if (timeRaw == null) {
            if (kDebugMode) {
              print('Skipping entry with missing time at $idx: $timeData');
            }
            continue;
          }

          final timeStr = timeRaw.toString().trim();

          // Accept formats like:
          // "10" => treated as "10:00"
          // "7:00", "07:00", "07:00:00"
          // "1000" is NOT parsed here; prefer "10" or "10:00"
          final timeParts = timeStr
              .split(':')
              .where((p) => p.trim().isNotEmpty)
              .toList();

          int? hour;
          int? minute;

          if (timeParts.length == 1) {
            // Single value, interpret as hour only
            final single = timeParts[0].trim();
            // Allow "10" or "09" etc.
            hour = int.tryParse(single);
            minute = 0;
          } else if (timeParts.length >= 2) {
            hour = int.tryParse(timeParts[0].trim());
            minute = int.tryParse(timeParts[1].trim());
          } else {
            if (kDebugMode) {
              print('Skipping unparsable time "$timeStr" at index $idx');
            }
            continue;
          }

          if (hour == null || minute == null) {
            if (kDebugMode) {
              print('Skipping invalid hour/minute for "$timeStr" at $idx');
            }
            continue;
          }

          // normalize hour/minute bounds
          if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            if (kDebugMode) {
              print('Skipping out-of-range time "$timeStr" at $idx');
            }
            continue;
          }

          final id = idRaw != null ? idRaw.toString() : 'idx_$idx';

          targetList.add(
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
        } catch (itemErr, st) {
          if (kDebugMode) {
            print('Error parsing time entry at index $idx: $itemErr');
            print(st);
          }
        }
      }

      if (kDebugMode) {
        print('Parsed ${targetList.length} timings for $infoQueryValue');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Error fetching timings for $infoQueryValue: $e');
        print(st);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Get Morning Bus Trips and Times

  Future<void> getMorningBusCLE() async {
    await _fetchCleBusTimings(
      infoQueryValue: 'CLE_MorningBus',
      targetList: morningCLE,
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Get Afternoon Bus Trips and Times

  Future<void> getAfternoonBusCLE() async {
    await _fetchCleBusTimings(
      infoQueryValue: 'CLE_AfternoonBus',
      targetList: afternoonCLE,
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Load the Data

  Future<void> _loadData() async {
    await Future.wait([getMorningBusCLE(), getAfternoonBusCLE()]);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to delete the trip

  void _showDeleteConfirmationDialog(
    BuildContext context,
    String info,
    BusTimings timing,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Confirm Deletion',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this trip?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTrip(timing, info);
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.red[800],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Delete the Trip

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

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to modify selected Trip

  void _showModifyDialog(BuildContext context, String info, BusTimings timing) {
    final TextEditingController timeController = TextEditingController(
      text: formatTime(timing.time),
    );

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,

              title: Text(
                'Modify Trip ${timing.id}',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'New Time (e.g. 15 or 7:30)',
                        labelStyle: TextStyle(
                          color: Color(0xff014689),
                        ), // Label color
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff014689)),
                        ),
                      ),
                    ),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: TextSizing.fontSizeText(context),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Color(0xff014689),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Capture navigator and messenger before any await
                          final NavigatorState navigator = Navigator.of(
                            dialogContext,
                          );
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);

                          final String timeText = timeController.text.trim();

                          // Validate time and normalize
                          final DateTime? parsed = parseTimeInput(timeText);
                          if (parsed == null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text(
                                    'Invalid time. Only accepts formats such as "15" or "7:30"',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          final String normalizedTime =
                              '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';

                          setState(() => isSubmitting = true);

                          try {
                            // perform patch using normalized time
                            await patchData(
                              info,
                              'times',
                              timing.id,
                              normalizedTime,
                            );

                            // refresh local data
                            await _loadData();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(child: Text('Trip updated')),
                              ),
                            );
                            navigator.pop();
                          } catch (e, st) {
                            if (kDebugMode) {
                              print('Modify trip error: $e');
                              print(st);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text('Failed to update trip'),
                                ),
                              ),
                            );
                            // keep dialog open so user can retry or cancel
                          } finally {
                            if (mounted) setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: TextSizing.fontSizeText(context),
                          height: TextSizing.fontSizeText(context),
                          child: CircularProgressIndicator(
                            strokeWidth:
                                TextSizing.fontSizeMiniText(context) * 0.3,
                            color: Color(0xff014689),
                          ),
                        )
                      : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: TextSizing.fontSizeText(context),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            color: Color(0xff014689),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to edit/delete Trip

  void _showTripOptionsDialog(
    BuildContext context,
    String info,
    BusTimings timing,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Data Options',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),

          content: Text(
            'Would you like to modify or delete this trip?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Color(0xff014689),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmationDialog(context, info, timing);
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.red[800],
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showModifyDialog(context, info, timing);
              },
              child: Text(
                'Modify',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to add Trip

  // Modified dialog with validation and safe async usage
  void _showAddTripDialog(
    BuildContext context,
    String partitionKey,
    String column,
  ) {
    final TextEditingController tripNoController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use StatefulBuilder so we can update the dialog's local state (isSubmitting)
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              title: Text(
                'Add New Trip',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    TextFormField(
                      controller: tripNoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Trip No',
                        labelStyle: TextStyle(
                          color: Color(0xff014689),
                        ), // Label color
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff014689)),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: TextSizing.fontSizeMiniText(context) * 0.5,
                    ),

                    TextFormField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'New Time (e.g. 15 or 7:30)',
                        labelStyle: TextStyle(
                          color: Color(0xff014689),
                        ), // Label color
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff014689)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: TextSizing.fontSizeText(context),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Color(0xff014689),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Capture navigator and messenger before any await
                          final NavigatorState navigator = Navigator.of(
                            dialogContext,
                          );
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);

                          final String tripNoText = tripNoController.text;
                          final String timeText = timeController.text;

                          // Validate trips
                          if (!isTripValid(tripNoText)) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text(
                                    'Invalid input. Trip must be a whole number',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          // Validate time and normalize
                          final parsed = parseTimeInput(timeText);
                          if (parsed == null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text(
                                    'Invalid time. Only accepts formats such as "15" or "7:30"',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          // Normalized time string "HH:MM"
                          final normalizedTime =
                              '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
                          final int tripNo = int.parse(tripNoText.trim());

                          // Mark submitting in dialog local state
                          setState(() => isSubmitting = true);

                          try {
                            // Build payload according to your API contract
                            final payload = {
                              'info': partitionKey,
                              'column': column,
                              'time': normalizedTime,
                              'trips': tripNo,
                            };

                            await submitForm(
                              partitionKey,
                              column,
                              tripNoText,
                              normalizedTime,
                            );

                            // Refresh main list after successful submit
                            await _loadData();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(child: Text('Trip added')),
                              ),
                            );
                            navigator.pop();
                          } catch (e, st) {
                            if (kDebugMode) {
                              print('Add trip error: $e');
                              print(st);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text('Failed to add trip'),
                                ),
                              ),
                            );
                            // keep dialog open so user can retry or cancel
                          } finally {
                            // clear submitting flag if still mounted in dialog
                            if (mounted) setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: TextSizing.fontSizeText(context),
                          height: TextSizing.fontSizeText(context),
                          child: CircularProgressIndicator(
                            strokeWidth:
                                TextSizing.fontSizeMiniText(context) * 0.3,
                            color: Color(0xff014689),
                          ),
                        )
                      : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: TextSizing.fontSizeText(context),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            color: Color(0xff014689),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns a normalized DateTime for today when parse succeeds, otherwise null.
  // Accepts: "10" -> 10:00, "7:30", "07:00", "07:00:00", "1000" -> NOT accepted by default.
  // Trimmed input only.

  DateTime? parseTimeInput(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    // Accept "H" or "HH" -> treat as H:00
    final singleHourMatch = RegExp(r'^\d{1,2}$');
    if (singleHourMatch.hasMatch(s)) {
      final h = int.tryParse(s);
      if (h == null || h < 0 || h > 23) return null;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, h, 0);
    }

    // Accept "H:M", "HH:MM", optionally with seconds "HH:MM:SS"
    final parts = s.split(':').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h == null || m == null) return null;
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, h, m);
    }

    // Not acceptable format
    return null;
  }

  // Trip must be a positive integer (0 allowed if you want), no extra characters.
  bool isTripValid(String input) {
    final s = input.trim();
    if (s.isEmpty) return false;
    final match = RegExp(r'^\d+$');
    return match.hasMatch(s);
  }

  //////////////////////////////////////////////////////////////////////////////
  // AddIng Trip to Server

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

  //////////////////////////////////////////////////////////////////////////////
  // Modifying Trip on Server

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

  //////////////////////////////////////////////////////////////////////////////
  // Delete Trip Data from Server

  Future<void> deleteData(String info, String updateKey, String id) async {
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

  //////////////////////////////////////////////////////////////////////////////
  // Table Rows

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
              SizedBox.expand(
                child: Container(
                  color: Color(0xff014689),
                  child: Center(
                    child: TextButton(
                      onPressed: () =>
                          _showTripOptionsDialog(context, info, timing1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_bus,
                            size: TextSizing.fontSizeText(context),
                            color: Color(0xfffeb041),
                          ),
                          SizedBox(
                            width: TextSizing.fontSizeMiniText(context) * 0.5,
                          ),

                          Text(
                            'Trip ${timing1.id}',
                            style: TextStyle(
                              fontSize: TextSizing.fontSizeText(context),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            DataCell(
              SizedBox.expand(
                child: Container(
                  color: Colors.blue[100],
                  child: Center(
                    child: Text(
                      formatTime(timing1.time),
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeText(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            DataCell(
              SizedBox.expand(
                child: Container(
                  color: Color(0xff014689),
                  child: Center(
                    child: timing2 != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus,
                                size: TextSizing.fontSizeText(context),
                                color: Color(0xfffeb041),
                              ),
                              SizedBox(
                                width:
                                    TextSizing.fontSizeMiniText(context) * 0.5,
                              ),
                              TextButton(
                                onPressed: () => _showTripOptionsDialog(
                                  context,
                                  info,
                                  timing2,
                                ),
                                child: Text(
                                  'Trip ${timing2.id}',

                                  style: TextStyle(
                                    fontSize: TextSizing.fontSizeText(context),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox.expand(),
                  ),
                ),
              ),
            ),

            DataCell(
              SizedBox.expand(
                child: Container(
                  color: Colors.blue[100],
                  child: Center(
                    child: timing2 != null
                        ? Text(
                            formatTime(timing2.time),
                            style: TextStyle(
                              fontSize: TextSizing.fontSizeText(context),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              color: Colors.black,
                            ),
                          )
                        : SizedBox.shrink(),
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

  //////////////////////////////////////////////////////////////////////////////
  // build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: TextSizing.fontSizeMiniText(context) * 0.3,
                color: Color(0xff014689),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(TextSizing.fontSizeText(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Center(
                      child: Text(
                        'CLE Morning Bus',
                        style: TextStyle(
                          fontSize: TextSizing.fontSizeHeading(context),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: TextSizing.fontSizeText(context)),

                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: DataTable(
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Trip No',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Trip No',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: _generateRows(morningCLE, 'CLE_MorningBus'),
                          columnSpacing: 0,
                          headingRowHeight:
                              TextSizing.fontSizeHeading(context) * 1.75,
                          border: TableBorder.all(
                            color: Colors.white,
                            width: TextSizing.fontSizeMiniText(context) * 0.3,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showAddTripDialog(
                              context,
                              'CLE_MorningBus',
                              'times',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                              0xff014689,
                            ), // Button background color
                            foregroundColor:
                                Colors.white, // Text (and icon) color
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: TextSizing.fontSizeText(context),
                                color: Color(0xfffeb041),
                              ),
                              SizedBox(
                                width: TextSizing.fontSizeMiniText(context),
                              ),
                              Text(
                                'Add New Trip',
                                style: TextStyle(
                                  fontSize: TextSizing.fontSizeText(context),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: TextSizing.fontSizeHeading(context)),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Center(
                      child: Text(
                        'CLE Afternoon Bus',
                        style: TextStyle(
                          fontSize: TextSizing.fontSizeHeading(context),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: TextSizing.fontSizeText(context)),

                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: DataTable(
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Trip No',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Trip No',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Color(0xff014689),
                                  child: Center(
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeText(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          rows: _generateRows(afternoonCLE, 'CLE_AfternoonBus'),
                          columnSpacing: 0,
                          headingRowHeight:
                              TextSizing.fontSizeHeading(context) * 1.75,
                          border: TableBorder.all(
                            color: Colors.white,
                            width: TextSizing.fontSizeMiniText(context) * 0.3,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _showAddTripDialog(
                              context,
                              'CLE_AfternoonBus',
                              'times',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                              0xff014689,
                            ), // Button background color
                            foregroundColor:
                                Colors.white, // Text (and icon) color
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: TextSizing.fontSizeText(context),
                                color: Color(0xfffeb041),
                              ),
                              SizedBox(
                                width: TextSizing.fontSizeMiniText(context),
                              ),
                              Text(
                                'Add New Trip',
                                style: TextStyle(
                                  fontSize: TextSizing.fontSizeText(context),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: TextSizing.fontSizeHeading(context)),
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

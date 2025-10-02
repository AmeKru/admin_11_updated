import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admin_11_updated/models/model_provider.dart';
import 'package:admin_11_updated/utils/text_sizing.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_api_dart/amplify_api_dart.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class TableExport extends StatefulWidget {
  const TableExport({super.key});

  @override
  State<TableExport> createState() => _TableExportState();
}

class _TableExportState extends State<TableExport> {
  int? trackBooking;
  List<String> busStops = [];
  List<List<dynamic>> tableData = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> afternoonKAP = [];
  List<Map<String, dynamic>> afternoonCLE = [];
  List<Map<String, dynamic>> morningKAP = [];
  List<Map<String, dynamic>> morningCLE = [];

  @override
  void initState() {
    super.initState();
    //_configureAmplify();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await getBusStops();
    await scanKAP();
    await scanCLE();

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}_${dateTime.hour.toString().padLeft(2, '0')}-${dateTime.minute.toString().padLeft(2, '0')}-${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<String> _getDownloadPath() async {
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      downloadsDir = Directory(
        '/storage/emulated/0/Download',
      ); // Downloads folder on Android
    } else if (Platform.isIOS) {
      downloadsDir =
          await getApplicationDocumentsDirectory(); // For iOS, we use application documents directory
    }

    return downloadsDir!.path;
  }

  Future<void> _exportKAPData() async {
    /// CHANGE: Capture the ScaffoldMessenger before any `await`
    // This avoids using BuildContext after an async gap, which can cause warnings/crashes
    final messenger = ScaffoldMessenger.of(context);

    var excel = Excel.createExcel(); // Create a new Excel file
    Sheet? afternoonSheetKAP = excel['KAP Afternoon Data']; // Create sheets
    Sheet? morningSheetKAP = excel['KAP Morning Sheet'];

    String formatDate = _formatDate(DateTime.now());

    afternoonSheetKAP.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    afternoonSheetKAP.appendRow([TextCellValue(''), TextCellValue('')]);
    afternoonSheetKAP.appendRow([TextCellValue(''), TextCellValue('')]);

    afternoonSheetKAP.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill KAP data into the sheet
    for (var item in afternoonKAP) {
      afternoonSheetKAP.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    morningSheetKAP.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    morningSheetKAP.appendRow([TextCellValue(''), TextCellValue('')]);
    morningSheetKAP.appendRow([TextCellValue(''), TextCellValue('')]);

    morningSheetKAP.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill KAP data into the sheet
    for (var item in morningKAP) {
      morningSheetKAP.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    // Async gap here — after this await, context might be invalid
    String downloadPath = await _getDownloadPath();

    String formattedDate = _formatDateTime(DateTime.now());
    String filePath = '$downloadPath/kap_data_$formattedDate.xlsx';
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    if (kDebugMode) {
      print('KAP Excel file exported to $filePath');
    }

    /// CHANGE: Use the pre-captured messenger instead of calling ScaffoldMessenger.of(context) here
    messenger.showSnackBar(
      SnackBar(content: Center(child: Text('KAP Excel exported: $filePath'))),
    );
  }

  Future<void> _exportCLEData() async {
    /// CHANGE: Capture the ScaffoldMessenger before any `await`
    // This avoids using BuildContext after an async gap, which can cause warnings/crashes
    final messenger = ScaffoldMessenger.of(context);

    var excel = Excel.createExcel(); // Create a new Excel file
    Sheet? afternoonSheetCLE = excel['CLE Afternoon Data']; //Create sheets
    Sheet? morningSheetCLE = excel['CLE Morning Data'];

    String formatDate = _formatDate(DateTime.now());

    afternoonSheetCLE.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    afternoonSheetCLE.appendRow([TextCellValue(''), TextCellValue('')]);
    afternoonSheetCLE.appendRow([TextCellValue(''), TextCellValue('')]);

    afternoonSheetCLE.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill CLE data into the sheet
    for (var item in afternoonCLE) {
      afternoonSheetCLE.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    morningSheetCLE.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    morningSheetCLE.appendRow([TextCellValue(''), TextCellValue('')]);
    morningSheetCLE.appendRow([TextCellValue(''), TextCellValue('')]);

    morningSheetCLE.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill CLE data into the sheet
    for (var item in morningCLE) {
      morningSheetCLE.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    // Async gap here — after this await, context might be invalid
    String downloadPath = await _getDownloadPath();

    String formattedDate = _formatDateTime(DateTime.now());
    String filePath = '$downloadPath/cle_data_$formattedDate.xlsx';
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    if (kDebugMode) {
      print('CLE Excel file exported to $filePath');
    }

    /// CHANGE: Use the pre-captured messenger instead of calling ScaffoldMessenger.of(context) here
    messenger.showSnackBar(
      SnackBar(content: Center(child: Text('CLE Excel exported: $filePath'))),
    );
  }

  Future<void> getBusStops() async {
    try {
      Response response = await get(
        Uri.parse(
          'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/busstop?info=BusStops',
        ),
      );
      List<dynamic> data = jsonDecode(response.body);

      for (var item in data) {
        List<dynamic> positions = item['positions'];
        for (var position in positions) {
          String id = position['id'];
          busStops.add(id);
          if (kDebugMode) {
            print(id);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('caught error: $e');
      }
    }
  }

  // void _configureAmplify() async {
  //   final provider = ModelProvider();
  //   final amplifyApi = AmplifyAPI(
  //       options: APIPluginOptions(modelProvider: provider));
  //   final dataStorePlugin = AmplifyDataStore(modelProvider: provider);
  //
  //   Amplify.addPlugin(dataStorePlugin);
  //   Amplify.addPlugin(amplifyApi);
  //   Amplify.configure(amplifyconfig);
  //
  //   print('Amplify configured');
  // }

  Future<void> scanKAP() async {
    try {
      final request1 = ModelQueries.list(KAPAfternoon.classType);

      if (kDebugMode) {
        print("printing request1: ");
        print(request1);
      }

      final response1 = await Amplify.API.query(request: request1).response;

      if (kDebugMode) {
        print("printing response 1: ");
        print(response1);
      }

      final data1 = response1.data?.items;

      if (kDebugMode) {
        print("raw kap afternoon: $data1");
      }

      if (data1 != null) {
        // Transform items to a list of maps with only the necessary fields
        afternoonKAP = data1.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item.Count,
            'tripNo': item.TripNo,
          };
        }).toList();

        if (kDebugMode) {
          print('Printing KAP $afternoonKAP');
        }

        final request2 = ModelQueries.list(KAPMorning.classType);
        final response2 = await Amplify.API.query(request: request2).response;
        final data2 = response2.data?.items;

        if (data2 != null) {
          // Transform items to a list of maps with only the necessary fields
          morningKAP = data2.map((item) {
            return {
              'busStop': item!.BusStop,
              'count': item.Count,
              'tripNo': item.TripNo,
            };
          }).toList();
          if (kDebugMode) {
            print('Printing KAP $morningKAP');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('$e');
      }
    }
  }

  Future<void> scanCLE() async {
    try {
      final request1 = ModelQueries.list(CLEAfternoon.classType);
      final response1 = await Amplify.API.query(request: request1).response;
      final data1 = response1.data?.items;

      if (data1 != null) {
        // Transform items to a list of maps with only the necessary fields
        afternoonCLE = data1.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item.Count,
            'tripNo': item.TripNo,
          };
        }).toList();
        if (kDebugMode) {
          print('Printing CLE $afternoonCLE');
        }
      }
      final request2 = ModelQueries.list(CLEMorning.classType);
      final response2 = await Amplify.API.query(request: request2).response;
      final data2 = response2.data?.items;

      if (data2 != null) {
        // Transform items to a list of maps with only the necessary fields
        morningCLE = data2.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item.Count,
            'tripNo': item.TripNo,
          };
        }).toList();
        if (kDebugMode) {
          print('Printing CLE $morningCLE');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('$e');
      }
    }
  }

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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(
                        TextSizing.fontSizeHeading(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: TextSizing.fontSizeHeading(context)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                0xff014689,
                              ), // Button background color
                              foregroundColor:
                                  Colors.white, // Text (and icon) color
                            ),
                            onPressed: () {
                              scanKAP();
                              if (kDebugMode) {
                                print('KAP Data: $afternoonKAP');
                              } // Print the KAP data
                              _exportKAPData(); // Then proceed with exporting the KAP data
                            },
                            child: SizedBox(
                              height: TextSizing.fontSizeHeading(context) * 2,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file_outlined,
                                      size: TextSizing.fontSizeHeading(context),
                                      color: Color(0xfffeb041),
                                    ),
                                    SizedBox(
                                      width: TextSizing.fontSizeMiniText(
                                        context,
                                      ),
                                    ),
                                    Text(
                                      'Export KAP Data',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeHeading(
                                          context,
                                        ),
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: TextSizing.fontSizeText(context),
                          ), // Add some space between buttons
                          // Button to export CLE data
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(
                                0xff014689,
                              ), // Button background color
                              foregroundColor:
                                  Colors.white, // Text (and icon) color
                            ),
                            onPressed: () {
                              scanCLE();
                              if (kDebugMode) {
                                print('CLE Data: $afternoonCLE');
                              }
                              _exportCLEData(); // Then proceed with exporting the KAP data
                            }, // Export CLE data
                            child: SizedBox(
                              height: TextSizing.fontSizeHeading(context) * 2,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file_outlined,
                                      size: TextSizing.fontSizeHeading(context),
                                      color: Color(0xfffeb041),
                                    ),
                                    SizedBox(
                                      width: TextSizing.fontSizeMiniText(
                                        context,
                                      ),
                                    ),
                                    Text(
                                      'Export CLE Data',
                                      style: TextStyle(
                                        fontSize: TextSizing.fontSizeHeading(
                                          context,
                                        ),
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

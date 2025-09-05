import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admin_11_updated/models/ModelProvider.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_api_dart/amplify_api_dart.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:excel/excel.dart';
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
  List<String> BusStops = [];
  List<List<dynamic>> tableData = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> KAP_Afternoon = [];
  List<Map<String, dynamic>> CLE_Afternoon = [];
  List<Map<String, dynamic>> KAP_Morning = [];
  List<Map<String, dynamic>> CLE_Morning = [];

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
    var excel = Excel.createExcel(); // Create a new Excel file
    Sheet? KAP_AfternoonSheet = excel['KAP Afternoon Data']; // Create sheets
    Sheet? KAP_MorningSheet = excel['KAP Morning Sheet'];

    String formatDate = _formatDate(DateTime.now());

    KAP_AfternoonSheet.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    KAP_AfternoonSheet.appendRow([TextCellValue(''), TextCellValue('')]);
    KAP_AfternoonSheet.appendRow([TextCellValue(''), TextCellValue('')]);

    KAP_AfternoonSheet.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill KAP data into the sheet
    for (var item in KAP_Afternoon) {
      KAP_AfternoonSheet.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    KAP_MorningSheet.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    KAP_MorningSheet.appendRow([TextCellValue(''), TextCellValue('')]);
    KAP_MorningSheet.appendRow([TextCellValue(''), TextCellValue('')]);

    KAP_MorningSheet.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill KAP data into the sheet
    for (var item in KAP_Morning) {
      KAP_MorningSheet.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    // Save Excel file
    String downloadPath = await _getDownloadPath();
    String formattedDate = _formatDateTime(DateTime.now());
    String filePath = '${downloadPath}/kap_data_$formattedDate.xlsx';
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    print('KAP Excel file exported to $filePath');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('KAP Excel exported: $filePath')));
  }

  Future<void> _exportCLEData() async {
    var excel = Excel.createExcel(); // Create a new Excel file
    Sheet? CLE_AfternoonSheet = excel['CLE Afternoon Data']; //Create sheets
    Sheet? CLE_MorningSheet = excel['CLE Morning Data'];

    String formatDate = _formatDate(DateTime.now());

    CLE_AfternoonSheet.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    CLE_AfternoonSheet.appendRow([TextCellValue(''), TextCellValue('')]);
    CLE_AfternoonSheet.appendRow([TextCellValue(''), TextCellValue('')]);

    CLE_AfternoonSheet.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill CLE data into the sheet
    for (var item in CLE_Afternoon) {
      CLE_AfternoonSheet.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    CLE_MorningSheet.appendRow([
      TextCellValue('Date: '),
      TextCellValue(formatDate),
    ]);

    CLE_MorningSheet.appendRow([TextCellValue(''), TextCellValue('')]);
    CLE_MorningSheet.appendRow([TextCellValue(''), TextCellValue('')]);

    CLE_MorningSheet.appendRow([
      TextCellValue('Bus Stop'),
      TextCellValue('Count'),
      TextCellValue('Trip No'),
    ]);

    // Fill CLE data into the sheet
    for (var item in CLE_Morning) {
      CLE_MorningSheet.appendRow([
        TextCellValue(item['busStop']), // Bus Stop
        IntCellValue(item['count']), // Count, assuming it's an integer
        IntCellValue(item['tripNo']), // Trip No
      ]);
    }

    // Save Excel file
    String downloadPath = await _getDownloadPath();
    String formattedDate = _formatDateTime(DateTime.now());
    String filePath = '${downloadPath}/cle_data_$formattedDate.xlsx';
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    print('CLE Excel file exported to $filePath');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CLE Excel exported: $filePath')));
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
          BusStops.add(id);
          print(id);
        }
      }
    } catch (e) {
      print('caugh error: $e');
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
      print("printing request1: ");
      print(request1);
      final response1 = await Amplify.API.query(request: request1).response;
      print("printing response 1: ");
      print(response1);
      final data1 = response1.data?.items;
      print("raw kap afternoon: ${data1}");

      if (data1 != null) {
        // Transform items to a list of maps with only the necessary fields
        KAP_Afternoon = data1.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item!.Count,
            'tripNo': item!.TripNo,
          };
        }).toList();
        print('Printing KAP ${KAP_Afternoon}');

        final request2 = ModelQueries.list(KAPMorning.classType);
        final response2 = await Amplify.API.query(request: request2).response;
        final data2 = response2.data?.items;

        if (data2 != null) {
          // Transform items to a list of maps with only the necessary fields
          KAP_Morning = data2.map((item) {
            return {
              'busStop': item!.BusStop,
              'count': item!.Count,
              'tripNo': item!.TripNo,
            };
          }).toList();
          print('Printing KAP ${KAP_Morning}');
        }
      }
    } catch (e) {
      print('$e');
    }
  }

  Future<void> scanCLE() async {
    try {
      final request1 = ModelQueries.list(CLEAfternoon.classType);
      final response1 = await Amplify.API.query(request: request1).response;
      final data1 = response1.data?.items;

      if (data1 != null) {
        // Transform items to a list of maps with only the necessary fields
        CLE_Afternoon = data1.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item!.Count,
            'tripNo': item!.TripNo,
          };
        }).toList();
        print('Printing CLE ${CLE_Afternoon}');
      }
      final request2 = ModelQueries.list(CLEMorning.classType);
      final response2 = await Amplify.API.query(request: request2).response;
      final data2 = response2.data?.items;

      if (data2 != null) {
        // Transform items to a list of maps with only the necessary fields
        CLE_Morning = data2.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item!.Count,
            'tripNo': item!.TripNo,
          };
        }).toList();
        print('Printing CLE ${CLE_Morning}');
      }
    } catch (e) {
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          scanKAP();
                          print(
                            'KAP Data: $KAP_Afternoon',
                          ); // Print the KAP data
                          _exportKAPData(); // Then proceed with exporting the KAP data
                        },
                        child: Text(
                          'Export KAP Data',
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Monsterrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 16), // Add some space between buttons
                      // Button to export CLE data
                      ElevatedButton(
                        onPressed: () {
                          scanCLE();
                          print('CLE Data: $CLE_Afternoon');
                          _exportCLEData(); // Then proceed with exporting the KAP data
                        }, // Export CLE data
                        child: Text(
                          'Export CLE Data',
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Monsterrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

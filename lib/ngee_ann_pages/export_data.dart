import 'dart:async';
import 'dart:io';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_api_dart/amplify_api_dart.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ModelProvider.dart';
import '../utils/text_sizing.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Table Export ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// TableExport class

class TableExport extends StatefulWidget {
  const TableExport({super.key});

  @override
  State<TableExport> createState() => _TableExportState();
}

class _TableExportState extends State<TableExport> {
  //////////////////////////////////////////////////////////////////////////////
  // Variables

  int? trackBooking;
  List<String> busStops = [];
  List<List<dynamic>> tableData = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> afternoonKAP = [];
  List<Map<String, dynamic>> afternoonCLE = [];
  List<Map<String, dynamic>> morningKAP = [];
  List<Map<String, dynamic>> morningCLE = [];

  //////////////////////////////////////////////////////////////////////////////
  // init State

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- get All Data ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // load Data

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await getBusStops();
    morningKAP = await scanTrips('KAP', TripTimeOfDay.MORNING);
    afternoonKAP = await scanTrips('KAP', TripTimeOfDay.AFTERNOON);
    morningCLE = await scanTrips('CLE', TripTimeOfDay.MORNING);
    afternoonCLE = await scanTrips('CLE', TripTimeOfDay.AFTERNOON);

    setState(() {
      _isLoading = false;
    });
  }

  //////////////////////////////////////////////////////////////////////////////
  // get BusStops

  Future<void> getBusStops() async {
    try {
      final request = ModelQueries.list(
        BusStops.classType,
        authorizationMode: APIAuthorizationType.userPools, // auth app
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) {
          print('GraphQL errors: ${response.errors}');
        }
        return;
      }

      final items = response.data?.items;

      if (items != null) {
        busStops.clear(); // reset before adding
        for (var item in items) {
          if (item != null) {
            busStops.add(item.BusStop); // add the BusStop string
            if (kDebugMode) {
              print(
                'BusStop: ${item.BusStop}, Lat: ${item.Lat}, Lon: ${item.Lon}',
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('caught error: $e');
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // scan Trips

  Future<List<Map<String, dynamic>>> scanTrips(
    String mrtStation,
    TripTimeOfDay tripTime,
  ) async {
    try {
      // Build filter: MRTStation + TripTime
      final whereClause = CountTripList.MRTSTATION
          .eq(mrtStation)
          .and(CountTripList.TRIPTIME.eq(tripTime));

      final request = ModelQueries.list(
        CountTripList.classType,
        where: whereClause,
        authorizationMode: APIAuthorizationType.userPools, // auth app
      );

      if (kDebugMode) {
        print("scanTrips request: $request");
      }

      final response = await Amplify.API.query(request: request).response;

      if (kDebugMode) {
        print("scanTrips response: $response");
      }

      final data = response.data?.items;

      if (data != null) {
        final trips = data.map((item) {
          return {
            'busStop': item!.BusStop,
            'count': item.Count,
            'tripNo': item.TripNo,
          };
        }).toList();

        if (kDebugMode) {
          print('Trips for $mrtStation $tripTime → $trips');
        }

        return trips;
      }
    } catch (e) {
      if (kDebugMode) {
        print('scanTrips error: $e');
      }
    }
    return [];
  }

  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- get Path and export ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // get the download path for device in use

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

  //////////////////////////////////////////////////////////////////////////////
  // export data for KAP

  Future<void> _exportKAPData() async {
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

    messenger.showSnackBar(
      SnackBar(content: Center(child: Text('KAP Excel exported: $filePath'))),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // export data for CLE

  Future<void> _exportCLEData() async {
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

    messenger.showSnackBar(
      SnackBar(content: Center(child: Text('CLE Excel exported: $filePath'))),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Format helpers---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // format for DateTime year-month-day_hour-minute-second

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}_${dateTime.hour.toString().padLeft(2, '0')}-${dateTime.minute.toString().padLeft(2, '0')}-${dateTime.second.toString().padLeft(2, '0')}';
  }

  //////////////////////////////////////////////////////////////////////////////
  // format for DateTime year-month-day

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  //////////////////////////////////////////////////////////////////////////////
  // Download Button

  Widget downloadButton(String station) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff014689), // Button background color
        foregroundColor: Colors.white, // Text (and icon) color
      ),
      onPressed: () async {
        await _loadData();
        station == 'KAP'
            ? _exportKAPData()
            : _exportCLEData(); // Then proceed with exporting the data
      },
      child: SizedBox(
        height: TextSizing.fontSizeHeading(context) * 2,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_for_offline_rounded,
                size: TextSizing.fontSizeHeading(context),
                color: Color(0xfffeb041),
              ),
              SizedBox(width: TextSizing.fontSizeMiniText(context)),

              Text(
                'Download ',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                station,
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' data',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Main build ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // build

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('table_export has been built');
    }
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
                          downloadButton('KAP'),
                          SizedBox(height: TextSizing.fontSizeText(context)),
                          downloadButton('CLE'),
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

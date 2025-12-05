import 'dart:async';
import 'dart:convert';
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
  bool _isLoadingExport = false;
  bool _isLoadingDelete = false;
  List<Map<String, dynamic>> afternoonKAP = [];
  List<Map<String, dynamic>> afternoonCLE = [];
  List<Map<String, dynamic>> morningKAP = [];
  List<Map<String, dynamic>> morningCLE = [];

  //////////////////////////////////////////////////////////////////////////////
  // init State

  @override
  void initState() {
    super.initState();
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
      _isLoadingExport = true;
    });

    await getBusStops();
    morningKAP = await scanTrips('KAP', TripTimeOfDay.MORNING);
    afternoonKAP = await scanTrips('KAP', TripTimeOfDay.AFTERNOON);
    morningCLE = await scanTrips('CLE', TripTimeOfDay.MORNING);
    afternoonCLE = await scanTrips('CLE', TripTimeOfDay.AFTERNOON);

    setState(() {
      _isLoadingExport = false;
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
        final trips = data.map<Map<String, dynamic>>((item) {
          final rawCreated = item!.createdAt;
          final utcDt = _toDateTime(rawCreated); // returns UTC DateTime
          final sgDt = utcDt.add(const Duration(hours: 8)); // Singapore time

          return <String, dynamic>{
            'busStop': item.BusStop,
            'count': item.Count,
            'tripNo': item.TripNo,
            'createdAt': sgDt, // store as DateTime in SGT
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
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Helpers for excel sheet ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // group data by date of creation and TripNo

  Map<String, Map<int, List<Map<String, dynamic>>>> groupByDateAndTrip(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, Map<int, List<Map<String, dynamic>>>> out = {};
    for (final it in items) {
      final created = it['createdAt'] as DateTime; // already SGT
      final dateKey =
          "${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}";
      final tripNo = (it['tripNo'] is int)
          ? it['tripNo'] as int
          : int.parse('${it['tripNo']}');

      out.putIfAbsent(dateKey, () => {});
      out[dateKey]!.putIfAbsent(tripNo, () => []);
      out[dateKey]![tripNo]!.add(it);
    }

    // Optional: sort each trip list by createdAt ascending
    out.forEach((_, trips) {
      trips.forEach((_, list) {
        list.sort(
          (a, b) => (a['createdAt'] as DateTime).compareTo(
            b['createdAt'] as DateTime,
          ),
        );
      });
    });

    return out;
  }

  //////////////////////////////////////////////////////////////////////////////
  // creates a sheet for each date and tripTime, with all bus stops, tripNo and passenger count listed

  void appendGroupedToWorkbook(
    Excel excel,
    Map<String, Map<int, List<Map<String, dynamic>>>> grouped,
    String station,
    String tripTimeLabel,
  ) {
    // Define styles
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    grouped.forEach((date, trips) {
      final sheetName = _sanitizeSheetName("$station $tripTimeLabel $date");
      final sheet = excel[sheetName];

      // Row: Date
      sheet.appendRow([TextCellValue('Date:'), TextCellValue(date)]);
      // Row: blank
      sheet.appendRow([TextCellValue('')]);
      // Header row
      sheet.appendRow([
        TextCellValue('Trip No'),
        TextCellValue('Bus Stop'),
        TextCellValue('Count'),
      ]);

      // Apply header style to the last appended row
      final headerRowIndex =
          sheet.maxRows - 1; // zero-based index of header row
      for (var col = 0; col < 3; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: headerRowIndex,
          ),
        );
        cell.cellStyle = headerStyle;
      }

      final sortedTripNos = trips.keys.toList()..sort();
      for (final tn in sortedTripNos) {
        // Sort rows by createdAt if present
        final rows = trips[tn]!;
        rows.sort((a, b) {
          try {
            final aDt = _toDateTime(a['createdAt']);
            final bDt = _toDateTime(b['createdAt']);
            return aDt.compareTo(bDt);
          } catch (_) {
            return 0;
          }
        });

        for (final row in rows) {
          final countVal = (row['count'] is int)
              ? row['count'] as int
              : int.tryParse('${row['count']}') ?? 0;

          sheet.appendRow([
            IntCellValue(tn),
            TextCellValue(row['busStop'] as String? ?? ''),
            IntCellValue(countVal),
          ]);

          // Apply data style to the last appended row
          final dataRowIndex = sheet.maxRows - 1;
          for (var col = 0; col < 3; col++) {
            final cell = sheet.cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: dataRowIndex,
              ),
            );
            cell.cellStyle = dataStyle;
          }
        }

        // spacer row
        sheet.appendRow([TextCellValue('')]);
      }
    });
  }

  //////////////////////////////////////////////////////////////////////////////
  // To make sure sheet name is ok

  String _sanitizeSheetName(String name) {
    // Excel sheet name max length is 31 and cannot contain: \ / ? * [ ]
    var s = name.replaceAll(RegExp(r'[\\\/\?\*\[\]]'), '_');
    if (s.length > 31) s = s.substring(0, 31);
    return s;
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Format helpers for name of excel sheet---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // format for DateTime year-month-day

  String _formatDateForFilename(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  //////////////////////////////////////////////////////////////////////////////
  // format for DateTime hour minute second

  String _formatTimeForFilename(DateTime dt) {
    // Use 24h compact format HH MM SS
    return "${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}";
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns current Singapore time (UTC+8)

  DateTime _nowSingapore() {
    return DateTime.now().toUtc().add(const Duration(hours: 8));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns the complete filename either as
  // mrt_data_yyyy-mm-dd_hhmmss or
  // mrt_data_yyyy-mm-dd_to_yyyy-mm-dd_hhmmss

  String _filenameDateRangeWithTime(
    Map<String, Map<int, List<Map<String, dynamic>>>> groupedMorning,
    Map<String, Map<int, List<Map<String, dynamic>>>> groupedAfternoon,
  ) {
    final Set<String> keys = {};
    keys.addAll(groupedMorning.keys);
    keys.addAll(groupedAfternoon.keys);

    // Determine date token (single date or range)
    String dateToken;
    if (keys.isEmpty) {
      dateToken = _formatDateForFilename(_nowSingapore());
    } else {
      final dates = keys.map((k) => DateTime.parse(k)).toList()..sort();
      if (dates.length == 1) {
        dateToken = _formatDateForFilename(dates.first);
      } else {
        final oldest = _formatDateForFilename(dates.first);
        final newest = _formatDateForFilename(dates.last);
        dateToken = "${oldest}_to_$newest";
      }
    }

    // Append current Singapore time after the latest date
    final nowSg = _nowSingapore();
    final timeToken = _formatTimeForFilename(nowSg);

    return "${dateToken}_$timeToken";
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- get Path and export ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////

  Future<void> exportStationData(String station) async {
    final messenger = ScaffoldMessenger.of(context);

    final morning = await scanTrips(station, TripTimeOfDay.MORNING);
    final afternoon = await scanTrips(station, TripTimeOfDay.AFTERNOON);

    final List<Map<String, dynamic>> morningTyped = morning
        .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
        .toList();
    final List<Map<String, dynamic>> afternoonTyped = afternoon
        .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
        .toList();

    final groupedMorning = groupByDateAndTrip(morningTyped);
    final groupedAfternoon = groupByDateAndTrip(afternoonTyped);

    final excel = Excel.createExcel();

    appendGroupedToWorkbook(excel, groupedMorning, station, 'MORNING');
    appendGroupedToWorkbook(excel, groupedAfternoon, station, 'AFTERNOON');

    // remove default sheet if present
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Build filename date token from grouped maps
    final dateToken = _filenameDateRangeWithTime(
      groupedMorning,
      groupedAfternoon,
    );

    String filePath = 'Downloads/${station.toLowerCase()}_data_$dateToken.xlsx';

    if (kIsWeb) {
      excel.save(fileName: '${station.toLowerCase()}_data_$dateToken.xlsx');
    } else {
      // Optionally include a station/timeframe label
      final downloadPath = await _getDownloadPath();
      filePath = '$downloadPath/${station.toLowerCase()}_data_$dateToken.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);
    }

    if (kDebugMode) {
      print('$station Excel file exported to $filePath');
    }

    messenger.showSnackBar(
      SnackBar(
        content: Center(child: Text('$station Excel exported: $filePath')),
        duration: const Duration(seconds: 5),
      ),
    );
  }

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
  // returns a DateTime type

  DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);

    // Try common TemporalDateTime method names, then fallback to parsing string
    try {
      // Many Amplify Temporal types expose toDateTime()
      final dt = (value as dynamic).toDateTime();
      if (dt is DateTime) return dt;
    } catch (_) {}

    try {
      // Some versions expose getDateTime or value property
      final dt = (value as dynamic).getDateTime();
      if (dt is DateTime) return dt;
    } catch (_) {}

    try {
      final maybe = (value as dynamic).value;
      if (maybe is DateTime) return maybe;
      if (maybe is String) return DateTime.parse(maybe);
    } catch (_) {}

    // Last resort: parse the string representation
    return DateTime.parse(value.toString());
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- function to delete old entries---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Deletes all CountTripList entries older than today (Singapore time)
  // - If dryRun = true, it only logs what would be deleted
  // - Uses Cognito User Pools auth for signed‑in users

  Future<void> deleteCountTripListOlderThanTodayRaw({
    bool dryRun = true,
  }) async {
    // Compute "today" in Singapore time (UTC+8), normalized to midnight
    final todaySg = _todaySingaporeDate();

    String? nextToken;
    int checked = 0;
    int toDelete = 0;
    int deleted = 0;

    // Prevent re‑entrance
    if (_isLoadingDelete) {
      if (kDebugMode) {
        print('Deletion already in progress; aborting new request.');
      }
      return;
    }

    // Ensure user is signed in (Cognito User Pools)
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        if (kDebugMode) {
          print('User not signed in; cannot perform userPools requests.');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) print('Auth session check failed: $e');
      return;
    }

    setState(() => _isLoadingDelete = true);

    if (kDebugMode) {
      print('Starting deletion pass (dryRun=$dryRun). Today (SGT): $todaySg');
    }

    try {
      do {
        // Query all items (paginated)
        final req = GraphQLRequest<String>(
          document: r'''
query ListCountTripLists($limit: Int, $nextToken: String) {
  listCountTripLists(limit: $limit, nextToken: $nextToken) {
    items {
      id
      MRTStation
      TripTime
      BusStop
      TripNo
      Count
      createdAt
    }
    nextToken
  }
}
''',
          variables: {'limit': 100, 'nextToken': nextToken},
          authorizationMode: APIAuthorizationType.userPools, // Cognito auth
        );

        final response = await Amplify.API.query(request: req).response;

        if (response.errors.isNotEmpty) {
          if (kDebugMode) print('GraphQL errors: ${response.errors}');
          break;
        }

        if (response.data == null) break;

        final Map<String, dynamic> decoded = jsonDecode(response.data!);
        final listBlock =
            decoded['listCountTripLists'] as Map<String, dynamic>?;

        if (listBlock == null) break;

        final items = (listBlock['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        nextToken = listBlock['nextToken'] as String?;

        for (final item in items) {
          checked++;
          final createdRaw = item['createdAt'] as String?;
          if (createdRaw == null) continue;

          // Parse createdAt (UTC) and convert to Singapore date
          final utcCreated = DateTime.parse(createdRaw).toUtc();
          final sgCreatedDate = _toSingaporeDate(utcCreated);

          // If older than today (SGT), mark for deletion
          if (sgCreatedDate.isBefore(todaySg)) {
            toDelete++;
            if (dryRun) {
              if (kDebugMode) {
                print(
                  'DRY RUN: would delete id=${item['id']} createdAt(SGT)=$sgCreatedDate '
                  'MRT=${item['MRTStation']} BusStop=${item['BusStop']} TripNo=${item['TripNo']}',
                );
              }
              continue;
            }

            // Perform delete mutation
            try {
              final deleteReq = GraphQLRequest<String>(
                document: r'''
mutation DeleteCountTripList($input: DeleteCountTripListInput!) {
  deleteCountTripList(input: $input) {
    id
  }
}
''',
                variables: {
                  'input': {'id': item['id']},
                },
                authorizationMode:
                    APIAuthorizationType.userPools, // Cognito auth
              );

              final deleteResp = await Amplify.API
                  .mutate(request: deleteReq)
                  .response;

              if (deleteResp.errors.isNotEmpty) {
                if (kDebugMode) {
                  print(
                    'Delete errors for id=${item['id']}: ${deleteResp.errors}',
                  );
                }
              } else {
                deleted++;
                if (kDebugMode) {
                  print(
                    'Deleted id=${item['id']} createdAt(SGT)=$sgCreatedDate',
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) print('Exception deleting id=${item['id']}: $e');
            }
          }
        }
      } while (nextToken != null && nextToken.isNotEmpty);

      if (kDebugMode) {
        print(
          'Checked $checked items; marked $toDelete for deletion; actually deleted $deleted (dryRun=$dryRun).',
        );
      }
    } catch (e) {
      if (kDebugMode) print('deleteCountTripListOlderThanTodayRaw error: $e');
    } finally {
      _isLoadingDelete = false;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Deletes all BookingDetails entries older than today (Singapore time)
  // - If dryRun = true, it only logs what would be deleted
  // - Uses Cognito User Pools auth for signed‑in users

  Future<void> deleteBookingDetailsOlderThanTodayRaw({
    bool dryRun = true,
  }) async {
    // Compute "today" in Singapore time (UTC+8), normalized to midnight
    final todaySg = _todaySingaporeDate();

    String? nextToken;
    int checked = 0;
    int toDelete = 0;
    int deleted = 0;

    // Prevent re‑entrance
    if (_isLoadingDelete) {
      if (kDebugMode) {
        print('Deletion already in progress; aborting new request.');
      }
      return;
    }

    // Ensure user is signed in (Cognito User Pools)
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        if (kDebugMode) {
          print('User not signed in; cannot perform userPools requests.');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) print('Auth session check failed: $e');
      return;
    }

    setState(() => _isLoadingDelete = true);

    if (kDebugMode) {
      print(
        'Starting BookingDetails deletion pass (dryRun=$dryRun). Today (SGT): $todaySg',
      );
    }

    try {
      do {
        // Query all BookingDetails (paginated)
        final req = GraphQLRequest<String>(
          document: r'''
query ListBookingDetails($limit: Int, $nextToken: String) {
  listBookingDetails(limit: $limit, nextToken: $nextToken) {
    items {
      id
      MRTStation
      TripNo
      BusStop
      createdAt
    }
    nextToken
  }
}
''',
          variables: {'limit': 100, 'nextToken': nextToken},
          authorizationMode: APIAuthorizationType.userPools, // Cognito auth
        );

        final response = await Amplify.API.query(request: req).response;

        if (response.errors.isNotEmpty) {
          if (kDebugMode) print('GraphQL errors: ${response.errors}');
          break;
        }

        if (response.data == null) break;

        final Map<String, dynamic> decoded = jsonDecode(response.data!);
        final listBlock =
            decoded['listBookingDetails'] as Map<String, dynamic>?;

        if (listBlock == null) break;

        final items = (listBlock['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        nextToken = listBlock['nextToken'] as String?;

        for (final item in items) {
          checked++;
          final createdRaw = item['createdAt'] as String?;
          if (createdRaw == null) continue;

          // Parse createdAt (UTC) and convert to Singapore date
          final utcCreated = DateTime.parse(createdRaw).toUtc();
          final sgCreatedDate = _toSingaporeDate(utcCreated);

          // If older than today (SGT), mark for deletion
          if (sgCreatedDate.isBefore(todaySg)) {
            toDelete++;
            if (dryRun) {
              if (kDebugMode) {
                print(
                  'DRY RUN: would delete id=${item['id']} createdAt(SGT)=$sgCreatedDate '
                  'MRT=${item['MRTStation']} BusStop=${item['BusStop']} TripNo=${item['TripNo']}',
                );
              }
              continue;
            }

            // Perform delete mutation
            try {
              final deleteReq = GraphQLRequest<String>(
                document: r'''
mutation DeleteBookingDetails($input: DeleteBookingDetailsInput!) {
  deleteBookingDetails(input: $input) {
    id
  }
}
''',
                variables: {
                  'input': {'id': item['id']},
                },
                authorizationMode:
                    APIAuthorizationType.userPools, // Cognito auth
              );

              final deleteResp = await Amplify.API
                  .mutate(request: deleteReq)
                  .response;

              if (deleteResp.errors.isNotEmpty) {
                if (kDebugMode) {
                  print(
                    'Delete errors for id=${item['id']}: ${deleteResp.errors}',
                  );
                }
              } else {
                deleted++;
                if (kDebugMode) {
                  print(
                    'Deleted id=${item['id']} createdAt(SGT)=$sgCreatedDate',
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) print('Exception deleting id=${item['id']}: $e');
            }
          }
        }
      } while (nextToken != null && nextToken.isNotEmpty);

      if (kDebugMode) {
        print(
          'Checked $checked BookingDetails; marked $toDelete for deletion; actually deleted $deleted (dryRun=$dryRun).',
        );
      }
    } catch (e) {
      if (kDebugMode) print('deleteBookingDetailsOlderThanTodayRaw error: $e');
    } finally {
      _isLoadingDelete = false;
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Returns midnight today in Singapore time (UTC+8)

  DateTime _todaySingaporeDate() {
    final nowUtc = DateTime.now().toUtc();
    final sgNow = nowUtc.add(const Duration(hours: 8));
    // Midnight in Singapore, keep it in Singapore local time
    return DateTime(sgNow.year, sgNow.month, sgNow.day);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Converts a UTC timestamp to the Singapore calendar date (midnight)

  DateTime _toSingaporeDate(DateTime utc) {
    final sg = utc.add(const Duration(hours: 8));
    return DateTime(sg.year, sg.month, sg.day);
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Format helpers for build ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

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
        station == 'KAP' ? exportStationData('KAP') : exportStationData('CLE');
        // Then proceed with exporting the data
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
  // Delete Button

  Widget deleteButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Button background color
        foregroundColor: Colors.white, // Text (and icon) color
      ),
      onPressed: () {
        _showDeleteDialog();
      },
      child: SizedBox(
        height: TextSizing.fontSizeHeading(context) * 2,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_forever_rounded,
                size: TextSizing.fontSizeHeading(context),
                color: Colors.red[400],
              ),
              SizedBox(width: TextSizing.fontSizeMiniText(context)),

              Text(
                'Delete Data',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  //

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          backgroundColor: Colors.black,
          title: Text(
            'Are you sure you want to delete all data of bookings from prior days?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.red[400],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                navigator.pop();
                await deleteCountTripListOlderThanTodayRaw();
                await deleteBookingDetailsOlderThanTodayRaw();
                if (mounted) {
                  setState(() {
                    _isLoadingDelete = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text('Older entries have been deleted.'),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.red[400],
                ),
              ),
            ),
          ],
        );
      },
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
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(TextSizing.fontSizeHeading(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Download Data',
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
              SizedBox(height: TextSizing.fontSizeText(context)),
              _isLoadingExport
                  ? Column(
                      children: [
                        SizedBox(
                          height: TextSizing.fontSizeHeading(context) * 1.5,
                        ),
                        SizedBox(
                          height: TextSizing.fontSizeHeading(context) * 1.25,
                          width: TextSizing.fontSizeHeading(context) * 1.25,
                          child: CircularProgressIndicator(
                            strokeWidth:
                                TextSizing.fontSizeMiniText(context) * 0.3,
                            color: Color(0xff014689),
                          ),
                        ),

                        SizedBox(
                          height: TextSizing.fontSizeHeading(context) * 1.5,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        downloadButton('KAP'),
                        SizedBox(height: TextSizing.fontSizeText(context)),
                        downloadButton('CLE'),
                      ],
                    ),
              SizedBox(height: TextSizing.fontSizeHeading(context) * 3),
              Text(
                'Delete Older Data from server',
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
                style: TextStyle(
                  fontSize: TextSizing.fontSizeHeading(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
              Text(
                'delete all entries of bookings and passenger counts from prior days from the server',
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                ),
              ),
              SizedBox(height: TextSizing.fontSizeText(context)),
              Center(
                child: _isLoadingDelete
                    ? CircularProgressIndicator(
                        strokeWidth: TextSizing.fontSizeMiniText(context) * 0.3,
                        color: Colors.black,
                      )
                    : deleteButton(context),
              ),
              SizedBox(height: TextSizing.fontSizeText(context)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/BusStops.dart';
import '../utils/text_sizing.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Bus Stop list ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// BusStop class

class BusStop extends StatefulWidget {
  const BusStop({super.key});

  @override
  State<BusStop> createState() => _BusStopState();
}

class _BusStopState extends State<BusStop> {
  //////////////////////////////////////////////////////////////////////////////
  // Variables

  List<BusStops> busStopsList = []; // store actual model objects
  bool _isLoading = false;

  //////////////////////////////////////////////////////////////////////////////
  // init state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Amplify ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // get bus stops

  Future<List<BusStops>> getBusStops() async {
    try {
      final request = ModelQueries.list(
        BusStops.classType,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('GraphQL errors: ${response.errors}');
        return [];
      }

      final items = response.data?.items;
      if (items != null) {
        final stops = items.whereType<BusStops>().toList();

        //  Sort by StopNo ascending
        stops.sort((a, b) => a.StopNo.compareTo(b.StopNo));

        if (kDebugMode) {
          for (var stop in stops) {
            print(
              "Bus Stop: ${stop.BusStop}, StopNo: ${stop.StopNo}, "
              "Position: ${stop.Lat}, ${stop.Lon}, "
              "Description: ${stop.Description}",
            );
          }
        }
        return stops;
      }
    } catch (e) {
      if (kDebugMode) print("Error in getBusStops: $e");
    }
    return [];
  }

  //////////////////////////////////////////////////////////////////////////////
  // create a new stop

  Future<void> createBusStop(
    String name,
    double lat,
    double lon,
    int stopNo,
    String description,
  ) async {
    try {
      // 1. Get all stops
      final stops = await getBusStops();

      // 2. Find conflicts
      final conflicts = stops.where((s) => s.StopNo >= stopNo).toList();

      // 3. Shift numbers forward
      for (var stop in conflicts) {
        final updated = stop.copyWith(StopNo: stop.StopNo + 1);
        final updateRequest = ModelMutations.update(
          updated,
          authorizationMode: APIAuthorizationType.userPools,
        );
        await Amplify.API.mutate(request: updateRequest).response;
      }

      // 4. Create new stop with description
      final newStop = BusStops(
        BusStop: name,
        Lat: lat,
        Lon: lon,
        StopNo: stopNo,
        Description: description,
      );
      final request = ModelMutations.create(
        newStop,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Create errors: ${response.errors}');
      } else {
        if (kDebugMode) print('Bus stop created: ${response.data?.id}');
      }
    } catch (e) {
      if (kDebugMode) print('Error creating bus stop: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // update an existing bus stop

  Future<void> updateBusStop(
    BusStops stop,
    String newName,
    double newLat,
    double newLon,
    int newStopNo,
    String newDescription,
  ) async {
    try {
      final stops = await getBusStops();
      final oldStopNo = stop.StopNo;

      if (newStopNo > oldStopNo) {
        // Shift backward
        final toShift = stops
            .where(
              (s) =>
                  s.StopNo > oldStopNo &&
                  s.StopNo <= newStopNo &&
                  s.id != stop.id,
            )
            .toList();

        for (var s in toShift) {
          final updated = s.copyWith(StopNo: s.StopNo - 1);
          final updateRequest = ModelMutations.update(
            updated,
            authorizationMode: APIAuthorizationType.userPools,
          );
          await Amplify.API.mutate(request: updateRequest).response;
        }
      } else if (newStopNo < oldStopNo) {
        // Shift forward
        final toShift = stops
            .where(
              (s) =>
                  s.StopNo >= newStopNo &&
                  s.StopNo < oldStopNo &&
                  s.id != stop.id,
            )
            .toList();

        for (var s in toShift) {
          final updated = s.copyWith(StopNo: s.StopNo + 1);
          final updateRequest = ModelMutations.update(
            updated,
            authorizationMode: APIAuthorizationType.userPools,
          );
          await Amplify.API.mutate(request: updateRequest).response;
        }
      }

      // Finally update the target stop with description
      final updatedStop = stop.copyWith(
        BusStop: newName,
        Lat: newLat,
        Lon: newLon,
        StopNo: newStopNo,
        Description: newDescription,
      );

      final request = ModelMutations.update(
        updatedStop,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Update errors: ${response.errors}');
      } else {
        if (kDebugMode) print('Bus stop updated: ${response.data?.id}');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating bus stop: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // delete bus stop

  Future<void> deleteBusStop(BusStops stop) async {
    try {
      // 1. Get all stops
      final stops = await getBusStops();

      // 2. Find those after the deleted stop
      final toShift = stops.where((s) => s.StopNo > stop.StopNo).toList();

      // 3. Decrement their StopNo
      for (var s in toShift) {
        final updated = s.copyWith(StopNo: s.StopNo - 1);
        final updateRequest = ModelMutations.update(
          updated,
          authorizationMode: APIAuthorizationType.userPools,
        );
        await Amplify.API.mutate(request: updateRequest).response;
      }

      // 4. Delete the target stop
      final request = ModelMutations.delete(
        stop,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Delete errors: ${response.errors}');
      } else {
        if (kDebugMode) print('Bus stop deleted: ${response.data?.id}');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting bus stop: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Some other functions ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Load data

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stops = await getBusStops(); // should return List<BusStops>
      if (mounted) {
        setState(() {
          busStopsList = stops;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading bus stops: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // delete stop

  Future<void> _deleteStop(BusStops busStop) async {
    setState(() => _isLoading = true);
    try {
      await deleteBusStop(busStop); // pass the model directly
      await _loadData(); // refresh data
    } catch (e) {
      if (kDebugMode) print('Error deleting bus stop: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Alert Dialog ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // options (modify, delete, nothing)

  void _showStopOptionsDialog(BuildContext context, BusStops stop) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Edit Bus Stop',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          content: Text(
            'Would you like to modify or delete ${stop.BusStop}?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                navigator.pop();
                _showDeleteConfirmationDialog(context, stop);
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
                navigator.pop();
                _showModifyDialog(context, stop);
              },
              child: Text(
                'Modify',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // confirm deletion

  void _showDeleteConfirmationDialog(BuildContext context, BusStops stop) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

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
            'Are you sure you want to delete this stop?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
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
                  color: const Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                navigator.pop(); // close the dialog
                await _deleteStop(stop); // call your helper
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
  // Modify bus stop

  void _showModifyDialog(BuildContext context, BusStops stop) {
    final TextEditingController latController = TextEditingController(
      text: stop.Lat.toString(),
    );
    final TextEditingController lonController = TextEditingController(
      text: stop.Lon.toString(),
    );
    final TextEditingController nameController = TextEditingController(
      text: stop.BusStop,
    );
    final TextEditingController stopNoController = TextEditingController(
      text: stop.StopNo.toString(),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: stop.Description,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Modify ${stop.BusStop}',
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
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'New Name',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                ),
                TextFormField(
                  controller: stopNoController,
                  decoration: const InputDecoration(
                    labelText: 'New Stop Number',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: 'New Lat',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: lonController,
                  decoration: const InputDecoration(
                    labelText: 'New Lon',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'New Description',
                    labelStyle: TextStyle(color: Color(0xff014689)),
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
              onPressed: () => navigator.pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    latController.text.isNotEmpty &&
                    lonController.text.isNotEmpty &&
                    stopNoController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  await updateBusStop(
                    stop,
                    nameController.text.trim(),
                    double.parse(latController.text.trim()),
                    double.parse(lonController.text.trim()),
                    int.parse(stopNoController.text.trim()), // new StopNo
                    descriptionController.text.trim(), // new Description
                  );
                  await _loadData(); // refresh list
                }
                navigator.pop();
              },
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // to add a bus stop

  void _showAddStopDialog(BuildContext context) {
    final TextEditingController latController = TextEditingController();
    final TextEditingController stopNoController = TextEditingController();
    final TextEditingController lonController = TextEditingController();
    final TextEditingController stopController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Add New Stop',
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
                  controller: stopController,
                  decoration: const InputDecoration(
                    labelText: 'Stop Name',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                ),
                SizedBox(height: TextSizing.fontSizeMiniText(context) * 0.5),
                TextFormField(
                  controller: stopNoController,
                  decoration: const InputDecoration(
                    labelText: 'Stop Number',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: TextSizing.fontSizeMiniText(context) * 0.5),
                TextFormField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: TextSizing.fontSizeMiniText(context) * 0.5),
                TextFormField(
                  controller: lonController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: TextSizing.fontSizeMiniText(context) * 0.5),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Color(0xff014689)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff014689)),
                    ),
                  ),
                ),
                SizedBox(height: TextSizing.fontSizeText(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => navigator.pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: TextSizing.fontSizeText(context),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: const Color(0xff014689),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final lat = latController.text.trim();
                        final lon = lonController.text.trim();
                        final stop = stopController.text.trim();
                        final stopNo = stopNoController.text.trim();
                        final description = descriptionController.text.trim();

                        if (lat.isNotEmpty &&
                            lon.isNotEmpty &&
                            stop.isNotEmpty &&
                            stopNo.isNotEmpty &&
                            description.isNotEmpty) {
                          try {
                            await createBusStop(
                              stop, // new BusStop
                              double.parse(lat), // new lat
                              double.parse(lon), // new lon
                              int.parse(stopNo), // new StopNo
                              description, // new Description
                            );
                            await _loadData(); // refresh list
                          } catch (e) {
                            if (kDebugMode) print('Error adding stop: $e');
                          }
                          navigator.pop();
                        }
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: TextSizing.fontSizeText(context),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: const Color(0xff014689),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // when pressing on bus stop

  void _showDescription(BuildContext context, BusStops stop) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            '${stop.BusStop} Description',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          content: Text(
            stop.Description,
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: const Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- UI helper ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // build one row

  TableRow _buildBusStopRow(BuildContext context, BusStops stop, int rowIndex) {
    return TableRow(
      children: [
        // Bus Stop name with icon
        Container(
          color: const Color(0xff014689),
          padding: EdgeInsetsGeometry.fromLTRB(
            0,
            TextSizing.fontSizeMiniText(context) * 0.5,
            0,
            TextSizing.fontSizeMiniText(context) * 0.5,
          ),
          child: TextButton(
            onPressed: () => _showDescription(context, stop),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xff014689),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // removes rounded corners
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.flip(
                  flipY: true,
                  child: Icon(
                    CupertinoIcons.location_circle_fill,
                    color: const Color(0xfffeb041),
                    size: TextSizing.fontSizeText(context),
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    ' ${stop.BusStop}',
                    maxLines: 1, //  limits to 1 lines
                    overflow:
                        TextOverflow.ellipsis, // clips text if not fitting
                    style: TextStyle(
                      fontSize: TextSizing.fontSizeText(context),
                      color: Colors.white,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stop number
        Container(
          color: Colors.blue[50],
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: TextButton(
            onPressed: () {},
            child: Center(
              child: Text(
                '${stop.StopNo}',
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),

        // Position
        Container(
          color: Colors.blue[100],
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: TextButton(
            onPressed: () {},
            child: Center(
              child: Text(
                '${stop.Lat}, ${stop.Lon}',
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  color: Colors.black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
        ),

        // Edit button
        Container(
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: Center(
            child: ElevatedButton(
              onPressed: () => _showStopOptionsDialog(context, stop),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff014689),
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context)),
                shape: const CircleBorder(),
              ),
              child: Icon(
                Icons.edit,
                size: TextSizing.fontSizeText(context),
                color: const Color(0xfffeb041),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // returns one Table Row

  TableRow _buildEmptyTripRow(BuildContext context) {
    return TableRow(
      children: [
        // under Bus Stop cell
        Container(
          color: const Color(0xffffffff),
          child: Center(
            child: Text(
              '',
              style: TextStyle(
                fontSize: TextSizing.fontSizeText(context) * 0.05,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // under No cell
        Container(color: Colors.white),

        // under position
        Container(color: Colors.white),

        // under edit
        Container(color: Colors.white),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // build all the trips rows

  List<TableRow> _buildBusStopRows(BuildContext context, List<BusStops> stops) {
    List<TableRow> rows = [];

    // Header row (4 columns)
    rows.add(
      TableRow(
        children: [
          _headerCell(context, 'Bus Stop'),
          _headerCell(context, 'No'),
          _headerCell(context, 'Position [Lat, Lng]'),
          _headerCell(context, 'Edit'),
        ],
      ),
    );

    // Data rows
    for (int i = 0; i < stops.length; i++) {
      BusStops stop = stops[i];
      int rowIndex = i + 1; // header is row 0, so data starts at 1
      rows.add(_buildBusStopRow(context, stop, rowIndex));
      rows.add(_buildEmptyTripRow(context));
    }

    return rows;
  }

  //////////////////////////////////////////////////////////////////////////////
  // returns differently formatted header Cell

  Widget _headerCell(BuildContext context, String text) {
    return Container(
      color: const Color(0xffffffff),
      padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: TextSizing.fontSizeText(context),
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            color: Colors.blueGrey[700],
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- build ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: TextSizing.fontSizeMiniText(context) * 0.3,
                color: const Color(0xff014689),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(TextSizing.fontSizeHeading(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bus Stops and Positions',
                      maxLines: 1, //  limits to 1 lines
                      overflow:
                          TextOverflow.ellipsis, // clips text if not fitting
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeHeading(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2), // Bus Stop wider
                            1: FlexColumnWidth(1), // Stop No
                            2: FlexColumnWidth(4), // Position
                            3: IntrinsicColumnWidth(), // Edit button shrinks to fit
                          },
                          border: TableBorder.all(
                            color: Colors.white,
                            width: TextSizing.fontSizeMiniText(context) * 0.3,
                          ),
                          children: _buildBusStopRows(context, busStopsList),
                        ),
                      ),
                    ),
                    SizedBox(height: TextSizing.fontSizeHeading(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: ElevatedButton(
                            onPressed: () {
                              _showAddStopDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff014689),
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_rounded,
                                  size: TextSizing.fontSizeText(context),
                                  color: const Color(0xfffeb041),
                                ),
                                SizedBox(
                                  width: TextSizing.fontSizeMiniText(context),
                                ),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    'Add New Stop',
                                    maxLines: 1, //  limits to 1 lines
                                    overflow: TextOverflow
                                        .ellipsis, // clips text if not fitting
                                    style: TextStyle(
                                      fontSize: TextSizing.fontSizeText(
                                        context,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

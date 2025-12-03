import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/BookingDetails.dart';
import '../models/CountTripList.dart';
import '../models/TripList.dart';
import '../models/TripTimeOfDay.dart';
import '../utils/format_time.dart';
import '../utils/text_sizing.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Trip Times ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Timing class

class TimingScreen extends StatefulWidget {
  final String station; // "KAP" or "CLE"

  const TimingScreen({super.key, required this.station});

  @override
  State<TimingScreen> createState() => _TimingScreenState();
}

class _TimingScreenState extends State<TimingScreen> {
  List<TripList> morningTrips = [];
  List<TripList> afternoonTrips = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ////////////////////////////////////////////////////////////////////////////////
  // load data

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Query trips for this station
      final trips = await getTripsByStation(widget.station);

      // Split into morning/afternoon lists
      final morning = <TripList>[];
      final afternoon = <TripList>[];

      for (var trip in trips) {
        final dep = trip.DepartureTime.getDateTimeInUtc().add(
          const Duration(hours: 8),
        );
        if (dep.hour < 12) {
          morning.add(trip);
        } else {
          afternoon.add(trip);
        }
      }

      // sort each list by TripNo
      morning.sort((a, b) => a.TripNo.compareTo(b.TripNo));
      afternoon.sort((a, b) => a.TripNo.compareTo(b.TripNo));

      if (kDebugMode) {
        print('Loaded ${trips.length} trips for ${widget.station}');
        print('Morning: ${morning.length}, Afternoon: ${afternoon.length}');
      }

      if (mounted) {
        setState(() {
          morningTrips = morning;
          afternoonTrips = afternoon;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading trips: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Amplify ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Get Bus Trips and Times from Server

  Future<List<TripList>> getTripsByStation(String station) async {
    try {
      final request = ModelQueries.list(
        TripList.classType,
        where: TripList.MRTSTATION.eq(station),
        authorizationMode: APIAuthorizationType.userPools, // auth users
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('GraphQL errors: ${response.errors}');
        return [];
      }

      final items = response.data?.items;
      return items?.whereType<TripList>().toList() ?? [];
    } catch (e) {
      if (kDebugMode) print('Error fetching trips: $e');
      return [];
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // AddIng Trip to Server

  Future<void> createTrip(
    String station,
    TripTimeOfDay tripTime,
    DateTime departureTime,
  ) async {
    try {
      // Create with placeholder TripNo
      final newTrip = TripList(
        MRTStation: station,
        TripTime: tripTime,
        TripNo: 0, // temporary, will be renumbered
        DepartureTime: TemporalDateTime(departureTime),
      );

      final request = ModelMutations.create(
        newTrip,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Create errors: ${response.errors}');
        return;
      }

      if (kDebugMode) print('Trip created: ${response.data?.id}');

      // Renumber after insertion so TripNo is correct
      await renumberTrips(station, tripTime);
    } catch (e, st) {
      if (kDebugMode) {
        print('Error creating trip: $e');
        print(st);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Modifying Trip on Server

  Future<void> updateTrip(
    TripList trip, {
    String? newStation,
    TripTimeOfDay? newTripTime,
    DateTime? newDepartureTime,
  }) async {
    try {
      final updated = trip.copyWith(
        MRTStation: newStation ?? trip.MRTStation,
        TripTime: newTripTime ?? trip.TripTime,
        DepartureTime: newDepartureTime != null
            ? TemporalDateTime(newDepartureTime)
            : trip.DepartureTime,
      );

      final request = ModelMutations.update(
        updated,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Update errors: ${response.errors}');
      } else {
        if (kDebugMode) print('Trip updated: ${response.data?.id}');
        // Renumber old group if station/time changed
        await renumberTrips(trip.MRTStation, trip.TripTime);
        // Renumber new group
        await renumberTrips(updated.MRTStation, updated.TripTime);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating trip: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Delete Trip Data from Server

  Future<void> deleteTripCascade(TripList trip) async {
    // Keep track of what we've deleted so we can rollback if needed
    final deletedCountTrips = <CountTripList>[];
    final deletedBookings = <BookingDetails>[];
    bool tripDeleted = false;

    try {
      // 1. Delete TripList itself
      final tripDeleteRequest = ModelMutations.delete(
        trip,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final tripDeleteResponse = await Amplify.API
          .mutate(request: tripDeleteRequest)
          .response;

      if (tripDeleteResponse.errors.isNotEmpty) {
        throw Exception('Trip delete failed: ${tripDeleteResponse.errors}');
      }
      tripDeleted = true;
      if (kDebugMode) print('Trip deleted: ${tripDeleteResponse.data?.id}');
      // Renumber remaining trips in same group
      await renumberTrips(trip.MRTStation, trip.TripTime);

      // 2. Delete related CountTripList entries
      final countRequest = ModelQueries.list(
        CountTripList.classType,
        where: CountTripList.MRTSTATION
            .eq(trip.MRTStation)
            .and(CountTripList.TRIPNO.eq(trip.TripNo)),
        authorizationMode: APIAuthorizationType.userPools,
      );
      final countResponse = await Amplify.API
          .query(request: countRequest)
          .response;
      final countItems =
          countResponse.data?.items.whereType<CountTripList>() ?? [];

      for (var count in countItems) {
        final deleteCountRequest = ModelMutations.delete(
          count,
          authorizationMode: APIAuthorizationType.userPools,
        );
        final resp = await Amplify.API
            .mutate(request: deleteCountRequest)
            .response;
        if (resp.errors.isNotEmpty) {
          throw Exception('Failed to delete CountTripList ${count.id}');
        }
        deletedCountTrips.add(count);
        if (kDebugMode) print('Deleted CountTripList: ${count.id}');
      }

      // 3. Delete related BookingDetails entries
      final bookingRequest = ModelQueries.list(
        BookingDetails.classType,
        where: BookingDetails.MRTSTATION
            .eq(trip.MRTStation)
            .and(BookingDetails.TRIPNO.eq(trip.TripNo)),
        authorizationMode: APIAuthorizationType.userPools,
      );
      final bookingResponse = await Amplify.API
          .query(request: bookingRequest)
          .response;
      final bookingItems =
          bookingResponse.data?.items.whereType<BookingDetails>() ?? [];

      for (var booking in bookingItems) {
        final deleteBookingRequest = ModelMutations.delete(
          booking,
          authorizationMode: APIAuthorizationType.userPools,
        );
        final resp = await Amplify.API
            .mutate(request: deleteBookingRequest)
            .response;
        if (resp.errors.isNotEmpty) {
          throw Exception('Failed to delete BookingDetails ${booking.id}');
        }
        deletedBookings.add(booking);
        if (kDebugMode) print('Deleted BookingDetails: ${booking.id}');
      }

      //  If we reach here, all deletes succeeded
      if (kDebugMode) print('Cascade delete complete for Trip ${trip.TripNo}');
    } catch (e) {
      if (kDebugMode) print('Cascade delete error: $e');

      //  Rollback logic (best effort)
      try {
        // Recreate TripList if it was deleted
        if (tripDeleted) {
          final recreateTripRequest = ModelMutations.create(
            trip,
            authorizationMode: APIAuthorizationType.userPools,
          );
          await Amplify.API.mutate(request: recreateTripRequest).response;
          if (kDebugMode) print('Rolled back TripList ${trip.id}');
        }

        // Recreate CountTripList entries
        for (var count in deletedCountTrips) {
          final recreateCountRequest = ModelMutations.create(
            count,
            authorizationMode: APIAuthorizationType.userPools,
          );
          await Amplify.API.mutate(request: recreateCountRequest).response;
          if (kDebugMode) print('Rolled back CountTripList ${count.id}');
        }

        // Recreate BookingDetails entries
        for (var booking in deletedBookings) {
          final recreateBookingRequest = ModelMutations.create(
            booking,
            authorizationMode: APIAuthorizationType.userPools,
          );
          await Amplify.API.mutate(request: recreateBookingRequest).response;
          if (kDebugMode) print('Rolled back BookingDetails ${booking.id}');
        }
      } catch (rollbackError) {
        if (kDebugMode) print('Rollback failed: $rollbackError');
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // helper to number trips accordingly

  Future<void> renumberTrips(String station, TripTimeOfDay tripTime) async {
    final trips = await getTripsByStation(station);

    // Filter by time of day (Morning vs Afternoon)
    final filtered = trips.where((t) => t.TripTime == tripTime).toList();

    // Sort by Singapore time (UTC+8), ignoring date
    filtered.sort((a, b) {
      final aDateTimeUtc = a.DepartureTime.getDateTimeInUtc();
      final bDateTimeUtc = b.DepartureTime.getDateTimeInUtc();

      // Convert to Singapore time by adding 8 hours
      final aDateTimeSg = aDateTimeUtc.add(const Duration(hours: 8));
      final bDateTimeSg = bDateTimeUtc.add(const Duration(hours: 8));

      // Extract only the time portion
      final aDuration = Duration(
        hours: aDateTimeSg.hour,
        minutes: aDateTimeSg.minute,
        seconds: aDateTimeSg.second,
      );
      final bDuration = Duration(
        hours: bDateTimeSg.hour,
        minutes: bDateTimeSg.minute,
        seconds: bDateTimeSg.second,
      );

      return aDuration.compareTo(bDuration);
    });

    // Renumber sequentially
    for (int i = 0; i < filtered.length; i++) {
      final trip = filtered[i];
      final newNo = i + 1;

      if (trip.TripNo != newNo) {
        final updated = trip.copyWith(TripNo: newNo);

        final request = ModelMutations.update(
          updated,
          authorizationMode: APIAuthorizationType.userPools,
        );
        await Amplify.API.mutate(request: request).response;
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Alert Dialogs ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to delete the trip

  void _showDeleteConfirmationDialog(BuildContext context, TripList trip) {
    bool isDeleting = false;
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
              onPressed: isDeleting ? null : () => navigator.pop(),
              child: isDeleting
                  ? SizedBox.shrink()
                  : Text(
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
              onPressed: isDeleting
                  ? null
                  : () async {
                      setState(() {
                        isDeleting = true;
                      });
                      await deleteTripCascade(trip); // call  helper
                      await _loadData(); // refresh list
                      navigator.pop(); // close dialog
                      setState(() {
                        isDeleting = false;
                      });
                    },
              child: isDeleting
                  ? SizedBox(
                      width: TextSizing.fontSizeText(context),
                      height: TextSizing.fontSizeText(context),
                      child: CircularProgressIndicator(
                        strokeWidth: TextSizing.fontSizeMiniText(context) * 0.3,
                        color: const Color(0xff014689),
                      ),
                    )
                  : Text(
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
  // Pop up to modify selected Trip

  void _showModifyDialog(BuildContext context, TripList trip) {
    final TextEditingController timeController = TextEditingController(
      // prefill with current departure time
      text: formatTime(
        trip.DepartureTime.getDateTimeInUtc().add(const Duration(hours: 8)),
      ),
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
                'Modify Trip ${trip.TripNo}',
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
                        labelText: trip.TripTime == TripTimeOfDay.MORNING
                            ? 'New Time (e.g. 10 or 7:30)'
                            : 'New Time (e.g. 15 or 17:30)',
                        labelStyle: const TextStyle(color: Color(0xff014689)),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const UnderlineInputBorder(
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
                  child: isSubmitting
                      ? SizedBox.shrink()
                      : Text(
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);

                          final String timeText = timeController.text.trim();

                          // Validate and normalize
                          final DateTime? parsed = parseTimeInput(timeText);
                          if (parsed == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Center(
                                  child: Text(
                                    'Invalid time. Only accepts formats such as "15" or "7:30"',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);

                          try {
                            // Call your updateTrip helper
                            await updateTrip(trip, newDepartureTime: parsed);

                            await _loadData(); // refresh list

                            messenger.showSnackBar(
                              const SnackBar(
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
                              const SnackBar(
                                content: Center(
                                  child: Text('Failed to update trip'),
                                ),
                              ),
                            );
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
                            color: const Color(0xff014689),
                          ),
                        )
                      : Text(
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
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Pop up to edit/delete Trip

  void _showTripOptionsDialog(BuildContext context, TripList trip) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);

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
                _showDeleteConfirmationDialog(context, trip);
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
                _showModifyDialog(context, trip);
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
  // Pop up to add Trip

  void _showAddTripDialog(BuildContext context, String station) {
    final TextEditingController timeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Departure Time (e.g. 15 or 7:30)',
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
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: isSubmitting
                      ? SizedBox.shrink()
                      : Text(
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);

                          final String timeText = timeController.text.trim();

                          // Validate time
                          final DateTime? parsed = parseTimeInput(timeText);
                          if (parsed == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Center(
                                  child: Text(
                                    'Invalid time. Use formats like "15" or "7:30"',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          // Derive TripTimeOfDay (morning vs afternoon)
                          final TripTimeOfDay tripTime = parsed.hour < 12
                              ? TripTimeOfDay.MORNING
                              : TripTimeOfDay.AFTERNOON;

                          setState(() => isSubmitting = true);

                          try {
                            // Call new createTrip signature (no tripNo argument)
                            await createTrip(station, tripTime, parsed);

                            await _loadData(); // refresh list

                            messenger.showSnackBar(
                              const SnackBar(
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
                              const SnackBar(
                                content: Center(
                                  child: Text('Failed to add trip'),
                                ),
                              ),
                            );
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
                            color: const Color(0xff014689),
                          ),
                        )
                      : Text(
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
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Input helpers ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Returns a normalized DateTime for today when parse succeeds, otherwise null
  // Accepts: "10" -> 10:00, "7:30", "07:00", "07:00:00", "1000" -> NOT accepted by default
  // Trimmed input only

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
  /// //////////////////////////////////////////////////////////////////////////
  /// --- UI helper ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // returns one Table Row

  TableRow _buildTripRow(
    BuildContext context,
    TripList trip1,
    TripList? trip2,
    int rowIndex,
  ) {
    return TableRow(
      children: [
        // Trip 1 cell
        Container(
          color: const Color(0xff014689),
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: Center(
            child: TextButton(
              onPressed: () => _showTripOptionsDialog(context, trip1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Icon(
                      Icons.directions_bus,
                      size: TextSizing.fontSizeText(context),
                      color: const Color(0xfffeb041),
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      width: TextSizing.fontSizeMiniText(context) * 0.5,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${trip1.TripNo}',
                      maxLines: 1, //  limits to 1 lines
                      overflow:
                          TextOverflow.ellipsis, // clips text if not fitting
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeText(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Trip 1 time cell
        Container(
          color: Colors.blue[100],
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: Center(
            child: TextButton(
              onPressed: () => _showTripOptionsDialog(context, trip1),
              child: Text(
                formatTime(
                  trip1.DepartureTime.getDateTimeInUtc().add(
                    const Duration(hours: 8),
                  ),
                ),
                maxLines: 1, //  limits to 1 lines
                overflow: TextOverflow.ellipsis, // clips text if not fitting
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

        Container(color: Colors.white),

        // Trip 2 cell (if exists)
        Container(
          color: trip2 != null
              ? const Color(0xff014689)
              : const Color(0xffffffff),
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: Center(
            child: trip2 != null
                ? TextButton(
                    onPressed: () => _showTripOptionsDialog(context, trip2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Icon(
                            Icons.directions_bus,
                            size: TextSizing.fontSizeText(context),
                            color: const Color(0xfffeb041),
                          ),
                        ),
                        Flexible(
                          child: SizedBox(
                            width: TextSizing.fontSizeMiniText(context) * 0.5,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '${trip2.TripNo}',
                            maxLines: 1, //  limits to 1 lines
                            overflow: TextOverflow
                                .ellipsis, // clips text if not fitting
                            style: TextStyle(
                              fontSize: TextSizing.fontSizeText(context),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton(
                    onPressed: () {},
                    child: Text(
                      ' ',
                      maxLines: 1, //  limits to 1 lines
                      overflow:
                          TextOverflow.ellipsis, // clips text if not fitting
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeText(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),

        // Trip 2 time cell (if exists)
        Container(
          color: trip2 != null ? Colors.blue[100] : Colors.white,
          padding: EdgeInsets.all(TextSizing.fontSizeMiniText(context) * 0.5),
          child: Center(
            child: trip2 != null
                ? TextButton(
                    onPressed: () => _showTripOptionsDialog(context, trip2),
                    child: Text(
                      formatTime(
                        trip2.DepartureTime.getDateTimeInUtc().add(
                          const Duration(hours: 8),
                        ),
                      ),
                      maxLines: 1, //  limits to 1 lines
                      overflow:
                          TextOverflow.ellipsis, // clips text if not fitting
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeText(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () {},
                    child: Text(
                      ' ',
                      maxLines: 1, //  limits to 1 lines
                      overflow:
                          TextOverflow.ellipsis, // clips text if not fitting
                      style: TextStyle(
                        fontSize: TextSizing.fontSizeText(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
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
        // under Trip 1 cell
        Container(
          color: const Color(0xffffffff),
          child: Center(
            child: Text(
              '',
              style: TextStyle(
                fontSize: TextSizing.fontSizeText(context) * 0.1,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // under Trip 1 time cell
        Container(color: Colors.white),

        // space in between
        Container(color: Colors.white),

        // under Trip 2 cell (if exists)
        Container(color: Colors.white),

        // under Trip 2 time cell
        Container(color: Colors.white),
      ],
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // build all the trips rows

  List<TableRow> _buildTripRows(BuildContext context, List<TripList> trips) {
    List<TableRow> rows = [];

    // Header row
    rows.add(
      TableRow(
        children: [
          _headerCell(context, 'Trip No'),
          _headerCell(context, 'Time'),
          _headerCell(context, ''),
          _headerCell(context, 'Trip No'),
          _headerCell(context, 'Time'),
        ],
      ),
    );

    // Data rows (two trips per row)
    for (int i = 0; i < trips.length; i += 2) {
      TripList trip1 = trips[i];
      TripList? trip2 = (i + 1 < trips.length) ? trips[i + 1] : null;
      int rowIndex = (i ~/ 2) + 1;
      rows.add(_buildTripRow(context, trip1, trip2, rowIndex));
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
          maxLines: 1, //  limits to 1 lines
          overflow: TextOverflow.ellipsis, // clips text if not fitting
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
  /// --- Main build function ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // build

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('${widget.station} Timing built');
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
          : SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(TextSizing.fontSizeHeading(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        '${widget.station} Morning Bus',
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
                    ),
                    SizedBox(height: TextSizing.fontSizeText(context)),

                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Table(
                              // Define column widths: TripNo narrow, in between a tiny bit of extra space, Time wider
                              columnWidths: const {
                                0: FlexColumnWidth(15),
                                1: FlexColumnWidth(20),
                                2: FlexColumnWidth(0.2),
                                3: FlexColumnWidth(15),
                                4: FlexColumnWidth(20),
                              },
                              border: TableBorder.all(
                                color: Colors.white,
                                width:
                                    TextSizing.fontSizeMiniText(context) * 0.3,
                              ),
                              children: _buildTripRows(context, morningTrips),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: ElevatedButton(
                            onPressed: () {
                              _showAddTripDialog(context, widget.station);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xff014689,
                              ), // Button background color
                              foregroundColor:
                                  Colors.white, // Text (and icon) color
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
                                    'Add New Trip',
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

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Center(
                      child: Text(
                        '${widget.station} Afternoon Bus',
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
                    ),
                    SizedBox(height: TextSizing.fontSizeText(context)),

                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Table(
                              // Define column widths: Trip No narrow, Time wider
                              columnWidths: const {
                                0: FlexColumnWidth(15),
                                1: FlexColumnWidth(20),
                                2: FlexColumnWidth(0.2),
                                3: FlexColumnWidth(15),
                                4: FlexColumnWidth(20),
                              },
                              border: TableBorder.all(
                                color: Colors.white,
                                width:
                                    TextSizing.fontSizeMiniText(context) * 0.3,
                              ),
                              children: _buildTripRows(context, afternoonTrips),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: TextSizing.fontSizeText(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: ElevatedButton(
                            onPressed: () {
                              _showAddTripDialog(context, widget.station);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xff014689,
                              ), // Button background color
                              foregroundColor:
                                  Colors.white, // Text (and icon) color
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
                                    'Add New Trip',
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

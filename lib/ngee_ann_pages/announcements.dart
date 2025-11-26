import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/Announcements.dart';
import '../utils/text_sizing.dart';

////////////////////////////////////////////////////////////////////////////////
/// ////////////////////////////////////////////////////////////////////////////
/// --- Auth Login Page ---
/// ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// AnnouncementPage class

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => AnnouncementsPageState();
}

class AnnouncementsPageState extends State<AnnouncementsPage> {
  //////////////////////////////////////////////////////////////////////////////
  // Variables

  String announcements = '';
  Announcements? announcementWithID;
  bool _isLoading = false;
  final TextEditingController _announcementsController =
      TextEditingController();

  //////////////////////////////////////////////////////////////////////////////
  // Init State

  @override
  void initState() {
    super.initState();
    loadAnnouncement();
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Amplify request, get read delete ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////////////
  // To get the existing Announcement if it exists

  Future<Announcements?> getFirstAnnouncement() async {
    if (kDebugMode) {
      print('getFirstAnnouncement() called');
    }
    try {
      final request = ModelQueries.list(
        Announcements.classType,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('GraphQL errors: ${response.errors}');
        return null;
      }

      final items = response.data?.items;
      if (items != null && items.isNotEmpty) {
        final first = items.first;
        if (kDebugMode) {
          print(
            'First announcement: id=${first?.id}, text=${first?.Announcement}',
          );
        }
        return first;
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching first announcement: $e');
    }
    return null;
  }

  /////////////////////////////////////////////////////////////////////////////
  // To create or update an Announcement

  Future<void> upsertAnnouncement(String newText) async {
    try {
      // Step 1: Try to fetch the first announcement
      final request = ModelQueries.list(
        Announcements.classType,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('GraphQL errors: ${response.errors}');
        return;
      }

      final items = response.data?.items;

      if (items != null && items.isNotEmpty) {
        // Step 2: Update the first announcement
        final first = items.first;
        if (first != null) {
          final updated = first.copyWith(Announcement: newText);

          final updateReq = ModelMutations.update(
            updated,
            authorizationMode: APIAuthorizationType.userPools,
          );
          final updateResp = await Amplify.API
              .mutate(request: updateReq)
              .response;

          if (updateResp.errors.isNotEmpty) {
            if (kDebugMode) print('Update errors: ${updateResp.errors}');
          } else {
            if (kDebugMode) {
              print('Announcement updated: ${updateResp.data?.id}');
            }
          }
        }
      } else {
        // Step 3: No announcement exists → create one
        final newAnnouncement = Announcements(Announcement: newText);

        final createReq = ModelMutations.create(
          newAnnouncement,
          authorizationMode: APIAuthorizationType.userPools,
        );
        final createResp = await Amplify.API
            .mutate(request: createReq)
            .response;

        if (createResp.errors.isNotEmpty) {
          if (kDebugMode) print('Create errors: ${createResp.errors}');
        } else {
          if (kDebugMode) print('Announcement created: ${createResp.data?.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error in upsertAnnouncement: $e');
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // Delete existing Announcement

  Future<void> deleteAnnouncement(Announcements announcement) async {
    try {
      final request = ModelMutations.delete(
        announcement,
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        if (kDebugMode) print('Delete errors: ${response.errors}');
      } else {
        if (kDebugMode) print('Announcement deleted: ${response.data?.id}');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting announcement: $e');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Some other Functions ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // To delete Announcement

  Future<void> _deleteNews() async {
    try {
      if (announcementWithID != null) {
        await deleteAnnouncement(announcementWithID!);
        await loadAnnouncement();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting trip: $e');
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // To load Data

  Future<void> loadAnnouncement() async {
    announcementWithID = await getFirstAnnouncement();
    if (announcementWithID != null) {
      if (mounted) {
        setState(() {
          announcements = announcementWithID!.Announcement.trim();
        });
      }
    } else {
      if (kDebugMode) print('No announcement found');
      setState(() {
        announcements = '';
      });
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  /// //////////////////////////////////////////////////////////////////////////
  /// --- Alert Dialog Widgets ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////
  // Confirm deletion

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Confirm Deletion',
            style: TextStyle(
              fontSize: TextSizing.fontSizeHeading(context),
              fontFamily: 'Roboto',
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this?',
            style: TextStyle(
              fontSize: TextSizing.fontSizeText(context),
              fontFamily: 'Roboto',
              color: Colors.black,
              fontWeight: FontWeight.normal,
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
                  fontFamily: 'Roboto',
                  color: Color(0xff014689),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNews();
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  fontSize: TextSizing.fontSizeText(context),
                  fontFamily: 'Roboto',
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Change Announcement

  void _showModifyDialog() {
    // Pre-fill controller with existing announcement if available
    _announcementsController.text = announcements;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Text(
            'Modify Announcement',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: TextSizing.fontSizeHeading(context),
              color: Colors.black,
            ),
          ),
          content: TextField(
            controller: _announcementsController,
            decoration: InputDecoration(
              hintText: 'Enter updated Announcement',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueGrey[500]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xff014689),
                  width: TextSizing.fontSizeMiniText(context) * 0.25,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: TextSizing.fontSizeText(context),
                  color: const Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                final text = _announcementsController.text.trim();

                if (text.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an announcement'),
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                setState(() => _isLoading = true);

                try {
                  await upsertAnnouncement(text);

                  if (!mounted) {
                    navigator.pop();
                    return;
                  }

                  setState(() => announcements = text);
                  await loadAnnouncement();

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Announcement updated')),
                  );

                  navigator.pop();
                  _announcementsController.clear();
                } catch (e, st) {
                  if (kDebugMode) {
                    print('Modify confirm error: $e');
                    print(st);
                  }
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update announcement'),
                    ),
                  );
                  navigator.pop();
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: TextSizing.fontSizeText(context),
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
  /// --- Build ---
  /// //////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Announcements built');
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
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          TextSizing.fontSizeHeading(context),
                          TextSizing.fontSizeText(context),
                          TextSizing.fontSizeHeading(context),
                          TextSizing.fontSizeText(context),
                        ),
                        decoration: BoxDecoration(color: Color(0xfffeb041)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.announcement,
                                  color: Colors.blueGrey[900],
                                  size: TextSizing.fontSizeHeading(context),
                                ),
                                SizedBox(
                                  width:
                                      TextSizing.fontSizeMiniText(context) *
                                      0.75,
                                ),
                                Flexible(
                                  child: Text(
                                    'NP Announcements',
                                    maxLines: 1, //  limits to 1 lines
                                    overflow: TextOverflow
                                        .ellipsis, // clips text if not fitting
                                    style: TextStyle(
                                      fontSize: TextSizing.fontSizeHeading(
                                        context,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[900],
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: TextSizing.fontSizeText(context)),
                            Center(
                              child: Text(
                                announcements.isNotEmpty
                                    ? announcements
                                    : 'No Announcements available',
                                style: TextStyle(
                                  fontSize: TextSizing.fontSizeText(context),
                                  fontWeight: FontWeight.normal,
                                  color: announcements.isNotEmpty
                                      ? Colors.blueGrey[900]
                                      : Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              height: TextSizing.fontSizeHeading(context),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .blueGrey[900], // Button background color
                                      foregroundColor:
                                          Colors.white, // Text (and icon) color
                                    ),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(context);
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: TextSizing.fontSizeText(
                                            context,
                                          ),
                                        ),

                                        Flexible(
                                          child: Text(
                                            '  Delete',
                                            maxLines: 1, //  limits to 1 lines
                                            overflow: TextOverflow
                                                .ellipsis, // clips text if not fitting
                                            style: TextStyle(
                                              fontSize: TextSizing.fontSizeText(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Flexible(
                                  fit: FlexFit.loose,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .blueGrey[900], // Button background color
                                      foregroundColor:
                                          Colors.white, // Text (and icon) color
                                    ),
                                    onPressed: () {
                                      _showModifyDialog();
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: TextSizing.fontSizeText(
                                            context,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            '  Edit',
                                            maxLines: 1, //  limits to 1 lines
                                            overflow: TextOverflow
                                                .ellipsis, // clips text if not fitting
                                            style: TextStyle(
                                              fontSize: TextSizing.fontSizeText(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: TextSizing.fontSizeText(context)),
                          ],
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

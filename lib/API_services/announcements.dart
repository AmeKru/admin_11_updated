import 'dart:convert';

import 'package:admin_11_updated/utils/text_sizing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => AnnouncementsPageState();
}

class AnnouncementsPageState extends State<AnnouncementsPage> {
  String news = '';
  bool _isLoading = false;
  final TextEditingController _newsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<dynamic> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: mergedHeaders);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: mergedHeaders,
          body: jsonEncode(body),
        );
        break;
      case 'PATCH':
        response = await http.patch(
          Uri.parse(url),
          headers: mergedHeaders,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: mergedHeaders);
        break;
      default:
        throw Exception('Invalid HTTP method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed request with status: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // To get the existing Announcement if it exists
  Future<void> getAnnouncement() async {
    try {
      setState(() {
        _isLoading = true;
        news = '';
      });

      final data = await _makeRequest(
        'GET',
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news?info=News',
      );

      if (kDebugMode) {
        print("Raw data from API: $data");
      }

      String fetchedNews = '';

      // Null or plain string
      if (data == null) {
        fetchedNews = '';
      } else if (data is String) {
        final trimmed = data.trim();
        fetchedNews = (trimmed.isNotEmpty && trimmed.toLowerCase() != 'news')
            ? trimmed
            : '';
      } else if (data is Map) {
        // Look only for explicit news/announcement keys (top-level or in common containers)
        dynamic candidate =
            data['news'] ??
            data['News'] ??
            data['announcement'] ??
            data['Announcement'];

        if (candidate == null) {
          final possibleContainers = ['Item', 'item', 'data', 'body'];
          for (final key in possibleContainers) {
            if (data.containsKey(key) && data[key] is Map) {
              final inner = data[key] as Map;
              candidate =
                  inner['news'] ??
                  inner['News'] ??
                  inner['announcement'] ??
                  inner['Announcement'];
              if (candidate != null) break;
            }
          }
        }

        if (candidate is String) {
          final trimmed = candidate.trim();
          fetchedNews = (trimmed.isNotEmpty && trimmed.toLowerCase() != 'news')
              ? trimmed
              : '';
        } else if (candidate is Map) {
          // DynamoDB-style attribute value handling
          final s = candidate['S'];
          if (s is String) {
            final trimmed = s.trim();
            fetchedNews =
                (trimmed.isNotEmpty && trimmed.toLowerCase() != 'news')
                ? trimmed
                : '';
          } else {
            fetchedNews = '';
          }
        } else {
          // Do NOT use a generic fallback that grabs any string from the map
          fetchedNews = '';
        }
      } else if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          final maybe =
              first['news'] ??
              first['News'] ??
              first['announcement'] ??
              first['Announcement'];
          if (maybe is String) {
            final trimmed = maybe.trim();
            fetchedNews =
                (trimmed.isNotEmpty && trimmed.toLowerCase() != 'news')
                ? trimmed
                : '';
          } else if (maybe is Map && maybe['S'] is String) {
            final trimmed = (maybe['S'] as String).trim();
            fetchedNews =
                (trimmed.isNotEmpty && trimmed.toLowerCase() != 'news')
                ? trimmed
                : '';
          } else {
            fetchedNews = '';
          }
        } else {
          // Avoid showing generic list values which may be the "info" marker
          fetchedNews = '';
        }
      } else {
        // Do not accept generic toString values as news
        fetchedNews = '';
      }

      if (fetchedNews.isEmpty) {
        if (kDebugMode) {
          print("No announcement text extracted from API response");
        }
      } else {
        if (kDebugMode) print("News captured: $fetchedNews");
      }

      if (mounted) {
        setState(() {
          news = fetchedNews;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in getNews: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // To delete Announcement

  Future<void> _deleteNews() async {
    try {
      await deleteData('News', 'news');
      await _loadData();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting trip: $e');
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////////
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

  /////////////////////////////////////////////////////////////////////////////
  // Delete existing Announcement

  Future<void> deleteData(String info, String updateKey) async {
    final url = Uri.parse(
      'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news?info=News',
    );

    final body = jsonEncode({'info': info, 'updateKey': updateKey});

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_AUTH_TOKEN', // Optional: include if your API requires authorization
        },
        body: body,
      );

      // Check the status code and handle the response
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

  /////////////////////////////////////////////////////////////////////////////
  // Update Data on server

  Future<void> patchData(String info, String updateKey, String newsText) async {
    // Try the endpoint that worked for delete (query param style)
    final base =
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news';
    final uriWithQuery = Uri.parse('$base?info=$info'); // e.g. ?info=News
    final payload = {'info': info, 'updateKey': updateKey, 'news': newsText};
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (kDebugMode) {
      print('PATCH attempt -> $uriWithQuery');
      print('Payload: $payload');
    }

    try {
      final resp = await http.patch(
        uriWithQuery,
        headers: headers,
        body: jsonEncode(payload),
      );
      if (kDebugMode) {
        print('http.patch status: ${resp.statusCode}');
        print('http.patch body: ${resp.body}');
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    } catch (e, st) {
      if (kDebugMode) {
        print('http.patch error: $e');
        print(st);
      }
    }

    throw Exception(
      'Update attempt failed; check server logs for required fields or mapping.',
    );
  }

  /////////////////////////////////////////////////////////////////////////////
  // Change Announcement

  void _showModifyDialog() {
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
            controller: _newsController,
            decoration: InputDecoration(
              hintText: 'Enter updated Announcement',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueGrey[500]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xff014689),
                  width: TextSizing.fontSizeMiniText(context) * 0.25,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: TextSizing.fontSizeText(context),
                  color: Color(0xff014689),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Capture everything from contexts BEFORE any await
                final NavigatorState navigator = Navigator.of(dialogContext);
                final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
                  context,
                );
                final String text = _newsController.text.trim();

                if (text.isEmpty) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text('Please enter an announcement'),
                      ),
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                setState(() => _isLoading = true);

                try {
                  // Use the exact server shape that worked
                  await patchData('News', 'news', text);

                  if (!mounted) {
                    // If widget was disposed while awaiting, just close the dialog via captured navigator
                    navigator.pop();
                    return;
                  }

                  // optimistic update
                  setState(() => news = text);

                  // optional verify refresh (awaiting here is okay because we already captured navigator and messenger)
                  await _loadData();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Center(child: Text('Announcement updated')),
                    ),
                  );

                  navigator.pop();
                  _newsController.clear();
                } catch (e, st) {
                  if (kDebugMode) {
                    print('Modify confirm error: $e');
                    print(st);
                  }
                  // Use captured messenger and navigator
                  messenger.showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text('Failed to update announcement'),
                      ),
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
                  color: Color(0xff014689),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /////////////////////////////////////////////////////////////////////////////

  Future<void> _loadData() async {
    await Future.wait([getAnnouncement()]);
  }

  /////////////////////////////////////////////////////////////////////////////

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
                                Text(
                                  'NP Announcements',
                                  style: TextStyle(
                                    fontSize: TextSizing.fontSizeHeading(
                                      context,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[900],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: TextSizing.fontSizeText(context)),
                            Center(
                              child: Text(
                                news.isNotEmpty
                                    ? news
                                    : 'No Announcements available',
                                style: TextStyle(
                                  fontSize: TextSizing.fontSizeText(context),
                                  fontWeight: FontWeight.normal,
                                  color: news.isNotEmpty
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
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
                                        size: TextSizing.fontSizeText(context),
                                      ),
                                      SizedBox(
                                        width: TextSizing.fontSizeMiniText(
                                          context,
                                        ),
                                      ),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: TextSizing.fontSizeText(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                ),
                                ElevatedButton(
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
                                        Icons.add_circle_rounded,
                                        size: TextSizing.fontSizeText(context),
                                      ),
                                      SizedBox(
                                        width: TextSizing.fontSizeMiniText(
                                          context,
                                        ),
                                      ),
                                      Text(
                                        'Modify',
                                        style: TextStyle(
                                          fontSize: TextSizing.fontSizeText(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
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

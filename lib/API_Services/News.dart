import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class News_Page extends StatefulWidget {
  const News_Page({super.key});

  @override
  State<News_Page> createState() => _News_PageState();
}

class _News_PageState extends State<News_Page> {

  String News = '';
  bool _isLoading = false;
  TextEditingController _newsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<dynamic> _makeRequest(String method, String url, {Map<String, String>? headers, dynamic body}) async {
    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(Uri.parse(url), headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Invalid HTTP method');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return decoded data
      } else {
        throw Exception('Failed request with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      rethrow;
    }
  }

  Future<void> getNews() async {
    try {
      setState(() {
        _isLoading = true;
      });
      News = '';

      var data = await _makeRequest(
        'GET',
        // 'https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/news?info=News',
        'https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news?info=News'
      );

      print("Raw data from API: $data");

      if (data is Map && data.containsKey('news')) {
        News = data['news']['S'];
        print("News captured: $News");
      } else {
        print("Unexpected data format: $data");
      }
    } catch (e) {
      print("Error in getNews: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteNews() async {
    try {
      await deleteData(
        'News',
        'news',
      );
      await _loadData();
    } catch (e) {
      print('Error deleting trip: $e');
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: TextStyle(fontSize: 35)),
          content: Text('Are you sure you want to delete this?', style: TextStyle(fontSize: 20)),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNews();
              },
              child: Text('Yes', style: TextStyle(fontSize: 20, color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No', style: TextStyle(fontSize: 20, color: Colors.deepPurple)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteData(String info, String updateKey) async {
    // final url = Uri.parse('https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/news');
    final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news');

    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
    });

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN' // Optional: include if your API requires authorization
        },
        body: body,
      );

      // Check the status code and handle the response
      if (response.statusCode == 200) {
        print('Data deleted successfully: ${response.body}');
      } else {
        print('Failed to delete data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error deleting data: $error');
    }
  }

  Future<void> patchData(String info, String updateKey, String news) async {
    // final url = Uri.parse('https://lrjwl7ccg1.execute-api.ap-southeast-2.amazonaws.com/prod/news');
    final url = Uri.parse('https://6f11dyznc2.execute-api.ap-southeast-2.amazonaws.com/prod/news');

    final body = jsonEncode({
      'info': info,
      'updateKey': updateKey,
      'news': news
    });

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Data modified successfully: ${response.body}');
      } else {
        print('Failed to modify data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error modifying data: $error');
    }
  }

  void _showModifyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modify News'),
          content: TextField(
            controller: _newsController,
            decoration: InputDecoration(
              hintText: 'Enter updated news',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_newsController.text.isNotEmpty) {
                  await patchData('News', 'news', _newsController.text);
                  await _loadData();
                  setState(() {
                    News = _newsController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    await Future.wait([
    getNews()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'NP News',
                    style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                    fontFamily: 'Aboreto'
                ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    News.isNotEmpty ? News : 'No news available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Row(
                children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.15),
                  TextButton(
                    onPressed: () {
                    _showDeleteConfirmationDialog(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 25, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(
                        fontSize: 20,
                        color: Colors.deepPurple
                        ),),
                      ],
                    ),
                  ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.3),
                  TextButton(
                    onPressed: () {
                      _showModifyDialog();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 25, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text('Modify', style: TextStyle(
                            fontSize: 20,
                            color: Colors.deepPurple
                        ),),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

}

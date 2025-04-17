import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  Future<Map<String, dynamic>>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');
    if (authKey == null || authKey.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    const String url = 'https://graphql.anilist.co';
    final Map<String, dynamic> body = {
      'query': '''
      query {
        Viewer {
          id
          name
          avatar {
            large
          }
        }
      }
    ''',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authKey',
      },
      body: jsonEncode(body),
    );
    
    //print(authKey);


    print("a request to the graphql has been made!!!!");


    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final viewer = data['data']['Viewer'];
      prefs.setInt('user_id', viewer['id']);
      return viewer;
    } else {
      throw Exception(
          'Failed to fetch user info: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Page",
          style: TextStyle(
            color: MyColors.appbarTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back, color: MyColors.appbarTextColor),
        ),
        backgroundColor: MyColors.appbarColor,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final userData = snapshot.data!;
            final userName = userData['name'] ?? "Unknown User";
            final userImage = userData['avatar']['large'] ??
                "https://www.strasys.uk/wp-content/uploads/2022/02/Depositphotos_484354208_S.jpg";
            final userId = userData['id'];

            return Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        child: Image.network(
                          userImage,
                          fit: BoxFit.fitHeight,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              "https://www.strasys.uk/wp-content/uploads/2022/02/Depositphotos_484354208_S.jpg",
                              fit: BoxFit.fitHeight,
                            );
                          },
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: MyColors.appbarTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userId.toString(),
                        style: TextStyle(
                          color: MyColors.appbarTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('auth_key', '');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.logout,
                          color: MyColors.appbarTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: Text(
                "No user data available.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }
}

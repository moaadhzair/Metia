import 'dart:convert';
//import 'dart:js_interop';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';

class AnilistApi {
  static const String auth_key =
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjQ3ZWQ2NzVjZWI2NDRjNTY0YTM2ZTE1NjgyNDZiYzRhNTkwMmQwMDk3MDBmZWI2ZjNkZjcyMGQ3MzU0ZjMzODFkNTkzZTE0OTZkYTA2MjJiIn0.eyJhdWQiOiIyNTU4OCIsImp0aSI6IjQ3ZWQ2NzVjZWI2NDRjNTY0YTM2ZTE1NjgyNDZiYzRhNTkwMmQwMDk3MDBmZWI2ZjNkZjcyMGQ3MzU0ZjMzODFkNTkzZTE0OTZkYTA2MjJiIiwiaWF0IjoxNzQzNDU4ODQyLCJuYmYiOjE3NDM0NTg4NDIsImV4cCI6MTc3NDk5NDg0Miwic3ViIjoiNzIxMjM3NiIsInNjb3BlcyI6W119.UyHJs0xhdBsu05_tqR3459oKFHFIRGME3kIe11Y5h-v6CUWDzIswyQAcJH6Voh3cDU_v3Rs2IXhNHvwf6_SDK4mJbp0ujqHl-F44EzQc6aCYSob-i8agbzMHmavM2buiBZFHGYmMpxIH4LT1fJH3qanVw098mM9OGTttZndL3OjiSxlEe5mSP7lzCajuPMC0kOsHHoTGrpRt2Z-FWu6S9hRcap1zi60IdqkomWNy82hU9woI1lSqK_J4AKFsCGBRUs85H1xyLD8z90nO77N0ybmLkIfgdBTh2aR9DU6N9B-X2OFkHQftNuzc_Kswi_W3SyyrQZEUnUXd2CURG3n5NeMSYC-y1hks4v3XLF_1u1rwa5mfYAqWy7AZ7onQJRcAzswFYw_by49ogN4GZmkB4Mo5TKshj7lElaqlDW1fXEXE9YLmDn7U20HrgX7pEnNnddQhObWiNSCEgoXvrvJNJheHmHxKCvLd5rN5z_hE8c-9WRcp61MwvgQYr0MEDx7F12SHO4krXCyWmgeKc-1DjTxwuclbCx4XbZ7te7hk2TUZzDt8RR9vI6dBrzXL20bvn-vTMX1cwL4OYrUxm5QHPeN5lFupZQzPXl8SFKvsp0aY06nV92vyuu_wsR7-jIZskoe2yuF0OI8nenUCsmlmnZpsL-UeMUD_7jRWRjX6Y3Y";

  static Future<Map<String, dynamic>> fetchUserAnimeList(int userId) async {
    const url = 'https://graphql.anilist.co';
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $auth_key', // Replace with your token
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      'query': '''
    query (\$type: MediaType!, \$userId: Int!) {
      MediaListCollection(type: \$type, userId: \$userId) {
        lists {
          name
          entries {
            id
            media {
              id
              title {
                  romaji
                  english
                  native
                }
              episodes
              averageScore
              coverImage {
                extraLarge
              }
            }
            progress
            status
          }
        }
      }
    }
  ''',
      "variables": {"type": "ANIME", "userId": userId},
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(response.body);
        throw Exception(
          'Failed to fetch user anime list: ${response.statusCode}',
        );
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  static Future<List<animeState>> fetchAnimeListofID(int userId) async {
    //final defaultSearch = await Setting.getdefaultSearch();
    final result = await fetchUserAnimeList(userId);
    //Tools.Toast(context, );
    //print("hereeee");
    var animeLib = animeLibrary();
    //print(jsonEncode(result["data"]["MediaListCollection"]["lists"]));

    for (var element in result["data"]["MediaListCollection"]["lists"]) {
      print(element["name"]);
      var State;
      switch(element["entries"].toString()){
        case "Completed":
          State = States.COMPLETED;
        case "Watching":
          State = States.WATCHING;
        case "Dropped":
          State = States.DROPPED;
        case "Paused":
          State = States.PAUSED;
        case "Planning":
          State = States.PLANNING;
        default:
          State = States.WATCHING;

      }
      final Anime = animeState(State, element["entries"]);
      animeLib.addAnime(Anime);
    }
    
    print(animeLib.lib);
    return animeLib.lib;
  }

  static Future<List<dynamic>> fetchAnimeList(BuildContext context) async {
    final defaultSearch = await Setting.getdefaultSearch();
    final result = await searchAnime(defaultSearch.toString());
    Tools.Toast(context, defaultSearch.toString());
    if (result.containsKey('data') &&
        result['data'].containsKey('Page') &&
        result['data']['Page'].containsKey('media')) {
      return result['data']['Page']['media'] as List<dynamic>;
    } else {
      throw Exception('Failed to parse anime list from response');
    }
  }

  static Future<Map<String, dynamic>> searchAnime(String animeName) async {
    const url = 'https://graphql.anilist.co';
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      "query": """
          query (\$search: String) {
            Page(page: 1, perPage: 30) {
              media(search: \$search, type: ANIME) {
                id
                title {
                  romaji
                  english
                  native
                }
                episodes
                averageScore
                coverImage {
                  extraLarge
                }
              }
            }
          }
        """,
      "variables": {"search": animeName},
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch anime data: ${response.statusCode}');
    }
  }
}

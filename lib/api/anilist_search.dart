import 'dart:convert';
import 'dart:ffi';
//import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnilistApi {
  static Future<Map<String, dynamic>> fetchUserAnimeList(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    if (authKey == null || authKey.isEmpty) {
      throw Exception('Please sign in to fetch your anime list.');
    }

    const String url = 'https://graphql.anilist.co';
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authKey',
      'Accept': 'application/json',
    };

    final String body = jsonEncode({
      'query': '''
    query (\$type: MediaType!, \$userId: Int!) {
      MediaListCollection(type: \$type, userId: \$userId, sort: UPDATED_TIME_DESC) {
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
              nextAiringEpisode {
                airingAt
                episode
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
        throw Exception('Failed to fetch anime list: ${response.statusCode}');
      }
    } catch (error) {
      // Rethrow the original exception without wrapping it
      rethrow;
    }
  }

  static Future<List<AnimeState>> fetchAnimeListofID(int userId) async {
    //final defaultSearch = await Setting.getdefaultSearch();
    final result = await fetchUserAnimeList(userId);
    //Tools.Toast(context, );
    var animeLib = AnimeLibrary();
    //print(jsonEncode(result["data"]["MediaListCollection"]["lists"]));
    for (var element in result["data"]["MediaListCollection"]["lists"]) {
      //print(element["name"]);
      String state = element["name"].toString().toUpperCase();




/*
      switch (element["name"].toString()) {
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
      }*/
      final Anime = AnimeState(state, element["entries"]);
      animeLib.addAnime(Anime);
    }
    List animes = [];
    for (AnimeState state in animeLib.lib) {
      if(state.state == "WATCHING"){
        for (var data in state.data) {
          if (data["media"]["nextAiringEpisode"] != null) {
            int episode = int.parse(data["media"]["nextAiringEpisode"]["episode"].toString());
            int progress = int.parse(data["progress"].toString());
            if(episode -1 > progress){
              animes.add(AnimeState("NEW EPISODE", [data]));
            }
          }
        }
      }
    }
    for (var anime in animes) {
      animeLib.addAnimes(0, anime);
    }

    //print(animeLib.lib);
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
    print("a request to the graphql has been made!!!!");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch anime data: ${response.statusCode}');
    }
  }
}

import 'dart:convert';
//import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnilistApi {
  static Future<List<Map<String, dynamic>>> fetchPopularAnime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      //'Authorization': 'Bearer $authKey',
      'Accept': 'application/json',
    };

    const String query = r'''
query {
  Page(perPage: 40) {
    media(type: ANIME, sort: POPULARITY_DESC) {
      averageScore
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
      }
      popularity
      episodes
      genres
      description(asHtml: false)
    }
  }
}
''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        print(response);
        return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)["data"]["Page"]["media"],
        );
      } else {
        throw Exception('Failed to fetch anime list: ${response.statusCode}');
      }
    } catch (error) {
      // Rethrow the original exception without wrapping it
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSearchAnime(
    String keyword,
  ) async {
    const String url = 'https://graphql.anilist.co';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      //'Authorization': 'Bearer $authKey',
      'Accept': 'application/json',
    };

    const String query = r'''
query ($search: String) {
  Page(perPage: 1000) {
    media(search: $search, type: ANIME, sort: POPULARITY_DESC, isAdult: false) {
      averageScore
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        extraLarge
      }
      episodes
      genres
      description(asHtml: false)
    }
  }
}

''';

    Map variables = {"search": keyword};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'query': query, "variables": variables}),
      );

      if (response.statusCode == 200) {
        print(response);
        return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)["data"]["Page"]["media"],
        );
      } else {
        throw Exception('Failed to fetch anime list: ${response.statusCode}');
      }
    } catch (error) {
      // Rethrow the original exception without wrapping it
      rethrow;
    }
  }

  static Future<void> updateAnimeTracking({
    required int mediaId,
    String? status, // e.g., "CURRENT", "COMPLETED"
    int? progress, // e.g., number of episodes watched
    double? score, // e.g., 8.5
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    const String mutation = r'''
      mutation($mediaId: Int, $status: MediaListStatus, $progress: Int, $score: Float) {
        SaveMediaListEntry(mediaId: $mediaId, status: $status, progress: $progress, score: $score) {
          id
          status
          progress
          score
        }
      }
    ''';

    final Map<String, dynamic> variables = {
      'mediaId': mediaId,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (score != null) 'score': score,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'query': mutation, 'variables': variables}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        print('AniList API Error: ${data['errors']}');
      } else {
        print('Tracking updated: ${data['data']['SaveMediaListEntry']}');
      }
    } else {
      print('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> fetchUserAnimeList(
    int userId,
    bool signedIn,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    if (signedIn == false) {
    } else if (authKey == null || authKey.isEmpty) {
      throw Exception('Please sign in to fetch your anime list.');
    }

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers;
    if (signedIn == true) {
      headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authKey',
        'Accept': 'application/json',
      };
    } else {
      headers = {
        'Content-Type': 'application/json',
        //'Authorization': 'Bearer $authKey',
        'Accept': 'application/json',
      };
    }

    final String body = jsonEncode({
      'query': '''
query (\$type: MediaType!, \$userId: Int!) {
      MediaListCollection(type: \$type, userId: \$userId, sort: UPDATED_TIME_DESC) {
        lists {
          name
          entries {
            id
            media {
              description
              genres
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

  static Future<List<AnimeState>> fetchAnimeListofID(
    int userId,
    bool signedIn,
  ) async {
    //final defaultSearch = await Setting.getdefaultSearch();
    final result = await fetchUserAnimeList(userId, signedIn);
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
      if (state.state == "WATCHING") {
        for (var data in state.data) {
          if (data["media"]["nextAiringEpisode"] != null) {
            int episode = int.parse(
              data["media"]["nextAiringEpisode"]["episode"].toString(),
            );
            int progress = int.parse(data["progress"].toString());
            if (episode - 1 > progress) {
              //animes.add(AnimeState("NEW EPISODE", [data]));
              animes.add(data);
            }
          }
        }
      }
    }

    if (animes.isNotEmpty) {
      animeLib.addAnimes(0, AnimeState("NEW EPISODE", animes));
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

  static Future<void> addAnimeToList(
    bool isCustomList,
    int mediaId,
    String statusList,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authKey',
      'Accept': 'application/json',
    };

    final String query =
        isCustomList
            ? '''
        mutation (
  \$id: Int,
  \$mediaId: Int,
  \$status: MediaListStatus,
  \$score: Float,
  \$progress: Int,
  \$progressVolumes: Int,
  \$repeat: Int,
  \$private: Boolean,
  \$notes: String,
  \$customLists: [String],
  \$hiddenFromStatusLists: Boolean,
  \$advancedScores: [Float],
  \$startedAt: FuzzyDateInput,
  \$completedAt: FuzzyDateInput
) {
  SaveMediaListEntry(
    id: \$id,
    mediaId: \$mediaId,
    status: \$status,
    score: \$score,
    progress: \$progress,
    progressVolumes: \$progressVolumes,
    repeat: \$repeat,
    private: \$private,
    notes: \$notes,
    customLists: \$customLists,
    hiddenFromStatusLists: \$hiddenFromStatusLists,
    advancedScores: \$advancedScores,
    startedAt: \$startedAt,
    completedAt: \$completedAt
  ) {
    id
    mediaId
    status
    score
    advancedScores
    progress
    progressVolumes
    repeat
    priority
    private
    hiddenFromStatusLists
    customLists
    notes
    updatedAt
    startedAt {
      year
      month
      day
    }
    completedAt {
      year
      month
      day
    }
    user {
      id
      name
    }
    media {
      id
      title {
        userPreferred
      }
      coverImage {
        large
      }
      type
      format
      status
      episodes
      volumes
      chapters
      averageScore
      popularity
      isAdult
      startDate {
        year
      }
    }
  }
}
      '''
            : '''
        mutation(\$mediaId: Int!, \$status: MediaListStatus) {
          SaveMediaListEntry(
            mediaId: \$mediaId,
            status: \$status
          ) {
            id
            mediaId
            status
          }
        }
      ''';

    final Map<String, dynamic> variables =
        isCustomList
            ? {
              "mediaId": mediaId,
              "status": "CURRENT", // or let user pick a status
              "customLists": [
                statusList,
              ], // statusList is your custom list name
            }
            : {
              "mediaId": mediaId,
              "status":
                  statusList == "WATCHING"
                      ? "CURRENT"
                      : statusList.toUpperCase(),
            };

    final String body = jsonEncode({'query': query, 'variables': variables});

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200)
      print(
        "Error: error encountered in the addAnimToList function from AnilistApi",
      );
  }

  static Future<void> createCustomList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authKey',
      'Accept': 'application/json',
    };

    List userAnimeLists = await getUserAnimeLists();
    List<String> userAnimeCustomLists =
        userAnimeLists
            .where((list) => list['isCustom'] == true)
            .map<String>((list) => list['name'] as String)
            .toList();

    userAnimeCustomLists.add(listName);

    final Map<String, dynamic> body = {
      'query': '''
      mutation(\$animeListOptions: MediaListOptionsInput) {
        UpdateUser(animeListOptions: \$animeListOptions) {
          id
        }
      }
    ''',
      'variables': {
        'animeListOptions': {'customLists': userAnimeCustomLists},
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('Custom list "$listName" added successfully.');
    } else {
      print('Failed to add custom list: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserAnimeLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authKey',
      },
      body: jsonEncode({
        'query': '''
        query {
          Viewer {
            mediaListOptions {
              animeList {
                customLists
              }
            }
          }
        }
      ''',
      }),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final customLists = List<String>.from(
      data['data']['Viewer']['mediaListOptions']['animeList']['customLists'],
    );

    final defaultLists = [
      {'name': 'WATCHING', 'isCustom': false},
      {'name': 'PLANNING', 'isCustom': false},
      {'name': 'COMPLETED', 'isCustom': false},
      {'name': 'DROPPED', 'isCustom': false},
      {'name': 'PAUSED', 'isCustom': false},
    ];

    final custom = customLists.map((name) => {'name': name, 'isCustom': true});

    return [...defaultLists, ...custom];
  }
}

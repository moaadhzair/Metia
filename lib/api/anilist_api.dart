import 'dart:async';
import 'dart:convert';
//import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnilistApi {
  static Future<bool> removeAnimeFromCustomList(int mediaId, String customListName, String statusName, int mediaListEntryId, bool isChanging) async {
    Map<String, dynamic>? animeEntryData = await getAnimeLists(mediaId);

    // Set the value of the customListName key to false in the customLists map
    if (animeEntryData != null && animeEntryData["customLists"] is List) {
      // Convert the list to a map for easier manipulation
      Map<String, bool> customListsMap = {for (var name in animeEntryData["customLists"]) name: true};
      customListsMap[customListName] = false;
      animeEntryData["customLists"] = customListsMap.entries.where((e) => e.value).map((e) => e.key).toList();
    }
    if (!isChanging) {
      if (animeEntryData!["customLists"].isNotEmpty) {
        await addAnimeToList(true, mediaId, animeEntryData["customLists"], statusName.isEmpty ? animeEntryData["status"] : statusName);
      } else {
        await deleteAnimeFromAll(mediaListEntryId);
      }
    } else {
      await addAnimeToList(true, mediaId, animeEntryData!["customLists"], statusName.isEmpty ? animeEntryData["status"] : statusName);
    }
    return true;
  }

  static Future<void> removeAnimeFromStatus(int mediaId, int mediaListEntryId) async {
    Map? data = await getAnimeLists(mediaId);
    if (data != null) {
      if (data["customLists"].isEmpty) {
        deleteAnime(mediaListEntryId, "");
      } else {
        changedAnimeVisibilityInStatus(mediaId, true);
      }
    } else {
      deleteAnime(mediaListEntryId, "");
    }
  }

  static Future<bool> deleteAnime(int id, String tabName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    // GraphQL mutation string
    const String mutation = r'''
      mutation($id: Int) {
        DeleteMediaListEntry(id: $id) {
          deleted
        }
      }
    ''';

    // Variables
    Map<String, dynamic> variables = {'id': id};

    // Construct body with mutation and variables
    Map<String, dynamic> body = {'query': mutation, 'variables': variables};

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final deleted = jsonData['data']?['DeleteMediaListEntry']?['deleted'];
        return deleted == true;
      } else {
        print('Failed to delete media list entry: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during deleteMediaListEntry: $e');
      return false;
    }
  }

  static Future<bool> deleteAnimeFromAll(int mediaListEntryId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    // GraphQL mutation string
    const String mutation = r'''
      mutation($id: Int) {
        DeleteMediaListEntry(id: $id) {
          deleted
        }
      }
    ''';

    // Variables
    Map<String, dynamic> variables = {'id': mediaListEntryId};

    // Construct body with mutation and variables
    Map<String, dynamic> body = {'query': mutation, 'variables': variables};

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final deleted = jsonData['data']?['DeleteMediaListEntry']?['deleted'];
        return deleted == true;
      } else {
        print('Failed to delete media list entry: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during deleteMediaListEntry: $e');
      return false;
    }
  }

  static Future<Map<String, Map<String, dynamic>>> fetchPopularAnime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    const String query = r'''
query (
  $season: MediaSeason,
  $seasonYear: Int,
  $nextSeason: MediaSeason,
  $nextYear: Int
) {
  trending: Page(page: 1, perPage: 30) {
    media(
      sort: TRENDING_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...media
    }
  }
  
  season: Page(page: 1, perPage: 30) {
    media(
      season: $season,
      seasonYear: $seasonYear,
      sort: POPULARITY_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...media
    }
  }
  
  nextSeason: Page(page: 1, perPage: 30) {
    media(
      season: $nextSeason,
      seasonYear: $nextYear,
      sort: POPULARITY_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...media
    }
  }
  
  popular: Page(page: 1, perPage: 30) {
    media(
      sort: POPULARITY_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...media
    }
  }
  
  top: Page(page: 1, perPage: 10) {
    media(
      sort: SCORE_DESC,
      type: ANIME,
      isAdult: false
    ) {
      ...media
    }
  }
}

fragment media on Media {
  id
  title {
    english
    romaji
    native
  }
  coverImage {
  large
  medium
    extraLarge
    color
  }
  bannerImage
  description
  episodes
  genres
  averageScore
  mediaListEntry {
    id
    status
  }
}

''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'variables': {"type": "ANIME", "season": "SPRING", "seasonYear": 2025, "nextSeason": "SUMMER", "nextYear": 2025},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)["data"];
        final trending = Map<String, dynamic>.from(data["trending"]);
        final season = Map<String, dynamic>.from(data["season"]);
        final nextSeason = Map<String, dynamic>.from(data["nextSeason"]);
        final popular = Map<String, dynamic>.from(data["popular"]);
        // Combine all lists into one
        return {"trending": trending, "popular": popular, "season": season, "nextSeason": nextSeason};
      } else {
        print('Failed to fetch anime list: ${response.statusCode}');
        return {};
      }
    } catch (error) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchSearchAnime(String keyword) async {
    const String url = 'https://graphql.anilist.co';
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    const String query = r'''
query ($search: String) {
  Page(perPage: 1000) {
    media(search: $search, type: ANIME, sort: POPULARITY_DESC, isAdult: false) {
    mediaListEntry{
        id
        status
        customLists
    }
      averageScore
      id
      title {
        romaji
        english
        native
      }
      coverImage {
      large
      medium
        extraLarge
      }
      duration
      episodes
      genres
      description(asHtml: false)
    }
  }
}

''';

    Map variables = {"search": keyword};

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode({'query': query, "variables": variables}));

      if (response.statusCode == 200) {
        return {
          "success": List<Map<String, dynamic>>.from(jsonDecode(response.body)["data"]["Page"]["media"]).isNotEmpty,
          "data": List<Map<String, dynamic>>.from(jsonDecode(response.body)["data"]["Page"]["media"]),
        };
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
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
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

  static Future<Map<String, dynamic>> fetchUserAnimeList(int userId, bool signedIn) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    if (signedIn == false) {
    } else if (authKey == null || authKey.isEmpty) {
      throw Exception('Please sign in to fetch your anime list.');
    }

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers;
    if (signedIn == true) {
      headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};
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
      MediaListCollection(type: \$type, userId: \$userId) {
        lists {
          name
          entries {
            id
            media {
            id
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
              large
                extraLarge
                medium
              }
              duration
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
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

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

  static Future<List<AnimeState>> fetchAnimeListofID(int userId, bool signedIn) async {
    final result = await fetchUserAnimeList(userId, signedIn);

    var animeLib = AnimeLibrary();

    // Collect all entries by list name
    Map<String, List<dynamic>> entriesByList = {};

    for (var element in result["data"]["MediaListCollection"]["lists"]) {
      String state = element["name"].toString();
      entriesByList[state] = element["entries"].reversed.toList();
    }

    // Get all user lists (default + custom)
    List<Map<String, dynamic>> allLists = await getUserAnimeLists();

    // Add AnimeState for each list, even if empty
    for (var list in allLists) {
      String listName = list['name'];
      var entries = entriesByList[listName] ?? [];
      animeLib.addAnime(AnimeState(listName, entries));
    }

    // Add "New Episode" logic as before
    List animes = [];
    for (AnimeState state in animeLib.lib) {
      if (!['Paused', 'Completed', 'Dropped'].contains(state.state)) {
        for (var data in state.data) {
          print("${state.state} is the state of ${data["media"]["title"]}");

          if (data["media"]["nextAiringEpisode"] != null) {
            int episode = int.parse(data["media"]["nextAiringEpisode"]["episode"].toString());
            int progress = int.parse(data["progress"].toString());
            if (episode - 1 > progress) {
              animes.add(data);
            }
          }
        }
      }
    }
    if (animes.isNotEmpty) {
      animeLib.addAnimes(0, AnimeState("New Episode", animes));
    }

    return animeLib.lib;
  }

  static Future<List<dynamic>> fetchAnimeList(BuildContext context) async {
    final defaultSearch = await Setting.getdefaultSearch();
    final result = await searchAnime(defaultSearch.toString());
    Tools.Toast(context, defaultSearch.toString());
    if (result.containsKey('data') && result['data'].containsKey('Page') && result['data']['Page'].containsKey('media')) {
      return result['data']['Page']['media'] as List<dynamic>;
    } else {
      throw Exception('Failed to parse anime list from response');
    }
  }

  static Future<Map<String, dynamic>> searchAnime(String animeName) async {
    const url = 'https://graphql.anilist.co';
    const headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

    final body = jsonEncode({
      "query": """
          query (\$search: String) {
            Page(page: 1, perPage: 30) {
              media(search: \$search, type: ANIME) {
                duration
                id
                title {
                  romaji
                  english
                  native
                }
                episodes
                averageScore
                coverImage {
                large
                medium
                  extraLarge
                }
                duration
              }
            }
          }
        """,
      "variables": {"search": animeName},
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch anime data: ${response.statusCode}');
    }
  }

  static Future<void> addAnimeToList(bool isCustomList, int mediaId, List<String> customList, String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

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
      duration
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
              if (listName.isNotEmpty) "status": listName.toUpperCase() == "WATCHING" ? "CURRENT" : listName.toUpperCase(),
              "customLists": customList,
              "hiddenFromStatusLists": listName.isEmpty,
              // statusList is your custom list name
            }
            : {"mediaId": mediaId, "status": listName.toUpperCase() == "WATCHING" ? "CURRENT" : listName.toUpperCase()};

    final String body = jsonEncode({'query': query, 'variables': variables});

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) print("Error: error encountered in the addAnimToList function from AnilistApi");
  }

  static Future<void> changedAnimeVisibilityInStatus(int mediaId, bool hidden) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    final Map<String, dynamic> body = {
      'query': '''
      mutation(
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
          hiddenFromStatusLists
        }
      }
    ''',
      'variables': {'mediaId': mediaId, 'hiddenFromStatusLists': hidden},
    };

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
    } else {
      throw Exception('Failed to change visibility: ${response.body}');
    }
  }

  static Future<List<String>> getAnimeCustomLists(int mediaId) async {
    Map<String, dynamic>? animeEntryData = await getAnimeLists(mediaId);
    List<String> customLists = animeEntryData != null ? animeEntryData["customLists"] : [];
    return customLists;
  }

  static Future<bool> addAnimeToStatus(int mediaId, String statusName) async {
    Map<String, dynamic>? animeEntryDetails = await getAnimeLists(mediaId);

    if (animeEntryDetails != null) {
      if (animeEntryDetails["customLists"].isEmpty) {
        if (!animeEntryDetails['hiddenFromStatusLists']) {
          await addAnimeToList(false, mediaId, [], statusName);
        } else {
          changedAnimeVisibilityInStatus(mediaId, false);
        }
        changedAnimeVisibilityInStatus(mediaId, false);
      } else {
        await addAnimeToList(true, mediaId, animeEntryDetails["customLists"], statusName);
      }
    } else {
      await addAnimeToList(false, mediaId, [], statusName);
    }

    return true;
  }

  static Future<void> addAnimeToCustomList(int mediaId, String customListName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    List<String> customLists = await getAnimeCustomLists(mediaId);
    customLists.add(customListName);

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    const String query = '''
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
      duration
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
      ''';

    final Map<String, dynamic> variables = {"mediaId": mediaId, "customLists": customLists, "hiddenFromStatusLists": true};

    final String body = jsonEncode({'query': query, 'variables': variables});

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) print("Error: error encountered in the addAnimToList function from AnilistApi");
  }

  static Future<void> deleteCustomList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    List userAnimeLists = await getUserAnimeLists();
    await Future.delayed(const Duration(seconds: 1));
    List<String> userAnimeCustomLists =
        userAnimeLists.where((list) => list['isCustom'] == true).map<String>((list) => list['name'] as String).toList();

    userAnimeCustomLists.remove(listName);

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
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
    } else {
      print('Failed to add custom list: ${response.body}');
    }
  }

  static Future<void> createCustomList(String listName, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    List userAnimeLists = await getUserAnimeLists();
    await Future.delayed(const Duration(seconds: 1));
    List<String> userAnimeCustomLists =
        userAnimeLists.where((list) => list['isCustom'] == true).map<String>((list) => list['name'] as String).toList();

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
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
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
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey'},
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

    if (response.statusCode != 200) {
      print(response.body);
      return [];
    }

    final data = jsonDecode(response.body);
    final customLists = List<String>.from(data['data']['Viewer']['mediaListOptions']['animeList']['customLists']);

    final defaultLists = [
      {'name': 'Watching', 'isCustom': false},
      {'name': 'Planning', 'isCustom': false},
      {'name': 'Completed', 'isCustom': false},
      {'name': 'Dropped', 'isCustom': false},
      {'name': 'Paused', 'isCustom': false},
    ];

    final custom = customLists.map((name) => {'name': name[0].toUpperCase() + name.substring(1), 'isCustom': true});

    final finalList = [...defaultLists, ...custom];

    return finalList;
  }

  static Future<Map<String, dynamic>?> getAnimeLists(int mediaId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    const String url = 'https://graphql.anilist.co';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey'},
      body: jsonEncode({
        'query': '''
        query(\$mediaId: Int) {
          Media(id: \$mediaId) {
            mediaListEntry {
              hiddenFromStatusLists
              status
              customLists
            }
          }
        }
      ''',
        'variables': {'mediaId': mediaId},
      }),
    );

    if (response.statusCode != 200) throw Exception("the request didnt return a 200 status code in AnilistApi.getAnimeLists");

    final json = jsonDecode(response.body);
    final entry = json['data']['Media']['mediaListEntry'];
    if (entry == null) return null;

    final status = entry['status'];
    final customListsMap = Map<String, dynamic>.from(entry['customLists'] ?? {});
    final activeCustomLists = customListsMap.entries.where((e) => e.value == true).map((e) => e.key).toList();

    return {'status': status, 'customLists': activeCustomLists, 'hiddenFromStatusLists': entry['hiddenFromStatusLists']};
  }

  static Future<void> changeFromCustomListToStatus(int mediaId, String customListName, String statusName) async {
    //await addAnimeToStatus(mediaId, statusName);
    await removeAnimeFromCustomList(mediaId, customListName, statusName, 0, true);
  }

  static Future<void> changeFromStatusToCustomList(int mediaId, String customListName) async {
    await addAnimeToCustomList(mediaId, customListName);
    await changedAnimeVisibilityInStatus(mediaId, true);
  }

  static Future<void> changeFromCustomListToCustomList(int mediaId, String firstcustomListName, String secondCustomList, int mediaListEntryId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? authKey = prefs.getString('auth_key');

    List<String> customLists = await getAnimeCustomLists(mediaId);
    customLists.add(secondCustomList);
    customLists.remove(firstcustomListName.toLowerCase());

    const String url = 'https://graphql.anilist.co';
    Map<String, String> headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $authKey', 'Accept': 'application/json'};

    const String query = '''
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
      duration
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
      ''';

    final Map<String, dynamic> variables = {"mediaId": mediaId, "customLists": customLists, "hiddenFromStatusLists": true};

    final String body = jsonEncode({'query': query, 'variables': variables});

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) print("Error: error encountered in the addAnimToList function from AnilistApi");
  }

  static Future<void> changeFromStatusToStatus(int mediaId, String secondStatus) async {
    await addAnimeToStatus(mediaId, secondStatus);
    //await removeAnimeFromStatus(mediaId, mediaListEntryId);
  }
}

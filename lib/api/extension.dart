import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Extension {
  final String title;
  final String iconUrl;
  final bool dub;
  final bool sub;
  final String language;
  int id = 0;
  final String episodeListApi;
  final String searchApi;
  final String streamDataApi;

  Extension({
    required this.streamDataApi,
    required this.title,
    required this.iconUrl,
    required this.dub,
    required this.sub,
    required this.language,
    required this.id,
    required this.episodeListApi,
    required this.searchApi,
  });

  Map<String, dynamic> toMap() {
    return {
      'streamDataApi': streamDataApi,
      'searchApi': searchApi,
      'episodeListApi': episodeListApi,
      'title': title,
      'iconUrl': iconUrl,
      'dub': dub,
      'sub': sub,
      'language': language,
      'id': id,
    };
  }

  /// Get list of episodes for a given show
  Future<List<dynamic>> getEpisodeList(String sessionId) async {
    //TODO: i'll implement it later
    final response = await http.get(Uri.parse(episodeListApi + sessionId));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data;
    }
    return [];
  }

  /// Search for shows or episodes
  Future<List<dynamic>> search(String query) async {
    //TODO: i'll implement it later
    final response = await http.get(
      Uri.parse(searchApi + Uri.encodeComponent(query)),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data;
    }
    return [];
  }

  /// Get streaming link for a specific episode
  Future<List<dynamic>> getStreamData(String episodeId) async {
    //TODO: i'll implement it later
    final response = await http.get(Uri.parse(streamDataApi + episodeId));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data;
    }
    return [];
  }

  bool hasId() {
    return id != 0;
  }
}

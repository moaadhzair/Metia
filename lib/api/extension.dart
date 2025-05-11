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
  

  Extension({
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
      'searchApi' : searchApi,
      'episodeListApi' : episodeListApi,
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
    return [
      {
        "cover" : null,
        "name" : "haha",
        "link" : null,
        "id" : "0",
        "dub" : true,
        "sub" : true,
      },{
        "cover" : null,
        "name" : "idk",
        "link" : null,
        "id" : "1",
        "dub" : true,
        "sub" : true,
      },{
        "cover" : null,
        "name" : "well",
        "link" : null,
        "id" : "2",
        "dub" : true,
        "sub" : true,
      },{
        "cover" : null,
        "name" : "that",
        "link" : null,
        "id" : "3",
        "dub" : false,
        "sub" : true,
      },{
        "cover" : null,
        "name" : "was",
        "link" : null,
        "id" : "4",
        "dub" : false,
        "sub" : true,
      },
      
    ];
  }

  /// Search for shows or episodes
  Future<List<dynamic>> search(String query) async {
    //TODO: i'll implement it later
    final response = await http.get(Uri.parse(searchApi + Uri.encodeComponent(query)));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data;
    }
    return [];
  }

  /// Get streaming link for a specific episode
  Future<Map<String, dynamic>> getStreamLink(String episodeId) async {
    //TODO: i'll implement it later
    await Future.delayed(const Duration(milliseconds: 100));
    return {};
  }

  bool hasId() {
    return id != 0;
  }
}

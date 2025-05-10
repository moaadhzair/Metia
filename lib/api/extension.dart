import 'dart:async';

class Extension {
  final String title;
  final String iconUrl;
  final bool dub;
  final bool sub;
  final String language;
  int id = 0;
  final String episodeListApi;

  Extension({
    required this.title,
    required this.iconUrl,
    required this.dub,
    required this.sub,
    required this.language,
    required this.id,
    required this.episodeListApi,
  });

  Map<String, dynamic> toMap() {
    return {
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
  Future<List<Map<String, dynamic>>> getEpisodeList(String showId) async {
    //TODO: i'll implement it later
    await Future.delayed(const Duration(milliseconds: 100));
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
  Future<List<Map<String, dynamic>>> search(String query) async {
    //TODO: i'll implement it later
    await Future.delayed(const Duration(milliseconds: 100));
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

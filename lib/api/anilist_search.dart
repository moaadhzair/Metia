import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';


class AnilistApi{
    
    
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
        "variables": {"search": animeName}
      });

      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch anime data: ${response.statusCode}');
      }
    }
}
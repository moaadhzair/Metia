import 'package:flutter/material.dart';
import 'package:metia/tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting {
  static String defaultSearch = "naruto";
  static String posterUrl = "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx176496-xCNtU4llsUpu.png";

  static Future<void> savePosterUrl(BuildContext context, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("poster_url", value);
    Tools.Toast(context, "saved: $value");

  }
  static Future<String?> getPosterUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("poster_url")) {
      return prefs.getString("poster_url");
    }
    return posterUrl;
  }
  static Future<void> savedefaultSearch(BuildContext context, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("search_url", value);
    Tools.Toast(context, "saved: $value");

  }
  static Future<String?> getdefaultSearch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("search_url")) {
      return prefs.getString("search_url");
    }
    return defaultSearch;
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';
import 'package:http/http.dart' as http;


class Tools 
{
  static Future<String> fetchAniListAccessToken(String authorizationCode) async {
    final Uri tokenEndpoint = Uri.https('anilist.co', '/api/v2/oauth/token');
    final Map<String, String> payload = {
      'grant_type': 'authorization_code',
      'client_id': '25588',
      'client_secret': 'QCzgwOKG6kJRzRL91evKRXXGfDCHlmgXfi44A0Ok',
      'redirect_uri': 'metia://',
      'code': authorizationCode,
    };

    try {
      final http.Response response = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['access_token'] as String;
      } else {
        throw Exception('Failed to retrieve access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  static void Toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: MyColors.appbarTextColor,
              fontSize: 16,
            ),
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: MyColors.appbarColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  static getResponsiveCrossAxisVal(double width, {required double itemWidth}) {
    return (width / itemWidth).floor().clamp(1, 17);
  }

  static String insertAt(String original, String toInsert, int index) {
    if (index < 0 || index > original.length) {
      throw ArgumentError("Index out of range");
    }
    return original.substring(0, index) + toInsert + original.substring(index);
  }
}

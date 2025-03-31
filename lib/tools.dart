import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';

class Tools {
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

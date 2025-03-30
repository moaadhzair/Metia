import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: MyColors.appbarTextColor),
        leading: Row(
          children: [
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.arrow_back, color: MyColors.appbarTextColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: MyColors.appbarTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: MyColors.appbarColor,
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, color: MyColors.appbarTextColor),
          ),
        ),
      ),
    );
  }
}

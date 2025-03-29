import 'dart:math';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {

  Map<String, Color> MyColors = {
    "AppbarTextColor":  Color(0xFF98CAFE),
    "AppbarColor":  Color(0xFF15121B),
    "UnselectedColor":  Color(0xFF9A989B),
  };

  List<String> tabs = [
    "WATCHING",
    "COMPLETED TV",
    "COMPLETED MOVIE",
    "COMPLETED OVA",
    "COMPLETED SPECIAL",
    "PAUSED",
    "DROPPED",
    "PLANNING",
    "REWATCHING",
    "ALL",
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 10,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            actionsPadding: EdgeInsets.only(top: 0),
            actions: [
              IconButton(
                icon:  Icon(Icons.settings,size: 30,color: MyColors["UnselectedColor"],),
                onPressed: () {
                  // Handle search action
                },
              ),
              SizedBox(
                width: 10,
              ),
              IconButton(
                icon:  Icon(Icons.refresh,size: 30,color: MyColors["UnselectedColor"],),
                onPressed: () {
                  // Handle search action
                },
              ),
              SizedBox(
                width: 0,
              ),
            ],
            backgroundColor: MyColors["AppbarColor"],
            title: Center(child: Text("Anime List", style: TextStyle(color: MyColors["AppbarTextColor"], fontSize: 20,fontWeight: FontWeight.bold,))),
            bottom: TabBar(
              indicatorColor: MyColors["AppbarTextColor"],
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: MyColors["AppbarTextColor"], // Color for the selected tab text
              unselectedLabelColor: MyColors["UnselectedColor"], // Color for unselected tab text
              tabs:
                  tabs.map((String tabName) {
                    return Tab(
                      
                      child: Text(
                        tabName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          body: Container(),
        ),
      ),
    );
  }
}

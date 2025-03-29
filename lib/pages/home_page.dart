import 'dart:math';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            
            backgroundColor: const Color(0xFF15121B),
            title: Center(child: const Text("Anilist List", style: TextStyle(color: Color(0xFF98CAFE), fontSize: 20,fontWeight: FontWeight.bold,))),
            bottom: TabBar(
              
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Color(0xFF98CAFE), // Color for the selected tab text
              unselectedLabelColor: Color(0xFF9A989B), // Color for unselected tab text
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

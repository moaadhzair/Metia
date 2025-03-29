import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, Color> MyColors = {
    "AppbarTextColor": Color(0xFF98CAFE),
    "AppbarColor": Color(0xFF15121B),
    "UnselectedColor": Color(0xFF9A989B),
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
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 10,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: Row(
              children: [
                SizedBox(width: 20),
                SvgPicture.asset(
                  'assets/icons/anilist.svg',
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    MyColors["AppbarTextColor"]!,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 30,
                  color: MyColors["UnselectedColor"],
                ),
                onPressed: () {
                  // Handle search action
                },
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 30,
                  color: MyColors["UnselectedColor"],
                ),
                onPressed: () {
                  // Handle search action
                },
              ),
              SizedBox(width: 0),
            ],
            backgroundColor: MyColors["AppbarColor"],
            title: Row(
              children: [
                SizedBox(width: 20),
                Text(
                  "Metia",
                  style: TextStyle(
                    color: MyColors["AppbarTextColor"],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              dividerColor: Color.fromARGB(255, 69, 69, 70),
              indicatorColor: MyColors["AppbarTextColor"],
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor:
                  MyColors["AppbarTextColor"], // Color for the selected tab text
              unselectedLabelColor:
                  MyColors["UnselectedColor"], // Color for unselected tab text
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
          body: TabBarView(
            children:
                tabs.map((String tabName) {
                  return Container(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(0),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: getResponsiveCrossAxisVal(
                          MediaQuery.of(context).size.width,
                          itemWidth: 108,
                        ),
                        mainAxisExtent: 250,
                        crossAxisSpacing: 0,
                      ),
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            child: Image(
                              image: Image.network("https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx176496-xCNtU4llsUpu.png").image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
  getResponsiveCrossAxisVal(double width, {required int itemWidth}) {
    return (width / itemWidth).floor().clamp(1, 10);
  }
}

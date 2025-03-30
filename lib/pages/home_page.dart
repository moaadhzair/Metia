import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/pages/settings_page.dart';

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
    return DefaultTabController(
      length: 10,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: MyColors.appbarColor,
          leading: Row(
            children: [
              SizedBox(width: 20),
              SvgPicture.asset(
                'assets/icons/anilist.svg',
                height: 30,
                colorFilter: ColorFilter.mode(
                  MyColors.appbarTextColor!,
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
                color: MyColors.unselectedColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 30,
                color: MyColors.unselectedColor,
              ),
              onPressed: () {
                Toast(context, "Refreshing...");
              },
            ),
            SizedBox(width: 0),
          ],
          title: Row(
            children: [
              SizedBox(width: 20),
              Text(
                "Metia",
                style: TextStyle(
                  color: MyColors.appbarTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            dividerColor: Color.fromARGB(255, 69, 69, 70),
            indicatorColor: MyColors.appbarTextColor,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MyColors.appbarTextColor,
            unselectedLabelColor: MyColors.unselectedColor,
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: getResponsiveCrossAxisVal(
                        MediaQuery.of(context).size.width,
                        itemWidth: 460 / 4,
                      ),
                      mainAxisExtent: 650 / 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Toast(context, "Clicked on $tabName at index $index");
                        },
                        child: Image(
                          fit: BoxFit.fitHeight,
                          image:
                              Image.network(
                                "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx176496-xCNtU4llsUpu.png",
                              ).image,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  void Toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(message, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: MyColors.appbarTextColor,
                fontSize: 16,
              )),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: MyColors.appbarColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  getResponsiveCrossAxisVal(double width, {required double itemWidth}) {
    return (width / itemWidth).floor().clamp(1, 10);
  }
}

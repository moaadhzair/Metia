import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:metia/api/anilist_search.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> tabs = [
    "COMPLETED",
    "WATCHING",
    "PAUSED",
    "DROPPED",
    "PLANNING",
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: MyColors.backgroundColor,
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
                setState(() {
                  Tools.Toast(context, "Refreshing...");
                });
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<animeState>>(
            future: AnilistApi.fetchAnimeListofID(
              7212376,
            ), // Fetch data asynchronously
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No data available"));
              } else {
                final animeLibrary = snapshot.data!;

                return TabBarView(
                  children:
                      animeLibrary.map((animeState state) {
                        return Container(
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      Tools.getResponsiveCrossAxisVal(
                                        MediaQuery.of(context).size.width,
                                        itemWidth: 460 / 4,
                                      ),
                                  mainAxisExtent: 250,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.7,
                                ),
                            itemCount: state.data.length,
                            itemBuilder: (context, index) {
                               return AnimeCard(
                                  index: index,
                                  tabName:
                                      state
                                          .state
                                          .name, // Convert enum to string
                                  data: state.data[index],
                                );
                              // Avoid returning null
                            },
                          ),
                        );
                      }).toList(),
                );
              }
            },
          ),
        ),
      ),
      //),
    );
  }
}

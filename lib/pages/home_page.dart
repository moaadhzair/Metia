import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/api/anilist_search.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> tabs = [
    "WATCHING",
    "COMPLETED",
    "PAUSED",
    "DROPPED",
    "PLANNING",
  ];

  List<int> itemCounts = [0, 0, 0, 0, 0];

  List<animeState>? _animeLibrary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnimeLibrary();
  }

  void _fetchAnimeLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AnilistApi.fetchAnimeListofID(7212376);
      setState(() {
        _animeLibrary = data;
        for (int i = 0; i < _animeLibrary!.length; i++) {
          itemCounts[i] = _animeLibrary![i].data.length;
          tabs[i] = "${tabs[i].split('(')[0]}(${itemCounts[i]})";
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: MyColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: MyColors.appbarColor,
          leading: Row(
            children: [
              const SizedBox(width: 20),
              SvgPicture.asset(
                'assets/icons/anilist.svg',
                height: 30,
                colorFilter: const ColorFilter.mode(
                  MyColors.appbarTextColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
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
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(
                Icons.refresh,
                size: 30,
                color: MyColors.unselectedColor,
              ),
              onPressed: () {
                Tools.Toast(context, "Refreshing...");
                _fetchAnimeLibrary(); // Refetch on refresh
              },
            ),
            const SizedBox(width: 0),
          ],
          title: const Row(
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
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: const Color.fromARGB(255, 69, 69, 70),
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
          padding: const EdgeInsets.only(top: 8),
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                    child: Text(
                      "Error: $_error",
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                  : TabBarView(
                    children:
                        _animeLibrary!.map((animeState state) {
                          return GridView.builder(
                            cacheExtent: 500,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      Tools.getResponsiveCrossAxisVal(
                                        MediaQuery.of(context).size.width,
                                        itemWidth: 460 / 4,
                                      ),
                                  mainAxisExtent: 260,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.7,
                                ),
                            itemCount: state.data.length,
                            itemBuilder: (context, index) {
                              return AnimeCard(
                                index: index,
                                tabName: state.state.name,
                                data: state.data[index],
                              );
                            },
                          );
                        }).toList(),
                  ),
        ),
      ),
    );
  }
}

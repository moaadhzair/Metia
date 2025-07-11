import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/pages/extensions_page.dart';
import 'package:metia/pages/search_page.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/pages/user_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';
import 'package:app_links/app_links.dart';
import 'package:metia/widgets/anime_card3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AppLinks _appLinks = AppLinks();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late TabController mainController;

  late TextEditingController _searchController;

  bool _isPopupMenuOpen = false;
  double _blurOpacity = 0.0;

  List<String> tabs = [];
  int oldIndexTabController = 0;

  List<int> itemCounts = [];

  List<AnimeState>? _animeLibrary;
  bool _loading = true;
  String? _error;

  Color _previousTabColor = MyColors.appbarTextColor;

  int currentIndex = 0;

  List<Map<String, dynamic>> searchAnimeData = [];
  Map<String, Map<String, dynamic>> popularAnimeData = {};
  bool isSearching = false;
  final bool _searchEnded = true;
  String searchTabHeaderText = "Popular right now:";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Safe default
    mainController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _initDeepLinking();
    _fetchAnimeLibrary(false);
    _fetchPopularAnime();

    mainController.addListener(() {
      if (mainController.index != currentIndex) {
        setState(() {
          currentIndex = mainController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    mainController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    if (_animeLibrary != null) {
      int oldIndex = _tabController.index;

      _tabController.dispose();

      int newLength = _animeLibrary!.length;
      _tabController = TabController(length: newLength, vsync: this);

      int newIndex = oldIndex;

      _tabController.index = newIndex;

      _tabController.addListener(() {
        setState(() {
          _previousTabColor = _getTabBorderColor(_tabController.previousIndex);
        });
      });
    }
  }

  Future<String> fetchAniListAccessToken(String authorizationCode) async {
    final Uri tokenEndpoint = Uri.https('anilist.co', '/api/v2/oauth/token');
    final Map<String, String> payload = {
      'grant_type': 'authorization_code',
      'client_id': '25588',
      'client_secret': 'QCzgwOKG6kJRzRL91evKRXXGfDCHlmgXfi44A0Ok',
      'redirect_uri': 'metia://',
      'code': authorizationCode,
    };

    try {
      final http.Response response = await http.post(tokenEndpoint, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));

      print("A request to the AniList API has been made!");

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

  Future<void> _initDeepLinking() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      // Handle initial link if needed
    }

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        String code = uri.toString().substring(uri.toString().indexOf('code=') + 5);
        fetchAniListAccessToken(code)
            .then((accessToken) {
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('auth_key', accessToken);
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPage()));
                }
              });
            })
            .catchError((error) {
              print("Error fetching access token: $error");
            });
      }
    });
  }

  Future<void> _fetchAnimeLibrary(bool isrefreshing) async {
    setState(() {
      _loading = isrefreshing ? false : true;
      _error = null;
    });

    try {
      await Setting.getuseSettingsUserId();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final customUserId = prefs.getInt("custom_user_id") ?? 0;
      List<AnimeState> data;

      if (Setting.useSettingsUserId) {
        data = await AnilistApi.fetchAnimeListofID(customUserId, false);
        print("custom");
      } else {
        print("loged in");
        data = await AnilistApi.fetchAnimeListofID(userId, true);
      }

      _animeLibrary = List.empty();
      tabs = List.empty();

      if (data.isEmpty) {
        throw Exception("empty library");
      }

      itemCounts = List.empty(growable: true);
      tabs = List.empty(growable: true);
      for (var state in data) {
        itemCounts.add(0);
        tabs.add(state.state.toString());
      }

      setState(() {
        _animeLibrary = data;
        for (int i = 0; i < _animeLibrary!.length; i++) {
          itemCounts[i] = _animeLibrary![i].data.length;
          tabs[i] = "${tabs[i].split('(')[0]} (${itemCounts[i]})";
        }
        _loading = false;
        _updateTabController();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchPopularAnime() async {
    AnilistApi.fetchPopularAnime().then((data) {
      setState(() {
        popularAnimeData = data;
        isSearching = false;
        searchTabHeaderText = "Popular right now:";
      });
      _precachePopularImages(); // <-- Call here, after setState
    });
  }

  Color _getTabBorderColor(int index) {
    if (_animeLibrary == null) return MyColors.appbarTextColor;
    final state = _animeLibrary![index].state;
    if (state == "New Episode") return Colors.orange;
    if (state == "Watching") return Colors.green;
    return MyColors.appbarTextColor;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape || MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Scaffold(
          bottomNavigationBar:
              isLandscape
                  ? null
                  : Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent, splashColor: Colors.transparent),
                    child: BottomNavigationBar(
                      selectedItemColor: MyColors.coolPurple,
                      backgroundColor: MyColors.coolPurple2,
                      onTap: (index) {
                        setState(() {
                          currentIndex = index;
                          mainController.animateTo(index);
                        });
                      },
                      currentIndex: currentIndex,
                      unselectedItemColor: const Color.fromARGB(255, 105, 105, 105),
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Library"),
                        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                        BottomNavigationBarItem(icon: Icon(Icons.save), label: "Downloads"),
                      ],
                    ),
                  ),
          backgroundColor: MyColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: MyColors.backgroundColor,
            leading: Row(
              children: [
                const SizedBox(width: 20),
                SvgPicture.asset(
                  'assets/icons/anilist.svg',
                  height: 35,
                  colorFilter: const ColorFilter.mode(MyColors.appbarTextColor, BlendMode.srcIn),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Theme(
                  data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                  child: PopupMenuButton<String>(
                    splashRadius: 1,
                    color: MyColors.backgroundColor,
                    tooltip: "",
                    icon: const Icon(Icons.more_vert, color: MyColors.appbarTextColor, size: 29),
                    onOpened: () {
                      setState(() {
                        _isPopupMenuOpen = true;
                        _blurOpacity = 1.0;
                      });
                    },
                    onCanceled: () {
                      setState(() {
                        _isPopupMenuOpen = false;
                        _blurOpacity = 0.0;
                      });
                    },
                    constraints: const BoxConstraints(maxWidth: 160),
                    itemBuilder:
                        (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            onTap: () {
                              Tools.Toast(context, "Refreshing...");
                              _fetchAnimeLibrary(false);
                            },
                            height: 35,
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 30, color: MyColors.unselectedColor),
                                SizedBox(width: 10),
                                Text("Refresh", style: TextStyle(color: MyColors.unselectedColor, fontSize: 17, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 10),
                          PopupMenuItem<String>(
                            height: 35,
                            child: const Row(
                              children: [
                                Icon(Icons.extension, size: 30, color: MyColors.unselectedColor),
                                SizedBox(width: 10),
                                Text("Extensions", style: TextStyle(color: MyColors.unselectedColor, fontSize: 17, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            onTap: () {
                              if (mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ExtensionsPage()));
                              }
                            },
                          ),
                          const PopupMenuDivider(height: 10),
                          PopupMenuItem<String>(
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final authCode = prefs.getString('auth_key');
                              if (authCode != null && authCode.isNotEmpty) {
                                if (mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPage()));
                                }
                              } else {
                                await _launchUrl(
                                  Uri.parse("https://anilist.co/api/v2/oauth/authorize?client_id=25588&redirect_uri=metia://&response_type=code"),
                                );
                              }
                            },
                            height: 35,
                            child: const Row(
                              children: [
                                Icon(Icons.login, size: 30, color: MyColors.unselectedColor),
                                SizedBox(width: 10),
                                Text("Login", style: TextStyle(color: MyColors.unselectedColor, fontSize: 17, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ],
            title: const Row(
              children: [
                SizedBox(width: 20),
                Text("Metia", style: TextStyle(color: MyColors.appbarTextColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                isLandscape
                    ? Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent, splashColor: Colors.transparent),
                      child: NavigationRail(
                        indicatorColor: MyColors.coolPurple2,
                        backgroundColor: MyColors.backgroundColor,
                        selectedLabelTextStyle: const TextStyle(color: MyColors.coolPurple, fontSize: 16, fontWeight: FontWeight.w500),
                        unselectedLabelTextStyle: const TextStyle(color: MyColors.unselectedColor, fontSize: 16, fontWeight: FontWeight.w500),
                        selectedIndex: currentIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            currentIndex = index;
                            mainController.animateTo(index);
                          });
                        },
                        labelType: NavigationRailLabelType.selected,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.video_library, color: MyColors.unselectedColor),
                            selectedIcon: Icon(Icons.video_library, color: MyColors.coolPurple),
                            label: Text("Library"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.search, color: MyColors.unselectedColor),
                            selectedIcon: Icon(Icons.search, color: MyColors.coolPurple),
                            label: Text("Search"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.save, color: MyColors.unselectedColor),
                            selectedIcon: Icon(Icons.save, color: MyColors.coolPurple),
                            label: Text("Downloads"),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox(),
                Expanded(
                  child: TabBarView(
                    controller: mainController,
                    children: [
                      // library
                      (tabs.isNotEmpty
                          ? Column(
                            children: [
                              
                              TweenAnimationBuilder<Color?>(
                                tween: ColorTween(begin: _previousTabColor, end: _getTabBorderColor(_tabController.index)),
                                duration: kTabScrollDuration,
                                builder: (context, color, child) {
                                  return TabBar(
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                                    controller: _tabController,
                                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                                    indicator: UnderlineTabIndicator(
                                      borderSide: BorderSide(width: 3, color: color ?? MyColors.appbarTextColor),
                                      insets: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    labelColor: MyColors.appbarTextColor,
                                    unselectedLabelColor: MyColors.unselectedColor,
                                    tabs:
                                        tabs.map((String tabName) {
                                          return Tab(
                                            child: Text(
                                              tabName,
                                              style: TextStyle(
                                                color:
                                                    tabName.startsWith("New Episode")
                                                        ? Colors.orange
                                                        : tabName.startsWith("Watching")
                                                        ? Colors.green
                                                        : null,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    //horizontal: MediaQuery.orientationOf(context) == Orientation.landscape ? 40 : 0,
                                  ),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children:
                                        _animeLibrary!.map((AnimeState state) {
                                          return Platform.isIOS
                                              ? CupertinoTheme(
                                                data: const CupertinoThemeData(primaryColor: MyColors.appbarTextColor),
                                                child: Padding(
                                                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                                                  child: CustomScrollView(
                                                    slivers: [
                                                      CupertinoSliverRefreshControl(
                                                        onRefresh: () async {
                                                          await _fetchAnimeLibrary(true);
                                                        },
                                                      ),
                                                      SliverGrid(
                                                        key: PageStorageKey('library ${state.state}'),

                                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                                            MediaQuery.of(context).size.width,
                                                            itemWidth: 135,
                                                          ),
                                                          mainAxisExtent: /*state.state == "New Episode" ? 283 :*/ 268,
                                                          crossAxisSpacing: 10,
                                                          mainAxisSpacing: 10,
                                                          childAspectRatio: 0.7,
                                                        ),
                                                        delegate: SliverChildBuilderDelegate((context, index) {
                                                          return AnimeCard(
                                                            key: ValueKey(state.data[index]["id"]),
                                                            index: index,
                                                            tabName: state.state,
                                                            data: state.data[index],

                                                            onLibraryChanged: () {
                                                              print("a new anime is added or removed");
                                                              _fetchAnimeLibrary(false);
                                                              _fetchPopularAnime();
                                                            },
                                                          );
                                                        }, childCount: state.data.length),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              : RefreshIndicator.adaptive(
                                                backgroundColor: MyColors.backgroundColor,
                                                strokeWidth: 3,
                                                color: MyColors.appbarTextColor,
                                                onRefresh: () async {
                                                  await _fetchAnimeLibrary(true);
                                                },
                                                child: ScrollConfiguration(
                                                  behavior: ScrollConfiguration.of(
                                                    context,
                                                  ).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                                                    child: GridView.builder(
                                                      key: PageStorageKey('library ${state.state}'),

                                                      controller: _scrollController,
                                                      cacheExtent: 500,
                                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                                          MediaQuery.of(context).size.width,
                                                          itemWidth: 135,
                                                        ),
                                                        mainAxisExtent:
                                                            /*state.state == "New Episode" ? 283 : */
                                                            268,
                                                        crossAxisSpacing: 10,
                                                        mainAxisSpacing: 10,
                                                        childAspectRatio: 0.7,
                                                      ),
                                                      itemCount: state.data.length,
                                                      itemBuilder: (context, index) {
                                                        return AnimeCard(
                                                          key: ValueKey(state.data[index]["id"]),

                                                          index: index,
                                                          tabName: state.state,
                                                          data: state.data[index],

                                                          onLibraryChanged: () {
                                                            print("a new anime is added or removed");
                                                            _fetchAnimeLibrary(false);
                                                            _fetchPopularAnime();
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error == "Exception: Please sign in to fetch your anime list."
                          ? Center(
                            child: GestureDetector(
                              onTap: () async {
                                await _launchUrl(
                                  Uri.parse("https://anilist.co/api/v2/oauth/authorize?client_id=25588&redirect_uri=metia://&response_type=code"),
                                );
                              },
                              child: const Text(
                                "Sign In To Track Your Progress",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.bold, fontSize: 25),
                              ),
                            ),
                          )
                          : _error == "Exception: Failed to fetch anime list: 429"
                          ? const Center(
                            child: Text(
                              "Your IP got blocked because you made way too many requests.\nWait for 2 minutes and then Refresh, The ban should go away",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                          )
                          : _error == "Exception: empty library"
                          ? const Center(
                            child: Text(
                              "you dumb, you have no anime in your Anilist library!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                          )
                          : Center(
                            child: Text(
                              _error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                          )),
                      // search page
                      _buildExplorerPage(),
                      _buildDownloadPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !_isPopupMenuOpen,
          child: AnimatedOpacity(
            curve: Curves.easeOutBack,
            opacity: _blurOpacity,
            duration: _isPopupMenuOpen ? const Duration(milliseconds: 333) : const Duration(milliseconds: 533),
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: Colors.black.withOpacity(0.2))),
          ),
        ),
      ],
    );
  }

  void _precachePopularImages() {
    if (!mounted) return;
    final ctx = context;
    for (final key in ["trending", "season", "nextSeason"]) {
      final mediaList = popularAnimeData[key]?["media"];
      if (mediaList != null) {
        for (var anime in mediaList) {
          final url = anime["coverImage"]?["extraLarge"];
          if (url != null) {
            precacheImage(CachedNetworkImageProvider(url), ctx);
          }
        }
      }
    }
  }

  _buildDownloadPage() {
    const List<Map<String, String>> data = [
      {
        "title": "episode1",
        "link":
            "https://rr5---sn-h5qzen7l.googlevideo.com/videoplayback?expire=1752270331&ei=mzFxaNyLKpDb1d8P7da10QU&ip=220.92.128.127&id=o-AHoIY5pBY7nqTcN95tVN8d-h1v9JoMm2EH3pQIj2cFYJ&itag=18&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&bui=AY1jyLNgOxZzB6xSJMZ0oxhMh5RQ4fzLO3N1VUcnk0XPPW7N3XZ9dPfJyKb89FxSlDQZVy-f_k2SsEY0&vprv=1&svpuc=1&mime=video%2Fmp4&ns=aywnzihE0oY8g6gzQ--J4KkQ&rqh=1&gir=yes&clen=5860714&ratebypass=yes&dur=234.103&lmt=1752244422993350&lmw=1&c=TVHTML5&sefc=1&txp=3309224&n=aptAcuhNzVDDVA&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cbui%2Cvprv%2Csvpuc%2Cmime%2Cns%2Crqh%2Cgir%2Cclen%2Cratebypass%2Cdur%2Clmt&sig=AJfQdSswRgIhAOrfrtAA-9UeoEYzoXtQ8kGlrr-1xPrOiLowACdVceJ7AiEA_H_oE2eW6OT-_uTExI9PuJOOGuLhDMiSvmE53iVdlDo%3D&title=Grok%204%20pushes%20humanity%20closer%20to%20AGI%E2%80%A6%20but%20there%E2%80%99s%20a%20problem&rm=sn-3u-20ny7k,sn-3u-bh2sd7d,sn-3pmzs76&rrc=79,79,104&fexp=24350590,24350737,24350827,24350961,24351316,24351318,24351528,24351907,24351914,24352220,24352297,24352299,24352322,24352334,24352336,24352394,24352396,24352398,24352400,24352452,24352454,24352457,24352460,24352466,24352467,24352517,24352519,24352535,24352537&req_id=ee2a731d64d1a3ee&cmsv=e&rms=nxu,au&redirect_counter=3&cms_redirect=yes&ipbypass=yes&met=1752264508,&mh=Gg&mip=105.69.126.116&mm=30&mn=sn-h5qzen7l&ms=nxu&mt=1752263292&mv=u&mvi=5&pl=22&lsparams=ipbypass,met,mh,mip,mm,mn,ms,mv,mvi,pl,rms&lsig=APaTxxMwRQIgEyh5qmi5fW1CONMm2tVtVCi1ILjnFkWZSokN4n4jBB0CIQDNq9tgXC6uon1KUPNtSa8FzFjyy4Deqzk59oIjbWCYcQ%3D%3D",
        "cover": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
        "animeTitle": "lmao",
        "audio": "Dub",
      },
      {
        "title": "episode2",
        "link": "https://vault-99.kwikie.ru/stream/99/01/8419664687a93915be35e4a53557134198592980e92b6e18b9de89095b7ebb7e/uwu.m3u8",
        "cover": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
        "animeTitle": "lmao",
        "audio": "Dub",
      },
      {
        "title": "episode3",
        "link": "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_2000kbps_720p_60.0fps_h264.mp4",
        "cover": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
        "animeTitle": "lmao",
        "audio": "Dub",
      },
      {
        "title": "episode4",
        "link": "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_2000kbps_720p_60.0fps_h264.mp4",
        "cover": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
        "animeTitle": "lmao",
        "audio": "Sub",
      },
      {
        "title": "episode5",
        "link": "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_2000kbps_720p_60.0fps_h264.mp4",
        "cover": "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
        "animeTitle": "lmao",
        "audio": "Sub",
      },
    ];

    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("Downloads", style: TextStyle(color: MyColors.unselectedColor, fontSize: 25, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 28),
          Expanded(
            child: Center(
              child: Text("Coming out soon!!", style: TextStyle(color: MyColors.appbarTextColor, fontSize: 25, fontWeight: FontWeight.w600)),
            ),
          ),
          // Expanded(
          //   child: ListView.separated(
          //     separatorBuilder: (context, index) => const SizedBox(height: 12),
          //     itemCount: 0,
          //     itemBuilder: (context, index) {
          //       return AnimeEpisode(
          //         progress: 75,
          //         downloaded: false,
          //         onClicked: (details) {
          //           print("lmao");
          //         },
          //         title: data[index]["title"]!,
          //         audio: data[index]["audio"]!,
          //         animeTitle: data[index]["animeTitle"]!,
          //         link: data[index]["link"]!,
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  _buildExplorerPage() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
      child: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(
              child: Text("Explorer", style: TextStyle(color: MyColors.unselectedColor, fontSize: 25, fontWeight: FontWeight.w600)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) => SearchPage(
                          onLibraryChanged: () {
                            _fetchAnimeLibrary(false);
                            _fetchPopularAnime();
                          },
                        ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                    opaque: false, // This allows the previous page to show through if you want
                  ),
                );
              },
              child: Hero(
                flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                  return Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: double.maxFinite,
                      decoration: BoxDecoration(color: MyColors.coolPurple, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final double fontSize = lerpDouble(25, 20, animation.value)!;
                                return Text("Search", style: TextStyle(color: MyColors.coolPurple2, fontSize: fontSize, fontWeight: FontWeight.w600));
                              },
                            ),
                            const Icon(Icons.search, color: MyColors.coolPurple2, weight: 700, size: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                tag: 'searchField',
                child: Container(
                  width: double.maxFinite,
                  decoration: BoxDecoration(color: MyColors.coolPurple, borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Search", style: TextStyle(color: MyColors.coolPurple2, fontSize: 25, fontWeight: FontWeight.w600)),
                        Icon(Icons.search, color: MyColors.coolPurple2, weight: 700, size: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 29)),
          SliverToBoxAdapter(child: _buildTrending()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(child: _buildPopular()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          SliverToBoxAdapter(child: _buildUpcoming()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  _buildTrending() {
    int count = popularAnimeData["trending"] == null ? 0 : popularAnimeData["trending"]!["media"].length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Trending", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                var mediaListEntry = popularAnimeData["trending"]!["media"][index]["mediaListEntry"];
                return SearchAnimeCard(
                  listName: getistNameFromMediaListEntry(mediaListEntry),
                  index: index,
                  data: {"media": popularAnimeData["trending"]!["media"][index]},
                  onLibraryChanged: _fetchPopularAnime,
                  tabName: "trending",
                );
              },
              itemCount: count,
            ),
          ),
        ),
      ],
    );
  }

  _buildPopular() {
    int count = popularAnimeData["season"] == null ? 0 : popularAnimeData["season"]!["media"].length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Popular This Season", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                var mediaListEntry = popularAnimeData["season"]!["media"][index]["mediaListEntry"];

                return SearchAnimeCard(
                  listName: getistNameFromMediaListEntry(mediaListEntry),
                  index: index,
                  data: {"media": popularAnimeData["season"]!["media"][index]},
                  onLibraryChanged: _fetchPopularAnime,
                  tabName: "season",
                );
              },
              itemCount: count,
            ),
          ),
        ),
      ],
    );
  }

  _buildUpcoming() {
    int count = popularAnimeData["nextSeason"] == null ? 0 : popularAnimeData["nextSeason"]!["media"].length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upcoming Next Season", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 268,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                var mediaListEntry = popularAnimeData["nextSeason"]!["media"][index]["mediaListEntry"];

                return SearchAnimeCard(
                  listName: getistNameFromMediaListEntry(mediaListEntry),
                  index: index,
                  data: {"media": popularAnimeData["nextSeason"]!["media"][index]},
                  onLibraryChanged: _fetchPopularAnime,
                  tabName: "nextSeason",
                );
              },
              itemCount: count,
            ),
          ),
        ),
      ],
    );
  }

  String getistNameFromMediaListEntry(mediaListEntry) {
    String listName = "";
    if (mediaListEntry != null) {
      // Check for customLists
      final customLists = mediaListEntry["customLists"];
      if (customLists != null && customLists is Map) {
        // Get all custom list names where value is true
        final trueLists = customLists.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();

        if (trueLists.isNotEmpty) {
          // If multiple, join with new line, else just the name
          listName = trueLists.join(',\n');
        } else {
          // Fallback to status if no custom list is true
          listName = mediaListEntry["status"] ?? "";
        }
      } else {
        // Fallback to status if no customLists
        listName = mediaListEntry["status"] ?? "";
      }
    }

    switch (listName) {
      case "CURRENT":
        listName = "Watching";
        break;
      case "COMPLETED":
        listName = "Completed";
        break;
      case "PLANNING":
        listName = "Planning";
        break;
      case "DROPPED":
        listName = "Dropped";
        break;
      case "PAUSED":
        listName = "Paused";
        break;
    }
    return listName;
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

class AnimeEpisode extends StatefulWidget {
  const AnimeEpisode({
    super.key,
    required this.onClicked,
    required this.title,
    required this.downloaded,
    required this.progress, // out of 100
    required this.audio,
    required this.animeTitle,
    required this.link,
  });

  final void Function(TapUpDetails)? onClicked;
  final String title;
  final bool downloaded;
  final int progress;
  final String audio;
  final String animeTitle;
  final String link;

  @override
  State<AnimeEpisode> createState() => _AnimeEpisodeState();
}

class _AnimeEpisodeState extends State<AnimeEpisode> {
  late Dio _dio;
  CancelToken? _cancelToken;
  int _currentProgress = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    _dio = Dio();
    _currentProgress = widget.progress;
    super.initState();
  }

  Future<String> getPrivateSavePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath = "${dir.path}/metia/$fileName";
    print(savePath);
    return savePath;
  }

  Future<void> _startDownload() async {
    final savePath = await getPrivateSavePath("${widget.title}.mp4");
    _cancelToken = CancelToken();

    try {
      setState(() {
        _isDownloading = true;
      });

      print("started!");

      await _dio.download(
        widget.link, // Replace with actual video link
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(received);
            final percent = (received / total * 100).toInt();
            setState(() {
              _currentProgress = percent;
            });
          }
        },
      );
      print("Download completed");
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        print("Download canceled");
      } else {
        print("Download error: $e");
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _pauseDownload() {
    _cancelToken?.cancel();
  }

  void _retryDownload() {
    //_dio.close();
    _startDownload();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: widget.downloaded ? widget.onClicked : (details) {},
      child: Container(
        width: double.infinity,
        height: 108,
        decoration: BoxDecoration(color: MyColors.coolPurple2, borderRadius: BorderRadius.circular(8)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  color: MyColors.coolPurple2, // background bar
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: widget.downloaded ? 100 : (_currentProgress / 100), // from 0.0 to 1.0
                      child: Container(color: widget.downloaded ? MyColors.coolPurple : Colors.green),
                    ),
                  ),
                ),
              ),
            ),

            Container(height: 104, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: MyColors.coolPurple2)),
            Opacity(
              opacity: widget.downloaded ? 1 : 0.2,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 100,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              errorWidget: (context, url, error) {
                                return Container();
                              },
                              imageUrl: "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx156415-zwP9deA786S1.jpg",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: SizedBox(
                            height: 100,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.animeTitle,
                                    style: const TextStyle(color: MyColors.unselectedColor, fontSize: 14, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    widget.audio,
                                    style: const TextStyle(color: MyColors.unselectedColor, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            widget.downloaded
                ? const SizedBox()
                : SizedBox(
                  height: 100,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$_currentProgress%",
                            style: const TextStyle(color: MyColors.appbarTextColor, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          IconButton(onPressed: _pauseDownload, icon: const Icon(Icons.pause, color: MyColors.appbarTextColor)),
                          IconButton(onPressed: _retryDownload, icon: const Icon(Icons.replay, color: MyColors.appbarTextColor)),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/pages/extensions_page.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/pages/user_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';
import 'package:app_links/app_links.dart';
import 'package:metia/widgets/anime_card3.dart';
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
  List<Map<String, dynamic>> popularAnimeData = [];
  bool isSearching = false;
  bool _searchEnded = true;
  String searchTabHeaderText = "Popular right now:";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Safe default
    mainController = TabController(length: 2, vsync: this);
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
    });
  }

  Future<void> _fetchSearchAnime(String keyword) async {
    setState(() {
      _searchEnded = false;
      searchTabHeaderText = "Search Resaults:";
    });
    AnilistApi.fetchSearchAnime(keyword).then((data) {
      setState(() {
        searchAnimeData = data;
        isSearching = true;
        _searchEnded = true;
      });
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
                                                            itemWidth: 460 / 4,
                                                          ),
                                                          mainAxisExtent: state.state == "New Episode" ? 260 : 245,
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
                                                          itemWidth: 115,
                                                        ),
                                                        mainAxisExtent: state.state == "New Episode" ? 260 : 245,
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
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0, left: 4.0, top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    searchTabHeaderText,
                                    style: const TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.w600, fontSize: 18),
                                  ),
                                ),
                                Expanded(
                                  child:
                                      _searchEnded == true
                                          ? isSearching
                                              ? searchAnimeData.isEmpty
                                                  ? const Center(
                                                    child: Text("No Anime Was Found!", style: TextStyle(color: MyColors.appbarTextColor, fontSize: 20)),
                                                  )
                                                  : _buildGrid()
                                              : popularAnimeData.isEmpty
                                              ? const Center(
                                                child: Text("No Anime Was Found!", style: TextStyle(color: MyColors.appbarTextColor, fontSize: 20)),
                                              )
                                              : _buildGrid()
                                          : const Center(child: CircularProgressIndicator()),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: MyColors.coolPurple2.withOpacity(0.40),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            onChanged: (keyword) async {
                                              if (_searchEnded == false) return;
                                              setState(() {
                                                _searchEnded = false;
                                              });
            
                                              Future.delayed(const Duration(milliseconds: 500), () {
                                                if (keyword.isNotEmpty) {
                                                  _searchEnded = false;
                                                  _fetchSearchAnime(keyword);
                                                } else {
                                                  _fetchPopularAnime();
                                                  _searchEnded = true;
                                                  isSearching = false;
                                                }
                                              });
                                            },
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText: "Search anime...",
                                              hintStyle: TextStyle(color: Colors.grey[500]),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                                            ),
                                            style: const TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: IconButton(
                                            icon: const Icon(Icons.search, color: MyColors.appbarTextColor, size: 28),
                                            onPressed: () {
                                              if (_searchController.text.isNotEmpty) {
                                                _searchEnded = false;
                                                _fetchSearchAnime(_searchController.text);
                                              } else {
                                                _fetchPopularAnime();
                                                _searchEnded = true;
                                                isSearching = false;
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  _buildGrid() {
    return GridView.builder(
      key: const PageStorageKey('searchResults'),
      itemCount: isSearching ? searchAnimeData.length : popularAnimeData.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Tools.getResponsiveCrossAxisVal(MediaQuery.of(context).size.width, itemWidth: 460 / 4),
        mainAxisExtent: 245,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        String listName = "";
        bool isCustom = false;
        var mediaListEntry = isSearching ? searchAnimeData[index]["mediaListEntry"] : popularAnimeData[index]["mediaListEntry"];

        if (mediaListEntry != null) {
          // Check for customLists
          final customLists = mediaListEntry["customLists"];
          if (customLists != null && customLists is Map) {
            // Get all custom list names where value is true
            final trueLists = customLists.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();

            if (trueLists.isNotEmpty) {
              isCustom = true;
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

        return SearchAnimeCard(
          tabName: "Search",
          listName: listName,
          index: index,
          data: isSearching ? {"media": searchAnimeData[index]} : {"media": popularAnimeData[index]},
          onLibraryChanged: () {
            print("a new anime is added or removed");
            isSearching ? _fetchSearchAnime(_searchController.text) : _fetchPopularAnime();
            _fetchAnimeLibrary(false);
          },
        );
      },
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

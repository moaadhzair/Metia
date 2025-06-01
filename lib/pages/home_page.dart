import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/api/anilist_search.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/data/setting.dart';
import 'package:metia/pages/extensions_page.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/pages/user_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final AppLinks _appLinks = AppLinks();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  bool _isPopupMenuOpen = false;
  double _blurOpacity = 0.0;

  List<String> tabs = [];
  int oldIndexTabController = 0;

  List<int> itemCounts = [];

  List<AnimeState>? _animeLibrary;
  bool _loading = true;
  String? _error;

  Color _previousTabColor = MyColors.appbarTextColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Safe default
    _initDeepLinking();
    _fetchAnimeLibrary(false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    if (_animeLibrary != null) {
      int oldLength = _tabController.length;
      int oldIndex = _tabController.index;

      _tabController.dispose();

      int newLength = _animeLibrary!.length;
      _tabController = TabController(length: newLength, vsync: this);

      int newIndex = oldIndex;

      if (newLength > oldLength) {
        // Tab added
        newIndex = (newLength - oldLength) + oldIndex;
      } else if (newLength < oldLength) {
        // Tab removed
        newIndex = (newLength - oldLength) - oldIndex;
      }

      // Clamp to valid range
      newIndex = newIndex.clamp(0, newLength - 1);

      if (oldLength == 1) newIndex = 0;

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
      final http.Response response = await http.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

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

  Color _getTabBorderColor(int index) {
    if (_animeLibrary == null) return MyColors.appbarTextColor;
    final state = _animeLibrary![index].state;
    if (state == "NEW EPISODE") return Colors.orange;
    if (state == "WATCHING") return Colors.green;
    return MyColors.appbarTextColor;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: MyColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: MyColors.appbarColor,
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
                                Text(
                                  "Refresh",
                                  style: TextStyle(
                                    color: MyColors.unselectedColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                Text(
                                  "Extensions",
                                  style: TextStyle(
                                    color: MyColors.unselectedColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ExtensionsPage()),
                                );
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
                                  Uri.parse(
                                    "https://anilist.co/api/v2/oauth/authorize?client_id=25588&redirect_uri=metia://&response_type=code",
                                  ),
                                );
                              }
                            },
                            height: 35,
                            child: const Row(
                              children: [
                                Icon(Icons.login, size: 30, color: MyColors.unselectedColor),
                                SizedBox(width: 10),
                                Text(
                                  "Login",
                                  style: TextStyle(
                                    color: MyColors.unselectedColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                Text(
                  "Metia",
                  style: TextStyle(color: MyColors.appbarTextColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(tabs.isEmpty ? 0 : 40),
              child: Column(
                children: [
                  tabs.isNotEmpty
                      ? TweenAnimationBuilder<Color?>(
                        tween: ColorTween(begin: _previousTabColor, end: _getTabBorderColor(_tabController.index)),
                        duration: kTabScrollDuration,
                        builder: (context, color, child) {
                          return TabBar(
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
                                            tabName.startsWith("NEW EPISODE")
                                                ? Colors.orange
                                                : tabName.startsWith("WATCHING")
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
                      )
                      : const SizedBox(),
                  PreferredSize(
                    preferredSize: const Size.fromHeight(0),
                    child: Container(color: tabs.isEmpty ? MyColors.unselectedColor : Colors.transparent, height: .5),
                  ),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              //horizontal: MediaQuery.orientationOf(context) == Orientation.landscape ? 40 : 0,
            ),
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error == "Exception: Please sign in to fetch your anime list."
                    ? Center(
                      child: GestureDetector(
                        onTap: () async {
                          await _launchUrl(
                            Uri.parse(
                              "https://anilist.co/api/v2/oauth/authorize?client_id=25588&redirect_uri=metia://&response_type=code",
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
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
                        style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Text(
                        _error.toString(),
                        style: const TextStyle(
                          color: MyColors.appbarTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                    )
                    : TabBarView(
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
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                              MediaQuery.of(context).size.width,
                                              itemWidth: 460 / 4,
                                            ),
                                            mainAxisExtent: state.state == "NEW EPISODE" ? 260 : 245,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            childAspectRatio: 0.7,
                                          ),
                                          delegate: SliverChildBuilderDelegate((context, index) {
                                            return AnimeCard(
                                              index: index,
                                              tabName: state.state,
                                              data: state.data[index],
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
                                        controller: _scrollController,
                                        cacheExtent: 500,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: Tools.getResponsiveCrossAxisVal(
                                            MediaQuery.of(context).size.width,
                                            itemWidth: 460 / 4,
                                          ),
                                          mainAxisExtent: state.state == "NEW EPISODE" ? 260 : 245,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 0.7,
                                        ),
                                        itemCount: state.data.length,
                                        itemBuilder: (context, index) {
                                          return AnimeCard(index: index, tabName: state.state, data: state.data[index]);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                          }).toList(),
                    ),
          ),
        ),
        IgnorePointer(
          ignoring: !_isPopupMenuOpen,
          child: AnimatedOpacity(
            curve: Curves.easeOutBack,
            opacity: _blurOpacity,
            duration: _isPopupMenuOpen ? const Duration(milliseconds: 333) : const Duration(milliseconds: 533),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

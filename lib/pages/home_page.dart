import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metia/api/anilist_search.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/data/Library.dart';
import 'package:metia/pages/settings_page.dart';
import 'package:metia/pages/user_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppLinks _appLinks = AppLinks();

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
    _initDeepLinking();
    _fetchAnimeLibrary();
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
      
      print("a request to the graphql has been made!!!!");

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
      //print("Initial Link: ${initialLink.toString()}");
    }

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        String code = uri.toString().substring(
          uri.toString().indexOf('code=') + 5,
        );
        fetchAniListAccessToken(code)
            .then((accessToken) {
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('auth_key', accessToken);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              });
            })
            .catchError((error) {
              print("Error fetching access token: $error");
            });
      }
    });
  }

  void _fetchAnimeLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final data = await AnilistApi.fetchAnimeListofID(userId);
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
                Icons.login,
                size: 30,
                color: MyColors.unselectedColor,
              ),
              onPressed: () {
                SharedPreferences.getInstance().then((prefs) {
                  final authCode = prefs.getString('auth_key');
                  if (authCode != null && authCode.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserPage()),
                    );
                  } else {
                    final url = Uri.parse(
                      "https://anilist.co/api/v2/oauth/authorize?client_id=25588&redirect_uri=metia://&response_type=code",
                    );
                    _launchURL(url);
                  }
                });
              },
            ),
            const SizedBox(width: 10),
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
                _fetchAnimeLibrary();
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
            tabs: tabs.map((String tabName) {
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error == "Exception: Please sign in to fetch your anime list."
                  ? const Center(
                      child: Text(
                        "Sign In",
                        style: TextStyle(color: MyColors.appbarTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        ),
                      ),
                    )
                  : TabBarView(
                      children: _animeLibrary!.map((animeState state) {
                        return GridView.builder(
                          cacheExtent: 500,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Tools.getResponsiveCrossAxisVal(
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

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}

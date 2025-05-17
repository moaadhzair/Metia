import 'dart:math';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:metia/api/extension.dart';
import 'package:metia/constants/Colors.dart';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:metia/managers/extension_manager.dart';
import 'package:metia/pages/player_page.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimePage extends StatefulWidget {
  final Map<String, dynamic> animeData;
  const AnimePage({super.key, required this.animeData});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  final ScrollController _scrollController = ScrollController();
  late ExtensionManager _localExtensionManager;
  Extension? currentExtension;

  dynamic clossestAnime;

  bool _isCollapsed = false;
  int itemCount = 0;
  int firstTabCount = 99;
  int eachItemForTab = 100;
  int tabCount = 0;
  List<String> labels = [];
  List<int> tabItemCounts = [];
  bool _isLoading = true;
  String? _selectedExtension;
  List<dynamic> EpisodeList = [];
  final bool _isSearchLoading = false;
  final List<Map<String, dynamic>> _searchResults = [];

  String currentAnime = "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _findAndSaveMatchingAnime() async {
    if (currentExtension == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = "anime_${widget.animeData["media"]["id"]}_extension_id";

    // Check if we already have a saved match
    final String? existingMatch = prefs.getString(key);
    if (existingMatch != null) {
      try {
        clossestAnime = jsonDecode(existingMatch);
        setState(() {});
        return;
      } catch (e) {
        print("Error parsing existing match: $e");
      }
    }

    final title =
        widget.animeData["media"]["title"]["english"] ??
        widget.animeData["media"]["title"]["romaji"] ??
        widget.animeData["media"]["title"]["native"] ??
        "";

    if (title.isEmpty) return;

    try {
      final searchResults = await currentExtension!.search(title);
      if (searchResults.isEmpty) return;

      // Find the best match
      Map<dynamic, dynamic>? bestMatch;
      double bestScore = 0;

      // Clean and normalize titles for comparison
      String normalizeTitle(String title) {
        return title
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }

      final normalizedSearchTitle = normalizeTitle(title);
      final searchWords = normalizedSearchTitle.split(' ');

      for (var anime in searchResults) {
        final animeTitle = anime["title"]?.toString() ?? "";
        final normalizedAnimeTitle = normalizeTitle(animeTitle);

        if (normalizedAnimeTitle.isEmpty) continue;

        double score = 0;

        // Exact match
        if (normalizedAnimeTitle == normalizedSearchTitle) {
          score = 1.0;
        }
        // Contains match
        else if (normalizedAnimeTitle.contains(normalizedSearchTitle) ||
            normalizedSearchTitle.contains(normalizedAnimeTitle)) {
          score = 0.8;
        }
        // Word match
        else {
          final animeWords = normalizedAnimeTitle.split(' ');
          int matchingWords = 0;

          for (var word in searchWords) {
            if (animeWords.contains(word)) {
              matchingWords++;
            }
          }

          if (matchingWords > 0) {
            score = matchingWords / max(searchWords.length, animeWords.length);
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = anime;
        }
      }

      if (bestMatch != null && bestScore >= 0.5) {
        clossestAnime = bestMatch;
      } else {
        clossestAnime = searchResults[0];
      }
      await prefs.setString(key, jsonEncode(bestMatch));

      //here is where we get the episode list
      EpisodeList = await currentExtension?.getEpisodeList(clossestAnime["session"]) ?? [];
      itemCount = EpisodeList.length;

      int remaining = itemCount - firstTabCount;
      int otherTabs = (remaining / eachItemForTab).ceil();
      tabCount = 1 + (remaining > 0 ? otherTabs : 0);

      tabItemCounts = [];
      if (itemCount <= firstTabCount) {
        tabItemCounts.add(itemCount);
      } else {
        tabItemCounts.add(firstTabCount);
        for (int i = 0; i < otherTabs; i++) {
          int start = firstTabCount + i * eachItemForTab + 1;
          int end = start + eachItemForTab - 1;
          if (end > itemCount) end = itemCount;
          tabItemCounts.add(end - start + 1);
        }
      }

      labels = [];
      if (itemCount <= firstTabCount) {
        labels.add("1 - $itemCount");
      } else {
        labels.add("1 - $firstTabCount");
        for (int i = 0; i < otherTabs; i++) {
          int start = firstTabCount + i * eachItemForTab + 1;
          int end = start + eachItemForTab - 1;
          if (end > itemCount) end = itemCount;
          labels.add("$start - $end");
        }
      }
      print("done?");

      _scrollController.addListener(_scrollListener);

      setState(() {});
    } catch (e) {
      print("Error finding matching anime: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _localExtensionManager = ExtensionManager();
    _localExtensionManager.init().then((value) async {
      await _initializeData();
      currentExtension = _localExtensionManager.getCurrentExtension();
      if (currentExtension != null) {
        await _findAndSaveMatchingAnime();
      }

      EpisodeList = await currentExtension?.getEpisodeList(clossestAnime["session"]) ?? [];
      itemCount = EpisodeList.length;

      int remaining = itemCount - firstTabCount;
      int otherTabs = (remaining / eachItemForTab).ceil();
      tabCount = 1 + (remaining > 0 ? otherTabs : 0);

      tabItemCounts = [];
      if (itemCount <= firstTabCount) {
        tabItemCounts.add(itemCount);
      } else {
        tabItemCounts.add(firstTabCount);
        for (int i = 0; i < otherTabs; i++) {
          int start = firstTabCount + i * eachItemForTab + 1;
          int end = start + eachItemForTab - 1;
          if (end > itemCount) end = itemCount;
          tabItemCounts.add(end - start + 1);
        }
      }

      labels = [];
      if (itemCount <= firstTabCount) {
        labels.add("1 - $itemCount");
      } else {
        labels.add("1 - $firstTabCount");
        for (int i = 0; i < otherTabs; i++) {
          int start = firstTabCount + i * eachItemForTab + 1;
          int end = start + eachItemForTab - 1;
          if (end > itemCount) end = itemCount;
          labels.add("$start - $end");
        }
      }

      _scrollController.addListener(_scrollListener);
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    await _localExtensionManager.init();
    final currentExtension = _localExtensionManager.getCurrentExtension();
    setState(() {
      _isLoading = false;
      _selectedExtension = currentExtension?.id.toString();
    });
  }

  void _scrollListener() {
    final collapseOffset = (MediaQuery.of(context).size.height) * 0.9 - kToolbarHeight - 10;
    if (_scrollController.hasClients) {
      final shouldBeCollapsed = _scrollController.offset > collapseOffset;
      if (_isCollapsed != shouldBeCollapsed) {
        setState(() {
          _isCollapsed = shouldBeCollapsed;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.animeData["media"]["title"]["english"] ??
        widget.animeData["media"]["title"]["romaji"] ??
        widget.animeData["media"]["title"]["native"] ??
        "Unknown Title";

    return Scaffold(
      floatingActionButton:
          _isCollapsed
              ? FloatingActionButton(
                onPressed: () {
                  // Example: Scroll to top when pressed
                  final double sliverAppBarHeight = MediaQuery.of(context).size.height * 0.8;
                  const double extensionPickerHeight = 56; // Approximate DropdownMenu height
                  const double buttonHeight = 56; // Approximate button height
                  const double verticalPadding = 12 + 12 + 12; // top + between + below

                  final double scrollTarget =
                      sliverAppBarHeight + extensionPickerHeight + buttonHeight + verticalPadding;

                  _scrollController.animateTo(
                    scrollTarget - 90,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                backgroundColor: MyColors.coolPurple,
                child: const Icon(Icons.arrow_upward, size: 30, color: MyColors.coolPurple2),
              )
              : null,
      backgroundColor: MyColors.backgroundColor,
      body: DefaultTabController(
        length: tabCount,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder:
              (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  backgroundColor: MyColors.appbarColor,
                  foregroundColor: MyColors.appbarTextColor,
                  stretch: true,
                  pinned: true,
                  title: AnimatedOpacity(
                    opacity: _isCollapsed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  expandedHeight: (MediaQuery.of(context).size.height) * 0.8,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    background: AnimeCover(animeData: widget.animeData),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                    child: Column(
                      children: [
                        // DropdownMenu (extension picker)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : DropdownMenu(
                                    width: 600,
                                    enableSearch: false,
                                    menuStyle: MenuStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        MyColors.backgroundColor,
                                      ),
                                    ),
                                    initialSelection: _selectedExtension,
                                    onSelected: (value) async {
                                      if (value != null) {
                                        setState(() {
                                          _selectedExtension = value;
                                        });
                                        _localExtensionManager.setCurrentExtension(
                                          int.parse(value),
                                        );
                                        currentExtension =
                                            _localExtensionManager.getCurrentExtension();
                                        await _findAndSaveMatchingAnime();
                                      }
                                    },
                                    label: const Text("Extensions"),
                                    inputDecorationTheme: InputDecorationTheme(
                                      labelStyle: const TextStyle(
                                        color: MyColors.coolPurple,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      suffixIconColor: MyColors.coolPurple,
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: MyColors.coolPurple,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: MyColors.coolPurple,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: MyColors.coolPurple,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: MyColors.coolPurple,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    textStyle: const TextStyle(color: MyColors.unselectedColor),
                                    dropdownMenuEntries:
                                        _localExtensionManager
                                            .getExtensions()
                                            .map(
                                              (extension) => DropdownMenuEntry(
                                                value: extension.id.toString(),
                                                label: extension.title,
                                                trailingIcon:
                                                    _localExtensionManager.isMainExtension(
                                                          extension,
                                                        )
                                                        ? const Icon(
                                                          Icons.check,
                                                          color: MyColors.coolPurple,
                                                          size: 20,
                                                        )
                                                        : null,
                                                leadingIcon: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: CachedNetworkImage(
                                                      imageUrl: extension.iconUrl,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                style: ButtonStyle(
                                                  foregroundColor: WidgetStateProperty.all(
                                                    MyColors.unselectedColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      errorWidget: (context, url, error) {
                                        return Container();
                                      },
                                      imageUrl: currentExtension?.iconUrl ?? "",
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Found:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  clossestAnime == null ? " " : clossestAnime["title"],
                                  style: const TextStyle(
                                    color: MyColors.appbarTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  final title =
                                      widget.animeData["media"]["title"]["english"] ??
                                      widget.animeData["media"]["title"]["romaji"] ??
                                      widget.animeData["media"]["title"]["native"] ??
                                      "";

                                  _searchController.text = title;
                                  setState(() {
                                    _searchQuery = title;
                                  });

                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: MyColors.backgroundColor,
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _searchController,
                                                    style: const TextStyle(color: Colors.white),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _searchQuery = value;
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      hintText: 'Search...',
                                                      hintStyle: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                      filled: true,
                                                      fillColor: MyColors.appbarColor,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _searchQuery = _searchController.text;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.search,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: FutureBuilder<List<dynamic>>(
                                                future:
                                                    _searchQuery.isEmpty
                                                        ? null
                                                        : currentExtension?.search(_searchQuery),
                                                builder: (context, snapshot) {
                                                  if (_searchQuery.isEmpty) {
                                                    return const Center(
                                                      child: Text(
                                                        'Enter a search term',
                                                        style: TextStyle(color: Colors.white),
                                                      ),
                                                    );
                                                  }

                                                  if (snapshot.connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                      child: CircularProgressIndicator(
                                                        color: MyColors.coolPurple,
                                                      ),
                                                    );
                                                  }

                                                  if (snapshot.hasError) {
                                                    return Center(
                                                      child: Text(
                                                        'Error: ${snapshot.error}',
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                    );
                                                  }

                                                  final searchResults =
                                                      snapshot.data
                                                          ?.map(
                                                            (item) => item as Map<String, dynamic>,
                                                          )
                                                          .toList() ??
                                                      [];

                                                  return GridView.builder(
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount:
                                                              Tools.getResponsiveCrossAxisVal(
                                                                        MediaQuery.of(
                                                                          context,
                                                                        ).size.width,
                                                                        itemWidth: 460 / 4,
                                                                      ) >
                                                                      5
                                                                  ? 5
                                                                  : Tools.getResponsiveCrossAxisVal(
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width,
                                                                    itemWidth: 460 / 4,
                                                                  ),
                                                          mainAxisExtent: 240,
                                                          crossAxisSpacing: 10,
                                                          mainAxisSpacing: 10,
                                                          childAspectRatio: 0.7,
                                                        ),
                                                    itemCount: searchResults.length,
                                                    itemBuilder: (context, index) {
                                                      final anime = searchResults[index];
                                                      return AnimeCard2(
                                                        onTap: (title) async {
                                                          final prefs =
                                                              await SharedPreferences.getInstance();
                                                          final key =
                                                              "anime_${widget.animeData["media"]["id"]}_extension_id";

                                                          setState(() {
                                                            clossestAnime = anime;
                                                          });

                                                          await prefs.setString(
                                                            key,
                                                            jsonEncode(anime),
                                                          );
                                                          print(
                                                            "Updated matching anime: ${anime["title"]} for key: $key",
                                                          );

                                                          EpisodeList =
                                                              await currentExtension
                                                                  ?.getEpisodeList(
                                                                    clossestAnime["session"],
                                                                  ) ??
                                                              [];
                                                          itemCount = EpisodeList.length;

                                                          int remaining = itemCount - firstTabCount;
                                                          int otherTabs =
                                                              (remaining / eachItemForTab).ceil();
                                                          tabCount =
                                                              1 + (remaining > 0 ? otherTabs : 0);

                                                          tabItemCounts = [];
                                                          if (itemCount <= firstTabCount) {
                                                            tabItemCounts.add(itemCount);
                                                          } else {
                                                            tabItemCounts.add(firstTabCount);
                                                            for (int i = 0; i < otherTabs; i++) {
                                                              int start =
                                                                  firstTabCount +
                                                                  i * eachItemForTab +
                                                                  1;
                                                              int end = start + eachItemForTab - 1;
                                                              if (end > itemCount) end = itemCount;
                                                              tabItemCounts.add(end - start + 1);
                                                            }
                                                          }

                                                          labels = [];
                                                          if (itemCount <= firstTabCount) {
                                                            labels.add("1 - $itemCount");
                                                          } else {
                                                            labels.add("1 - $firstTabCount");
                                                            for (int i = 0; i < otherTabs; i++) {
                                                              int start =
                                                                  firstTabCount +
                                                                  i * eachItemForTab +
                                                                  1;
                                                              int end = start + eachItemForTab - 1;
                                                              if (end > itemCount) end = itemCount;
                                                              labels.add("$start - $end");
                                                            }
                                                          }

                                                          _scrollController.addListener(
                                                            _scrollListener,
                                                          );
                                                          setState(() {});

                                                          Navigator.pop(
                                                            context,
                                                          ); // Close the modal bottom sheet
                                                        },
                                                        index: index,
                                                        title: anime["title"] ?? "Unknown Title",
                                                        imageUrl: anime["poster"] ?? "",
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  "Wrong Anime?",
                                  style: TextStyle(
                                    color: MyColors.coolPurple,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Start Watching Button
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                /*padding: const EdgeInsets.only(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),*/
                                foregroundColor: MyColors.coolGreen,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(color: MyColors.coolGreen),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              label: Text(
                                widget.animeData["media"]["episodes"] != null
                                    ? widget.animeData["media"]["episodes"] ==
                                            widget.animeData["progress"]
                                        ? "FINISHED"
                                        : "CONTINUE EPISODE ${widget.animeData["progress"] + 1}"
                                    : "NULL",
                                style: const TextStyle(
                                  color: MyColors.coolGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              icon:
                                  widget.animeData["media"]["episodes"] != null &&
                                          widget.animeData["media"]["episodes"] !=
                                              widget.animeData["progress"]
                                      ? const Icon(Icons.play_arrow_outlined, size: 20)
                                      : const SizedBox(),
                              onPressed: () async {
                                showModalBottomSheet(
                                  backgroundColor: MyColors.backgroundColor,

                                  context: context,
                                  builder: (context) {
                                    return Container(
                                      child: FutureBuilder(
                                        future: currentExtension?.getStreamData(
                                          EpisodeList[widget.animeData["progress"]]["id"],
                                        ),
                                        builder: (context, snapshot) {
                                          return snapshot.hasData
                                              ? Container(
                                                padding: const EdgeInsets.all(12),
                                                child: ListView.separated(
                                                  separatorBuilder: (context, index) {
                                                    return const SizedBox(height: 12);
                                                  },
                                                  itemCount: snapshot.data!.length,
                                                  itemBuilder: (context, index) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) => PlayerPage(
                                                                  episodeList: EpisodeList,
                                                                  currentExtension:
                                                                      currentExtension,
                                                                  episodeCount: EpisodeList.length,
                                                                  extensionEpisodeData:
                                                                      EpisodeList[widget
                                                                          .animeData["progress"]],
                                                                  episodeNumber:
                                                                      widget.animeData["progress"] +
                                                                      1,
                                                                  extensionStreamData:
                                                                      snapshot.data?[index],
                                                                  anilistData: widget.animeData,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: MyColors.coolPurple2,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        width: double.infinity,
                                                        height: 60,
                                                        padding: const EdgeInsets.all(12),
                                                        child: Center(
                                                          child: Text(
                                                            "${snapshot.data?[index]["provider"]} - ${snapshot.data?[index]["sub"] ? "Sub" : "Dub"}",
                                                            style: const TextStyle(
                                                              color: MyColors.appbarTextColor,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 16.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              : const SizedBox(
                                                height: double.infinity,
                                                width: double.infinity,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    color: MyColors.coolPurple,
                                                  ),
                                                ),
                                              );
                                        },
                                      ),
                                    );
                                  },
                                );

                                /*currentExtension?.getStreamData(
                                        EpisodeList[index]["id"],
                                      ).then((value) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerPage(
                                              StreamData: value,
                                            ),
                                          ),
                                        );
                                      });*/
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
          body: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Column(
              children: [
                // TabBar
                Builder(
                  builder: (context) {
                    final TabController tabController = DefaultTabController.of(context);
                    return StatefulBuilder(
                      builder: (context, setState) {
                        tabController.addListener(() {
                          setState(() {});
                        });

                        return TabBar(
                          tabAlignment: TabAlignment.start,
                          labelPadding: EdgeInsets.zero,
                          isScrollable: true,
                          indicatorColor: Colors.transparent,
                          dividerColor: Colors.transparent,
                          tabs: List.generate(labels.length, (i) {
                            final bool selected = tabController.index == i;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: selected ? Colors.white : Colors.transparent,
                                border: Border.all(color: MyColors.coolPurple),
                              ),
                              child: Center(
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: selected ? MyColors.coolPurple : const Color(0xFF9A989B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  },
                ),
                // TabBarView
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TabBarView(
                      children: List.generate(tabCount, (tabIndex) {
                        int count = tabItemCounts[tabIndex];
                        int startIndex =
                            (tabIndex == 0) ? 0 : firstTabCount + (tabIndex - 1) * eachItemForTab;
                        return CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((context, index) {
                                int episodeIndex = startIndex + index;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: AnimeEpisode(
                                    current: widget.animeData["progress"] == episodeIndex,
                                    animeData: widget.animeData,
                                    seen: widget.animeData["progress"] > episodeIndex,
                                    index: episodeIndex,
                                    onClicked: (details) async {
                                      showModalBottomSheet(
                                        backgroundColor: MyColors.backgroundColor,

                                        context: context,
                                        builder: (context) {
                                          return Container(
                                            child: FutureBuilder(
                                              future: currentExtension?.getStreamData(
                                                EpisodeList[episodeIndex]["id"],
                                              ),
                                              builder: (context, snapshot) {
                                                return snapshot.hasData
                                                    ? Container(
                                                      padding: const EdgeInsets.all(12),
                                                      child: ListView.separated(
                                                        separatorBuilder: (context, index) {
                                                          return const SizedBox(height: 12);
                                                        },
                                                        itemCount: snapshot.data!.length,
                                                        itemBuilder: (context, index) {
                                                          return GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) => PlayerPage(
                                                                        episodeList: EpisodeList,
                                                                        currentExtension:
                                                                            currentExtension,
                                                                        episodeCount:
                                                                            EpisodeList.length,
                                                                        extensionEpisodeData:
                                                                            EpisodeList[episodeIndex],
                                                                        episodeNumber:
                                                                            episodeIndex + 1,
                                                                        extensionStreamData:
                                                                            snapshot.data?[index],
                                                                        anilistData:
                                                                            widget.animeData,
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: MyColors.coolPurple2,
                                                                borderRadius: BorderRadius.circular(
                                                                  12,
                                                                ),
                                                              ),
                                                              width: double.infinity,
                                                              height: 60,
                                                              padding: const EdgeInsets.all(12),
                                                              child: Center(
                                                                child: Text(
                                                                  "${snapshot.data?[index]["provider"]} - ${snapshot.data?[index]["sub"] ? "Sub" : "Dub"}",
                                                                  style: const TextStyle(
                                                                    color: MyColors.appbarTextColor,
                                                                    fontWeight: FontWeight.w600,
                                                                    fontSize: 16.5,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                    : const SizedBox(
                                                      height: double.infinity,
                                                      width: double.infinity,
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          color: MyColors.coolPurple,
                                                        ),
                                                      ),
                                                    );
                                              },
                                            ),
                                          );
                                        },
                                      );

                                      /*currentExtension?.getStreamData(
                                        EpisodeList[index]["id"],
                                      ).then((value) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerPage(
                                              StreamData: value,
                                            ),
                                          ),
                                        );
                                      });*/
                                    },
                                    episodeData: {
                                      "episode": EpisodeList[episodeIndex],
                                    }, // make it a map of neccesary data that the each extension paases in
                                  ),
                                );
                              }, childCount: count),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimeEpisode extends StatelessWidget {
  const AnimeEpisode({
    super.key,
    required this.onClicked,
    required this.episodeData,
    required this.seen,
    required this.index,
    required this.animeData,
    required this.current,
  });

  final void Function(TapUpDetails)? onClicked;
  final dynamic episodeData;
  final bool seen;
  final int index;
  final dynamic animeData;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onClicked,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: current ? const Color(0xFF3c3243) : MyColors.coolPurple2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Opacity(
              opacity: seen ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.all(4),
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
                            imageUrl: episodeData["episode"]["cover"],
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
                                  animeData["media"]["title"]["english"] ??
                                      animeData["media"]["title"]["romaji"] ??
                                      animeData["media"]["title"]["native"] ??
                                      "Unknown Title",
                                  style: const TextStyle(
                                    color: MyColors.unselectedColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  episodeData["episode"]["name"],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  episodeData["episode"]["dub"] && episodeData["episode"]["sub"]
                                      ? "Sub | Dub"
                                      : episodeData["episode"]["sub"]
                                      ? "Sub"
                                      : episodeData["episode"]["dub"]
                                      ? "Dub"
                                      : "not specified",
                                  style: const TextStyle(
                                    color: MyColors.unselectedColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            if (seen)
              const Positioned(
                left: 4,
                child: SizedBox(
                  height: 100,
                  width: 177.78, // This is 100 * (16/9) to match the AspectRatio
                  child: Center(child: Icon(Icons.check, size: 60, color: Colors.white)),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: current ? const Color(0xFF3c3243) : MyColors.coolPurple2,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 18,
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

class AnimeCover extends StatelessWidget {
  const AnimeCover({super.key, required this.animeData});
  final dynamic animeData;
  String processHtml(String htmlContent) {
    // Replace <br> with newlines
    htmlContent = htmlContent.replaceAll(RegExp(r'<br\s*/?>'), '\n');

    // Parse the HTML
    html_dom.Document document = html_parser.parse(htmlContent);

    // Extract and return plain text
    String plainText = document.body?.text.trim() ?? '';

    // Replace multiple newlines with a single newline
    plainText = plainText.replaceAll(RegExp(r'(\n\s*){2,}'), '\n\n');
    return plainText;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = animeData["media"]["coverImage"]["extraLarge"];
    final title =
        animeData["media"]["title"]["english"] ??
        animeData["media"]["title"]["romaji"] ??
        animeData["media"]["title"]["native"] ??
        "Unknown Title";
    final description = processHtml(animeData["media"]["description"]);
    final List<dynamic> genres = animeData["media"]["genres"];

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, alignment: Alignment.center),
        Transform.translate(
          offset: const Offset(0, 4),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, MyColors.backgroundColor],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16.0, right: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  genres.join(' • '),
                  style: const TextStyle(
                    color: Color(0xFFA9A7A7),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animeData["media"]["averageScore"].toString() == "null"
                          ? "0.0"
                          : Tools.insertAt(animeData["media"]["averageScore"].toString(), ".", 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  "Synopsis",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.1,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA9A7A7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

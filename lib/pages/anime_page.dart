import 'dart:math';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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

class _AnimePageState extends State<AnimePage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late ExtensionManager _localExtensionManager;
  Extension? currentExtension;

  dynamic clossestAnime;

  String extensionAnimeTitle = "";

  late TabController _tabController;

  bool _isCollapsed = false;
  int itemCount = 0;
  int firstTabCount = 99;
  int eachItemForTab = 100;
  int tabCount = 0;
  List<String> labels = [];
  List<int> tabItemCounts = [];
  bool _isLoading = true;
  bool _isLoadingExtesnion = true;
  String? _selectedExtension;
  List<dynamic> EpisodeList = [];
  String foundTitle = "";

  String currentAnime = "";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  Future<void> _findAndSaveMatchingAnime() async {
    foundTitle = "";

    if (currentExtension == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key =
        "anime_${widget.animeData["media"]["id"]}_extension_${currentExtension?.id}";

    // Check if we already have a saved match
    final String? existingMatch = prefs.getString(key);
    if (existingMatch != null) {
      try {
        clossestAnime = jsonDecode(existingMatch);
        setState(() {
          foundTitle = clossestAnime == null ? " " : clossestAnime["title"];
        });
        return;
      } catch (e) {
        print("Error parsing existing match: $e");
      }
    }

    final title =
        currentExtension?.anilistPreferedTitle.toLowerCase() == "english"
            ? widget.animeData["media"]["title"]["english"] ??
                widget.animeData["media"]["title"]["romaji"] ??
                widget.animeData["media"]["title"]["native"]
            : currentExtension?.anilistPreferedTitle.toLowerCase() == "romaji"
            ? widget.animeData["media"]["title"]["romaji"] ??
                widget.animeData["media"]["title"]["english"] ??
                widget.animeData["media"]["title"]["native"]
            : "";

    if (title.isEmpty) return;

    try {
      final searchResults = await currentExtension!.search(title);
      if (searchResults.isEmpty) return;
      extensionAnimeTitle = searchResults[0]["title"] ?? "";

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
      EpisodeList =
          await currentExtension?.getEpisodeList(clossestAnime["session"]) ??
          [];
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

      setState(() {
        foundTitle = clossestAnime == null ? " " : clossestAnime["title"];
      });
    } catch (e) {
      print("Error finding matching anime: $e");
    }
  }

  @override
  void initState() {
    _tabController = TabController(length: 0, vsync: this);

    super.initState();
    _isLoading = true;
    EpisodeList = [];
    prepareTabBarAndListView();

    _localExtensionManager = ExtensionManager();
    _scrollController.addListener(_scrollListener);
    _localExtensionManager.init().then((value) async {
      await _initializeData();
      currentExtension = _localExtensionManager.getCurrentExtension();
      await initEpisodeList();
    });
  }

  Future<void> initEpisodeList() async {
    if (currentExtension != null) {
      await _findAndSaveMatchingAnime();
    }

    if (clossestAnime != null) {
      EpisodeList = await currentExtension!.getEpisodeList(
        clossestAnime["session"],
      );
    } else {
      EpisodeList = [];
    }

    prepareTabBarAndListView();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void prepareTabBarAndListView() {
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
    if (mounted) {
      if (_tabController.length != tabCount) {
        _tabController.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }
    }
  }

  Future<void> _initializeData() async {
    await _localExtensionManager.init();
    final currentExtension = _localExtensionManager.getCurrentExtension();
    setState(() {
      _isLoadingExtesnion = false;
      _selectedExtension = currentExtension?.id.toString();
    });
  }

  void _scrollListener() {
    final double expandedHeight = MediaQuery.of(context).size.height * 0.7;
    if (_scrollController.hasClients) {
      final shouldBeCollapsed =
          _scrollController.offset > (expandedHeight - kToolbarHeight);
      if (_isCollapsed != shouldBeCollapsed) {
        // Schedule setState after the frame to avoid conflicts with gestures
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isCollapsed = shouldBeCollapsed;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
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
              ? _buildFloatingActionButton(scrollController: _scrollController)
              : null,
      backgroundColor: MyColors.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              _buildAnimeCoverSliverAppBar(
                isCollapsed: _isCollapsed,
                title: title,
                widget: widget,
              ),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  surfaceTintColor: MyColors.backgroundColor,
                  toolbarHeight: 179,
                  expandedHeight: 179,
                  collapsedHeight: 179,
                  pinned: true,
                  leading: const SizedBox(),
                  backgroundColor: MyColors.backgroundColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            MediaQuery.of(context).orientation ==
                                    Orientation.landscape
                                ? 23
                                : 0,
                      ),
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          left: 12,
                          right: 12,
                          bottom: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          //spacing: 5,
                          children: [
                            //extension picker, found title, title picker
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                // DropdownMenu image (extension picker)
                                _isLoadingExtesnion
                                    ? const CircularProgressIndicator()
                                    : Row(
                                      children: [
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                          ),
                                          child: PopupMenuButton<String>(
                                            splashRadius: 0,
                                            tooltip: "Select Extension",
                                            color: MyColors.coolPurple2,
                                            onSelected: (value) async {
                                              setState(() {
                                                _isLoading = true;
                                                EpisodeList = [];
                                                prepareTabBarAndListView();
                                                _selectedExtension = value;
                                              });
                                              _localExtensionManager
                                                  .setCurrentExtension(
                                                    int.parse(value),
                                                  );
                                              currentExtension =
                                                  _localExtensionManager
                                                      .getCurrentExtension();
                                              if (mounted) {
                                                await initEpisodeList();
                                              }
                                            },
                                            itemBuilder:
                                                (context) =>
                                                    _localExtensionManager
                                                        .getExtensions()
                                                        .map(
                                                          (
                                                            extension,
                                                          ) => PopupMenuItem<
                                                            String
                                                          >(
                                                            value:
                                                                extension.id
                                                                    .toString(),
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 24,
                                                                  height: 24,
                                                                  child: ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                    child: CachedNetworkImage(
                                                                      imageUrl:
                                                                          extension
                                                                              .iconUrl,
                                                                      fit:
                                                                          BoxFit
                                                                              .contain,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  extension
                                                                      .title,
                                                                  style: const TextStyle(
                                                                    color:
                                                                        MyColors
                                                                            .unselectedColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                if (_localExtensionManager
                                                                    .isMainExtension(
                                                                      extension,
                                                                    ))
                                                                  const Padding(
                                                                    padding:
                                                                        EdgeInsets.only(
                                                                          left:
                                                                              8.0,
                                                                        ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .check,
                                                                      color:
                                                                          MyColors
                                                                              .coolPurple,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: 32,
                                                  height: 32,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child:
                                                        currentExtension
                                                                    ?.iconUrl ==
                                                                null
                                                            ? const Icon(
                                                              Icons.extension,
                                                              color:
                                                                  MyColors
                                                                      .coolPurple,
                                                            )
                                                            : CachedNetworkImage(
                                                              imageUrl:
                                                                  currentExtension
                                                                      ?.iconUrl ??
                                                                  "",
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: MyColors.coolPurple,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                // static "Found:" text
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Found:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                //found title
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      foundTitle,
                                      maxLines: 2,
                                      style: const TextStyle(
                                        color: MyColors.appbarTextColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                //wrong anime bottom sheet picker
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      final title =
                                          currentExtension?.anilistPreferedTitle
                                                      .toLowerCase() ==
                                                  "english"
                                              ? widget.animeData["media"]["title"]["english"] ??
                                                  widget
                                                      .animeData["media"]["title"]["romaji"] ??
                                                  widget
                                                      .animeData["media"]["title"]["native"]
                                              : currentExtension
                                                      ?.anilistPreferedTitle
                                                      .toLowerCase() ==
                                                  "romaji"
                                              ? widget.animeData["media"]["title"]["romaji"] ??
                                                  widget
                                                      .animeData["media"]["title"]["english"] ??
                                                  widget
                                                      .animeData["media"]["title"]["native"]
                                              : "";

                                      _searchController.text = title;
                                      setState(() {
                                        _searchQuery = title;
                                      });

                                      showModalBottomSheet(
                                        enableDrag:
                                            false, // disables drag gestures that trigger rebuilds
                                        context: context,
                                        backgroundColor:
                                            MyColors.backgroundColor,
                                        builder: (context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _searchController,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _searchQuery =
                                                                value;
                                                          });
                                                        },
                                                        decoration: InputDecoration(
                                                          hintText: 'Search...',
                                                          hintStyle:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                          filled: true,
                                                          fillColor:
                                                              MyColors
                                                                  .appbarColor,
                                                          border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            borderSide:
                                                                BorderSide.none,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _searchQuery =
                                                              _searchController
                                                                  .text;
                                                        });
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();
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
                                                  child: FutureBuilder<
                                                    List<dynamic>
                                                  >(
                                                    future:
                                                        _searchQuery.isEmpty
                                                            ? null
                                                            : currentExtension
                                                                ?.search(
                                                                  _searchQuery,
                                                                ),
                                                    builder: (
                                                      context,
                                                      snapshot,
                                                    ) {
                                                      if (_searchQuery
                                                          .isEmpty) {
                                                        return const Center(
                                                          child: Text(
                                                            'Enter a search term',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        );
                                                      }

                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return const Center(
                                                          child: CircularProgressIndicator(
                                                            color:
                                                                MyColors
                                                                    .coolPurple,
                                                          ),
                                                        );
                                                      }

                                                      if (snapshot.hasError) {
                                                        return Center(
                                                          child: Text(
                                                            'Error: ${snapshot.error}',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        );
                                                      }

                                                      final searchResults =
                                                          snapshot.data
                                                              ?.map(
                                                                (item) =>
                                                                    item
                                                                        as Map<
                                                                          String,
                                                                          dynamic
                                                                        >,
                                                              )
                                                              .toList() ??
                                                          [];

                                                      return GridView.builder(
                                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount:
                                                              Tools.getResponsiveCrossAxisVal(
                                                                        MediaQuery.of(
                                                                          context,
                                                                        ).size.width,
                                                                        itemWidth:
                                                                            460 /
                                                                            4,
                                                                      ) >
                                                                      5
                                                                  ? 5
                                                                  : Tools.getResponsiveCrossAxisVal(
                                                                    MediaQuery.of(
                                                                      context,
                                                                    ).size.width,
                                                                    itemWidth:
                                                                        460 / 4,
                                                                  ),
                                                          mainAxisExtent: 240,
                                                          crossAxisSpacing: 10,
                                                          mainAxisSpacing: 10,
                                                          childAspectRatio: 0.7,
                                                        ),
                                                        itemCount:
                                                            searchResults
                                                                .length,
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          final anime =
                                                              searchResults[index];
                                                          return AnimeCard2(
                                                            onTap: (
                                                              title,
                                                            ) async {
                                                              final prefs =
                                                                  await SharedPreferences.getInstance();
                                                              final key =
                                                                  "anime_${widget.animeData["media"]["id"]}_extension_${currentExtension?.id}";
                                                              // Set loading before closing the sheet
                                                              setState(() {
                                                                _isLoading =
                                                                    true;
                                                              });

                                                              // Save the selected anime
                                                              clossestAnime =
                                                                  anime;
                                                              await prefs
                                                                  .setString(
                                                                    key,
                                                                    jsonEncode(
                                                                      anime,
                                                                    ),
                                                                  );
                                                              extensionAnimeTitle =
                                                                  anime["title"] ??
                                                                  "";

                                                              setState(() {
                                                                foundTitle =
                                                                    clossestAnime ==
                                                                            null
                                                                        ? " "
                                                                        : clossestAnime["title"];
                                                              });

                                                              // Close the bottom sheet
                                                              Navigator.pop(
                                                                context,
                                                              );

                                                              // Fetch episodes after closing the sheet
                                                              EpisodeList =
                                                                  await currentExtension
                                                                      ?.getEpisodeList(
                                                                        clossestAnime["session"],
                                                                      ) ??
                                                                  [];

                                                              prepareTabBarAndListView();

                                                              // Remove loading and update UI
                                                              if (mounted) {
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              }
                                                            },
                                                            index: index,
                                                            title:
                                                                anime["title"] ??
                                                                "Unknown Title",
                                                            imageUrl:
                                                                anime["poster"] ??
                                                                "",
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Start Watching Button
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: MyColors.coolGreen,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: MyColors.coolGreen,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                label: Text(
                                  widget.animeData["media"]["episodes"] != null
                                      ? widget.animeData["media"]["episodes"] ==
                                              widget.animeData["progress"]
                                          ? "FINISHED"
                                          : "CONTINUE EPISODE ${widget.animeData["progress"] ?? 0 + 1}"
                                      : "NULL",
                                  style: const TextStyle(
                                    color: MyColors.coolGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                icon:
                                    widget.animeData["media"]["episodes"] !=
                                                null &&
                                            widget.animeData["media"]["episodes"] !=
                                                widget.animeData["progress"]
                                        ? const Icon(
                                          Icons.play_arrow_outlined,
                                          size: 20,
                                        )
                                        : const SizedBox(),
                                onPressed: () async {
                                  await showSourcePicker(
                                    context,
                                    currentExtension,
                                    EpisodeList,
                                    widget.animeData["progress"] ?? 0,
                                    widget.animeData,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            //Tab bar builder
                            Builder(
                              builder: (context) {
                                final TabController tabController =
                                    _tabController;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    tabController.addListener(() {
                                      setState(() {});
                                    });

                                    if (_tabController.length != tabCount) {
                                      return const SizedBox(); // or a loading indicator
                                    }

                                    return TabBar(
                                      controller: _tabController,
                                      tabAlignment: TabAlignment.start,
                                      labelPadding: EdgeInsets.zero,
                                      isScrollable: true,
                                      indicatorColor: Colors.transparent,
                                      dividerColor: Colors.transparent,
                                      tabs: List.generate(labels.length, (i) {
                                        final bool selected =
                                            tabController.index == i;
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color:
                                                selected
                                                    ? Colors.white
                                                    : Colors.transparent,
                                            border: Border.all(
                                              color: MyColors.coolPurple,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              labels[i],
                                              style: TextStyle(
                                                color:
                                                    selected
                                                        ? MyColors.coolPurple
                                                        : const Color(
                                                          0xFF9A989B,
                                                        ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
        body:
            _isLoading
                ? const Column(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Loading The Anime...",
                      style: TextStyle(
                        color: MyColors.appbarTextColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CircularProgressIndicator(color: MyColors.coolPurple),
                    SizedBox(height: 20),
                  ],
                )
                : TabBarView(
                  controller: _tabController,
                  children: List.generate(tabCount, (tabIndex) {
                    bool isLandscape =
                        MediaQuery.orientationOf(context) ==
                        Orientation.landscape;
                    EdgeInsetsGeometry padding = EdgeInsets.only(
                      left: (isLandscape ? 20 : 0) + 12,
                      right: (isLandscape ? 20 : 0) + 12,
                      top: 12,
                    );
                    int count = tabItemCounts[tabIndex];
                    int startIndex =
                        (tabIndex == 0)
                            ? 0
                            : firstTabCount + (tabIndex - 1) * eachItemForTab;
                    return count == 0
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60.0),
                            child: Text(
                              "No Anime Was Found!.",
                              style: TextStyle(
                                color: MyColors.appbarTextColor,
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        : Padding(
                          padding: padding,
                          child: _buildAnimeEpisodeList(
                            isCollapsed: _isCollapsed,
                            count: count,
                            startIndex: startIndex,
                            extensionAnimeTitle: extensionAnimeTitle,
                            widget: widget,
                            currentExtension: currentExtension,
                            episodeList: EpisodeList,
                          ),
                        );
                  }),
                ),
      ),
    );
  }
}

class _buildAnimeEpisodeList extends StatefulWidget {
  const _buildAnimeEpisodeList({
    super.key,
    required this.count,
    required this.startIndex,
    required this.extensionAnimeTitle,
    required this.widget,
    required this.currentExtension,
    required this.episodeList,
    required this.isCollapsed,
  });

  final int count;
  final int startIndex;
  final String extensionAnimeTitle;
  final AnimePage widget;
  final Extension? currentExtension;
  final List episodeList;
  final bool isCollapsed;

  @override
  State<_buildAnimeEpisodeList> createState() => _buildAnimeEpisodeListState();
}

class _buildAnimeEpisodeListState extends State<_buildAnimeEpisodeList> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey<String>('anime-episode-list-${widget.startIndex}'),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        //SliverToBoxAdapter(child: SizedBox(height: widget.isCollapsed ? kToolbarHeight : 0)),
        const SliverToBoxAdapter(child: SizedBox(height: kToolbarHeight)),

        // Scroll up by kToolbarHeight when the list is built
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            int episodeIndex = widget.startIndex + index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: AnimeEpisode(
                title: widget.extensionAnimeTitle,
                current:
                    widget.widget.animeData["progress"] ?? 0 == episodeIndex,
                animeData: widget.widget.animeData,
                seen: widget.widget.animeData["progress"] ?? 0 > episodeIndex,
                index: episodeIndex,
                onClicked: (details) async {
                  await showSourcePicker(
                    context,
                    widget.currentExtension,
                    widget.episodeList,
                    episodeIndex,
                    widget.widget.animeData,
                  );
                },
                episodeData: {"episode": widget.episodeList[episodeIndex]},
              ),
            );
          }, childCount: widget.count),
        ),
      ],
    );
  }
}

Future<void> showSourcePicker(
  BuildContext context,
  Extension? currentExtension,
  List<dynamic> episodeList,
  int episodeIndex,
  animeData,
) async {
  showModalBottomSheet(
    backgroundColor: MyColors.backgroundColor,

    context: context,
    builder: (context) {
      return Container(
        child: FutureBuilder(
          future: currentExtension?.getStreamData(
            episodeList[episodeIndex]["id"],
          ),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                        child: Text(
                          "Available Sources:",
                          style: TextStyle(
                            color: MyColors.appbarTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            snapshot.data!.isEmpty
                                ? const SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Center(
                                    child: Text(
                                      "No Sources Are Available!",
                                      style: TextStyle(
                                        color: MyColors.appbarTextColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.5,
                                      ),
                                    ),
                                  ),
                                )
                                : ListView.separated(
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
                                                  episodeList: episodeList,
                                                  currentExtension:
                                                      currentExtension,
                                                  episodeCount:
                                                      episodeList.length,
                                                  extensionEpisodeData:
                                                      episodeList[episodeIndex],
                                                  episodeNumber:
                                                      episodeIndex + 1,
                                                  extensionStreamData:
                                                      snapshot.data?[index],
                                                  anilistData: animeData,
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
                                            "${snapshot.data?[index]["provider"].toString().toUpperCase()} - ${snapshot.data?[index]["sub"] ? "Sub" : "Dub"}",
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
                      ),
                    ],
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
}

class _buildAnimeCoverSliverAppBar extends StatelessWidget {
  const _buildAnimeCoverSliverAppBar({
    super.key,
    required bool isCollapsed,
    required this.title,
    required this.widget,
  }) : _isCollapsed = isCollapsed;

  final bool _isCollapsed;
  final dynamic title;
  final AnimePage widget;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      surfaceTintColor: MyColors.backgroundColor,
      backgroundColor: MyColors.backgroundColor,
      foregroundColor: MyColors.appbarTextColor,
      pinned: true,
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      expandedHeight: (MediaQuery.of(context).size.height) * 0.7,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: AnimeCover(animeData: widget.animeData),
        //stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
      ),
    );
  }
}

class _buildFloatingActionButton extends StatelessWidget {
  const _buildFloatingActionButton({
    super.key,
    required ScrollController scrollController,
  }) : _scrollController = scrollController;

  final ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Example: Scroll to top when pressed
        final double sliverAppBarHeight =
            MediaQuery.of(context).size.height * 0.7;
        const double secondAppBarHeight = 0;

        final double scrollTarget = sliverAppBarHeight + secondAppBarHeight;

        _scrollController.jumpTo(
          sliverAppBarHeight - kToolbarHeight + 1,
        ); //482 for bluestakcs
      },
      backgroundColor: MyColors.coolPurple,
      child: const Icon(
        Icons.arrow_upward,
        size: 30,
        color: MyColors.coolPurple2,
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
    required this.title,
  });

  final void Function(TapUpDetails)? onClicked;
  final dynamic episodeData;
  final bool seen;
  final int index;
  final dynamic animeData;
  final bool current;
  final String title;

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
                                  title,
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
                                  episodeData["episode"]["dub"] &&
                                          episodeData["episode"]["sub"]
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
                  width:
                      177.78, // This is 100 * (16/9) to match the AspectRatio
                  child: Center(
                    child: Icon(Icons.check, size: 60, color: Colors.white),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      current ? const Color(0xFF3c3243) : MyColors.coolPurple2,
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

class AnimeCover extends StatefulWidget {
  const AnimeCover({super.key, required this.animeData});
  final dynamic animeData;

  @override
  State<AnimeCover> createState() => _AnimeCoverState();
}

class _AnimeCoverState extends State<AnimeCover> {
  double _opacity = 0.0;

  String processHtml(String htmlContent) {
    htmlContent = htmlContent.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    html_dom.Document document = html_parser.parse(htmlContent);
    String plainText = document.body?.text.trim() ?? '';
    plainText = plainText.replaceAll(RegExp(r'(\n\s*){2,}'), '\n\n');
    return plainText;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.animeData["media"]["coverImage"]["extraLarge"];
    final description = processHtml(widget.animeData["media"]["description"]);
    final List<dynamic> genres = widget.animeData["media"]["genres"];
    final title =
        widget.animeData["media"]["title"]["english"] ??
        widget.animeData["media"]["title"]["romaji"] ??
        widget.animeData["media"]["title"]["native"] ??
        "Unknown Title";

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: '${widget.animeData["media"]["id"]}',
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              // When the image loads, fade in
              imageBuilder: (context, imageProvider) {
                if (_opacity == 0.0) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _opacity = 1.0);
                  });
                }
                return Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                );
              },
            ),
          ),
        ),
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
        AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,

          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                bottom: 16.0,
                right: 16.0,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal:
                      MediaQuery.orientationOf(context) == Orientation.landscape
                          ? 20
                          : 0,
                ),
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
                          widget.animeData["media"]["averageScore"]
                                      .toString() ==
                                  "null"
                              ? "0.0"
                              : Tools.insertAt(
                                widget.animeData["media"]["averageScore"]
                                    .toString(),
                                ".",
                                1,
                              ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 8,
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
          ),
        ),
      ],
    );
  }
}

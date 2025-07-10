import 'package:flutter/material.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/tools.dart';
import 'package:metia/widgets/anime_card3.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onLibraryChanged;

  const SearchPage({super.key, this.onLibraryChanged});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> searchAnimeData = {"data": [], "status": false};
  bool _searchEnded = true;
  bool _isDefault = true;

  Future<void> _fetchSearchAnime(String keyword) async {
    setState(() {
      _searchEnded = false;
      _isDefault = false;
    });
    AnilistApi.fetchSearchAnime(keyword).then((data) {
      setState(() {
        searchAnimeData = data;
        _searchEnded = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: Column(spacing: 16, children: [_buildSearchArea(), _isDefault ? _buildEmptyBody() : _buildBody()]),
        ),
      ),
    );
  }

  _buildEmptyBody() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Search for something...", textAlign: TextAlign.center, style: TextStyle(color: MyColors.unselectedColor, fontSize: 25)),
            Text("example: The Apothecary Diaries.", style: TextStyle(color: MyColors.unselectedColor, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  _buildSearchArea() {
    return Row(
      spacing: 16,
      children: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: MyColors.unselectedColor, size: 27)),
        Expanded(
          child: Hero(
            tag: 'searchField',
            child: Material(
              color: MyColors.coolPurple, // <-- Change this to your desired color
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        onSubmitted: (value) {
                          if (value.trim().isEmpty) {
                            setState(() {
                              _isDefault = true;
                            });
                          } else {
                            _fetchSearchAnime(value.trim());
                          }
                        },
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(
                          color: Colors.black, // <-- Change text color if needed
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Search",
                          hintStyle: TextStyle(
                            color: Colors.black54, // <-- Change hint color if needed
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        cursorColor: Colors.black, // <-- Change cursor color if needed
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_searchController.text.trim().isEmpty) {
                          setState(() {
                            _isDefault = true;
                          });
                        } else {
                          _fetchSearchAnime(_searchController.text.trim());
                        }
                      },
                      child: const Icon(Icons.search, color: Colors.black, weight: 700, size: 30), // <-- Change icon color if needed
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

  _buildGrdiView() {
    return Expanded(
      child: GridView.builder(
        key: const PageStorageKey('searchResults'),
        itemCount: searchAnimeData["data"].length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Tools.getResponsiveCrossAxisVal(MediaQuery.of(context).size.width, itemWidth: 130),
          mainAxisExtent: 268,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          String listName = "";
          bool isCustom = false;
          var mediaListEntry = searchAnimeData["data"][index]["mediaListEntry"];

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
            data: {"media": searchAnimeData["data"][index]},
            onLibraryChanged: () {
              setState(() {
                print("a new anime is added or removed");
                _fetchSearchAnime(_searchController.text);
                widget.onLibraryChanged?.call();
              });
            },
          );
        },
      ),
    );
  }

  _buildBody() {
    if (_searchEnded == false) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    } else {
      if (searchAnimeData["success"] == false) {
        return const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't find an anime with that title!",
                textAlign: TextAlign.center,
                style: TextStyle(color: MyColors.unselectedColor, fontSize: 25),
              ),
            ],
          ),
        );
      } else {
        return _buildGrdiView();
      }
    }
  }
}

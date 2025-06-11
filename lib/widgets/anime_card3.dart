import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/pages/anime_page.dart';
import 'package:metia/tools.dart';

class SearchAnimeCard extends StatefulWidget {
  final String listName;
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback? onLibraryChanged;
  final String tabName;

  const SearchAnimeCard({super.key, required this.listName, required this.index, required this.data, required this.onLibraryChanged, required this.tabName});

  @override
  State<SearchAnimeCard> createState() => searchAnimeCardState();
}

class CustomPageRoute extends MaterialPageRoute {
  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 500);

  CustomPageRoute({builder}) : super(builder: builder);
}

// ignore: camel_case_types
class searchAnimeCardState extends State<SearchAnimeCard> with AutomaticKeepAliveClientMixin {
  final double _opacity = 0.0;
  late final title;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    title =
        widget.data["media"]["title"]["english"] ??
        widget.data["media"]["title"]["romaji"] ??
        widget.data["media"]["title"]["native"] ??
        "Unknown Title";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 115,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, CustomPageRoute(builder: (context) => AnimePage(animeData: widget.data, tabName: "Search",)));
              },
              behavior: HitTestBehavior.translucent, // Ensures taps are registered
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.hardEdge,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: widget.data["media"]["coverImage"]["extraLarge"],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                      AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) {
                                          final double t = animation.value;
                                          // double t;// fade out
                                          return Opacity(opacity: t.clamp(0.0, 1.0), child: child);
                                        },
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
                                    ],
                                  );
                                },
                                tag: widget.data["media"]["id"].toString() + widget.tabName,
                                child: CachedNetworkImage(
                                  imageUrl: widget.data["media"]["coverImage"]["large"],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              widget.listName.isEmpty
                                  ? Align(
                                    alignment: Alignment.bottomRight,
                                    child: GestureDetector(
                                      onTapUp: (details) {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return StatefulBuilder(
                                              builder: (context, setModalState) {
                                                return ClipRRect(
                                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                                                  child: Scaffold(
                                                    floatingActionButton: FloatingActionButton(
                                                      backgroundColor: MyColors.coolPurple,
                                                      child: const Icon(Icons.add, color: MyColors.backgroundColor),
                                                      onPressed: () async {
                                                        final result = await showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            TextEditingController listNameController = TextEditingController();
                                                            return AlertDialog(
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                              backgroundColor: MyColors.backgroundColor,
                                                              title: const Text(
                                                                "Create New List",
                                                                style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.w600),
                                                              ),
                                                              content: TextField(
                                                                controller: listNameController,
                                                                decoration: const InputDecoration(
                                                                  hintText: "Enter List Name",
                                                                  hintStyle: TextStyle(color: MyColors.unselectedColor),
                                                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MyColors.coolPurple)),
                                                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MyColors.coolPurple)),
                                                                ),
                                                                style: const TextStyle(color: MyColors.appbarTextColor),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: const Text("Cancel", style: TextStyle(color: MyColors.unselectedColor)),
                                                                ),
                                                                ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(backgroundColor: MyColors.coolPurple),
                                                                  onPressed: () async {
                                                                    final listName = listNameController.text.trim();
                                                                    if (listName.isEmpty) return;
                                                                    await AnilistApi.createCustomList(listName, context);
                                                                    Navigator.of(context).pop("refresh");
                                                                  },
                                                                  child: const Text("Add", style: TextStyle(color: MyColors.backgroundColor)),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
            
                                                        if (result == "refresh") {
                                                          setModalState(() {}); // This will rebuild the FutureBuilder!
                                                        }
                                                      },
                                                    ),
                                                    backgroundColor: MyColors.backgroundColor,
                                                    body: Padding(
                                                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        spacing: 16,
                                                        children: [
                                                          const Text(
                                                            "Add To List:",
                                                            style: TextStyle(color: MyColors.appbarTextColor, fontWeight: FontWeight.w600, fontSize: 16.5),
                                                          ),
                                                          Expanded(
                                                            child: FutureBuilder(
                                                              future: AnilistApi.getUserAnimeLists(),
                                                              builder: (context, snapshot) {
                                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                                  return const Center(child: CircularProgressIndicator());
                                                                }
                                                                if (snapshot.connectionState == ConnectionState.done) {
                                                                  List<Map<String, dynamic>>? userLists = snapshot.data;
                                                                  return ListView.separated(
                                                                    separatorBuilder: (context, index) {
                                                                      return const SizedBox(height: 12);
                                                                    },
                                                                    itemBuilder: (context, index) {
                                                                      return GestureDetector(
                                                                        onTapUp: (details) async {
                                                                          userLists[index]["isCustom"] == true
                                                                              ? await AnilistApi.addAnimeToCustomList(
                                                                                widget.data["media"]["id"],
                                                                                userLists[index]["name"],
                                                                              )
                                                                              : await AnilistApi.addAnimeToStatus(
                                                                                widget.data["media"]["id"],
                                                                                userLists[index]["name"],
                                                                              );
                                                                          if (widget.onLibraryChanged != null) {
                                                                            widget.onLibraryChanged!();
                                                                          }
                                                                          Navigator.of(context).pop();
                                                                          Tools.Toast(context, "added $title to ${userLists[index]["name"]}");
                                                                        },
                                                                        child: Container(
                                                                          decoration: BoxDecoration(
                                                                            color: MyColors.coolPurple2,
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          width: double.infinity,
                                                                          height: 60,
                                                                          padding: const EdgeInsets.all(12),
                                                                          alignment: Alignment.center,
                                                                          child: Text(
                                                                            userLists[index]["name"],
                                                                            style: const TextStyle(
                                                                              color: MyColors.appbarTextColor,
                                                                              fontWeight: FontWeight.w600,
                                                                              fontSize: 16.5,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                    itemCount: userLists!.length,
                                                                  );
                                                                }
                                                                return Container();
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        height: 30,
                                        width: 30,
                                        margin: const EdgeInsets.all(4),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(25),
                                          child: Container(
                                            decoration: const BoxDecoration(color: Color.fromARGB(178, 41, 41, 41)),
                                            child: const Icon(Icons.add, color: Colors.white, size: 25),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Container(
                                    color: Colors.black.withOpacity(0.7),
                                    child: Center(
                                      child: Text(
                                        widget.listName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.5),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${widget.data["media"]["episodes"] ?? "?"} Ep",
                                style: const TextStyle(color: MyColors.appbarTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              widget.data["media"]["nextAiringEpisode"].toString() != "null" && widget.listName.startsWith("NEW EPISODE")
                                  ? TextSpan(
                                    text: "\n${widget.data["media"]["nextAiringEpisode"]["episode"] - 1}",
                                    style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                                  )
                                  : const TextSpan(),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              widget.data["media"]["averageScore"].toString() == "null"
                                  ? "0.0"
                                  : Tools.insertAt(widget.data["media"]["averageScore"].toString(), ".", 1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                            ),
                            const Icon(Icons.star, color: Colors.orange, size: 18),
                          ],
                        ),
                      ],
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

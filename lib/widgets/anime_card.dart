import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/pages/anime_page.dart';
import 'package:metia/tools.dart';
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';

class CustomPageRoute extends MaterialPageRoute {
  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 500);

  CustomPageRoute({builder}) : super(builder: builder);
}

class AnimeCard extends StatefulWidget {
  final String tabName;
  final int index;
  final Map<String, dynamic> data;

  const AnimeCard({
    super.key,
    required this.tabName,
    required this.index,
    required this.data,
  });

  @override
  State<AnimeCard> createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> {
  final double _opacity = 0.0;
  late final String title;

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
    return Container(
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
                child: Hero(
                  flightShuttleBuilder: (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              widget.data["media"]["coverImage"]["extraLarge"],
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final double t = animation.value;
                            // double t;// fade out
                            return Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  MyColors.backgroundColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  tag: '${widget.data["media"]["id"]}',
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      scaffoldBackgroundColor: Colors.transparent, // try this
                    ),
                    child: CupertinoContextMenu.builder(
                      builder: (
                        BuildContext context,
                        Animation<double> animation,
                      ) {
                        return GestureDetector(
                          onTap: () {
                            print("tapped");
                            Navigator.push(
                              context,
                              CustomPageRoute(
                                builder:
                                    (context) =>
                                        AnimePage(animeData: widget.data),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Customize radius here
                            child: CachedNetworkImage(
                              imageUrl:
                                  widget
                                      .data["media"]["coverImage"]["extraLarge"],
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                      actions: [
                        CupertinoContextMenuAction(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AnimePage(animeData: widget.data),
                              ),
                            );
                          },
                          trailingIcon: CupertinoIcons.play,
                          child: const Text("Watch"),
                        ),
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.square_arrow_right,
                          child: const Text("Change to Another List"),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(25),
                                        topRight: Radius.circular(25),
                                      ),
                                      child: Scaffold(
                                        floatingActionButton: FloatingActionButton(
                                          backgroundColor: MyColors.coolPurple,
                                          child: const Icon(
                                            Icons.add,
                                            color: MyColors.backgroundColor,
                                          ),
                                          onPressed: () async {
                                            final result = await showDialog(
                                              context: context,
                                              builder: (context) {
                                                TextEditingController
                                                listNameController =
                                                    TextEditingController();
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      MyColors.backgroundColor,
                                                  title: const Text(
                                                    "Create New List",
                                                    style: TextStyle(
                                                      color:
                                                          MyColors
                                                              .appbarTextColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  content: TextField(
                                                    controller:
                                                        listNameController,
                                                    decoration: const InputDecoration(
                                                      hintText:
                                                          "Enter List Name",
                                                      hintStyle: TextStyle(
                                                        color:
                                                            MyColors
                                                                .unselectedColor,
                                                      ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  MyColors
                                                                      .coolPurple,
                                                            ),
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  MyColors
                                                                      .coolPurple,
                                                            ),
                                                          ),
                                                    ),
                                                    style: const TextStyle(
                                                      color:
                                                          MyColors
                                                              .appbarTextColor,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color:
                                                              MyColors
                                                                  .unselectedColor,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                MyColors
                                                                    .coolPurple,
                                                          ),
                                                      onPressed: () async {
                                                        final listName =
                                                            listNameController
                                                                .text
                                                                .trim();
                                                        if (listName.isEmpty)
                                                          return;
                                                        await AnilistApi.createCustomList(
                                                          listName,
                                                          context,
                                                        );
                                                        Navigator.of(
                                                          context,
                                                        ).pop("refresh");
                                                      },
                                                      child: const Text(
                                                        "Add",
                                                        style: TextStyle(
                                                          color:
                                                              MyColors
                                                                  .backgroundColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (result == "refresh") {
                                              setModalState(
                                                () {},
                                              ); // This will rebuild the FutureBuilder!
                                            }
                                          },
                                        ),
                                        backgroundColor:
                                            MyColors.backgroundColor,
                                        body: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                            left: 16,
                                            right: 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            spacing: 16,
                                            children: [
                                              const Text(
                                                "Add To List:",
                                                style: TextStyle(
                                                  color:
                                                      MyColors.appbarTextColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16.5,
                                                ),
                                              ),
                                              Expanded(
                                                child: FutureBuilder(
                                                  future:
                                                      AnilistApi.getUserAnimeLists(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    }
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.done) {
                                                      List<
                                                        Map<String, dynamic>
                                                      >?
                                                      userLists = snapshot.data;
                                                      return ListView.separated(
                                                        separatorBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          return const SizedBox(
                                                            height: 12,
                                                          );
                                                        },
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          return GestureDetector(
                                                            onTapUp: (
                                                              details,
                                                            ) async {
                                                              if (userLists[index]["isCustom"] ==
                                                                  true) {
                                                                if ([
                                                                  "COMPLETED",
                                                                  "WATCHING",
                                                                  "PAUSED",
                                                                  "DROPPED",
                                                                  "PLANNING",
                                                                ].contains(
                                                                  widget.tabName
                                                                      .toUpperCase(),
                                                                )) {
                                                                  //from status to custom
                                                                  await AnilistApi.changeFromStatusToCustomList(
                                                                    widget
                                                                        .data["media"]["id"],
                                                                    userLists[index]["name"],
                                                                  );
                                                                } else {
                                                                  //from custom to custom
                                                                  await AnilistApi.changeFromCustomListToCustomList(
                                                                    widget
                                                                        .data["media"]["id"],
                                                                    widget
                                                                        .tabName,
                                                                    userLists[index]["name"]
                                                                        .toString()
                                                                        .toLowerCase(),
                                                                    widget
                                                                        .data["id"],
                                                                  );
                                                                }
                                                              } else {
                                                                if ([
                                                                  "COMPLETED",
                                                                  "WATCHING",
                                                                  "PAUSED",
                                                                  "DROPPED",
                                                                  "PLANNING",
                                                                ].contains(
                                                                  widget.tabName
                                                                      .toUpperCase(),
                                                                )) {
                                                                  //from status to status
                                                                  await AnilistApi.changeFromStatusToStatus(
                                                                    widget
                                                                        .data["media"]["id"],
                                                                    userLists[index]["name"],
                                                                  );
                                                                } else {
                                                                  //from custom to status
                                                                  AnilistApi.changeFromCustomListToStatus(
                                                                    widget
                                                                        .data["media"]["id"],
                                                                    widget
                                                                        .tabName,
                                                                    userLists[index]["name"],
                                                                  );
                                                                }
                                                              }

                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              Tools.Toast(
                                                                context,
                                                                "added $title to ${userLists[index]["name"]}",
                                                              );
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    MyColors
                                                                        .coolPurple2,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              width:
                                                                  double
                                                                      .infinity,
                                                              height: 60,
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                userLists[index]["name"],
                                                                style: const TextStyle(
                                                                  color:
                                                                      MyColors
                                                                          .appbarTextColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      16.5,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        itemCount:
                                                            userLists!.length,
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
                        ),
                        CupertinoContextMenuAction(
                          trailingIcon: CupertinoIcons.doc_on_doc,
                          child: const Text("Copy Name"),
                          onPressed: () {
                            Pasteboard.writeText(title);
                            Navigator.of(context).pop();
                            Tools.Toast(
                              context,
                              "Copied \"$title\" to clipboard",
                            );
                          },
                        ),
                        CupertinoContextMenuAction(
                          isDestructiveAction: true,
                          trailingIcon: CupertinoIcons.delete,
                          child: const Text("Remove From List"),
                          onPressed: () async {
                            if ([
                              "COMPLETED",
                              "WATCHING",
                              "PAUSED",
                              "DROPPED",
                              "PLANNING",
                            ].contains(widget.tabName.toUpperCase())) {
                              await AnilistApi.removeAnimeFromStatus(
                                widget.data["media"]["id"],
                                widget.data["id"],
                              );
                            } else {
                              await AnilistApi.removeAnimeFromCustomList(
                                widget.data["media"]["id"],
                                widget.tabName.toLowerCase(),
                                "",
                                widget.data["id"]
                              );
                            }

                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.5,
                ),
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
                      text:
                          "${widget.data["progress"]}/${widget.data["media"]["episodes"] ?? "?"}",
                      style: const TextStyle(
                        color: MyColors.appbarTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    widget.data["media"]["nextAiringEpisode"].toString() !=
                                "null" &&
                            widget.tabName.startsWith("NEW EPISODE")
                        ? TextSpan(
                          text:
                              "\n${widget.data["media"]["nextAiringEpisode"]["episode"] - 1}",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                        : Tools.insertAt(
                          widget.data["media"]["averageScore"].toString(),
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
            ],
          ),
        ],
      ),
    );
  }
}

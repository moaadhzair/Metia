import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/pages/anime_page.dart';
import 'package:metia/tools.dart';
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Tools.Toast(
          context,
          "${widget.data["media"]["title"]["english"]} in (${widget.tabName})",
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimePage(animeData: widget.data),
          ),
        );
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
                  child: Hero(
                    flightShuttleBuilder: (
                      flightContext,
                      animation,
                      flightDirection,
                      fromHeroContext,
                      toHeroContext,
                    ) {
                      // Calculate opacity based on direction and animation value
                      final double gradientOpacity = flightDirection == HeroFlightDirection.push
                          ? animation.value // fade in
                          : 1.0 - animation.value; // fade out

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.data["media"]["coverImage"]["extraLarge"],
                            fit: BoxFit.fitWidth,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                          AnimatedOpacity(
                            opacity: gradientOpacity.clamp(0.0, 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
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
                    child: CachedNetworkImage(
                      imageUrl:
                          widget.data["media"]["coverImage"]["extraLarge"],
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      errorWidget:
                          (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Center(
                child: Text(
                  widget.data["media"]["title"]["english"] ??
                      widget.data["media"]["title"]["romaji"] ??
                      widget.data["media"]["title"]["native"] ??
                      "Unknown Title",
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
                            "${widget.data["progress"]}/${widget.data["media"]["episodes"] ?? "??"}",
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
                                "\n${widget.data["media"]["nextAiringEpisode"]["episode"]}",
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
      ),
    );
  }
}

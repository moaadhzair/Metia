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

class AnimeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Tools.Toast(
          context,
          "${data["media"]["title"]["english"]} in ($tabName)",
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimePage(animeData: data),
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
                    tag: '${data["media"]["id"]}',
                    child: CachedNetworkImage(
                      imageUrl: data["media"]["coverImage"]["extraLarge"],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Center(
                child: Text(
                  data["media"]["title"]["english"] ??
                      data["media"]["title"]["romaji"] ??
                      data["media"]["title"]["native"] ??
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
                        text: "${data["progress"]}/${data["media"]["episodes"]?? "??"}",
                        style: const TextStyle(
                          color: MyColors.appbarTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      data["media"]["nextAiringEpisode"].toString() != "null" && tabName.startsWith("NEW EPISODE")
                          ? TextSpan(
                              text: "\n${data["media"]["nextAiringEpisode"]["episode"]}",
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
                      data["media"]["averageScore"].toString() == "null"
                          ? "0.0"
                          : Tools.insertAt(
                              data["media"]["averageScore"].toString(),
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

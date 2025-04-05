import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:metia/constants/Colors.dart';
import 'package:metia/tools.dart';

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
        Tools.Toast(context, tabName);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          children: [
            Expanded(
              // Poster
              flex: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.hardEdge,
                child: CachedNetworkImage(
                  imageUrl: data["media"]["coverImage"]["extraLarge"],
                  fit: BoxFit.fitHeight,
                  placeholder:
                      (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Title
              flex: 2,
              child: Text(
                data["media"]["title"]["english"] ??
                    data["media"]["title"]["romaji"] ??
                    data["media"]["title"]["native"] ??
                    "Unknown Title",
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 0),
            Stack(
              children: [
                Align(
                  // Progress
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                ),
                Align(
                  // Rating
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.3),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: data["progress"].toString(),
                            style: TextStyle(
                              color: MyColors.appbarTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: "/" + data["media"]["episodes"].toString(),
                            style: TextStyle(
                              color: MyColors.unselectedColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

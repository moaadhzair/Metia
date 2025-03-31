import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        Tools.Toast(context, data.toString());
      },
      child: Column(
        children: [
          Expanded(
            flex: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                12,
              ), // Apply border radius with width
              clipBehavior:
                  Clip.hardEdge, // Ensures only the widget's width is clipped
              child: Image.network(
                data["coverImage"]["extraLarge"],
                fit:
                    BoxFit
                        .fitHeight, // Ensures the image fills the clipped area
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: Text(
              data["title"]["romaji"],
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 2),
          Stack(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data["averageScore"].toString() == "null"
                          ? "0.0"
                          : Tools.insertAt(
                            data["averageScore"].toString(),
                            ".",
                            1,
                          ),
                      //Tools.insertAt(data["averageScore"].toString(), ".", 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange,
                      ),
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 18,
                      applyTextScaling: true,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "0",
                        style: TextStyle(
                          color: MyColors.appbarTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " /" + data["episodes"].toString(),
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
            ],
          ),
        ],
      ),
    );
  }
}

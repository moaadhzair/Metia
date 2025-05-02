import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:metia/tools.dart';

class AnimePage extends StatefulWidget {
  final Map<String, dynamic> animeData;

  const AnimePage({super.key, required this.animeData});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  @override
  Widget build(BuildContext context) {
    final title =
        widget.animeData["media"]["title"]["english"] ??
        widget.animeData["media"]["title"]["romaji"] ??
        widget.animeData["media"]["title"]["native"] ??
        "Unknown Title";

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          slivers: [
            SliverAppBar(
              backgroundColor: MyColors.appbarColor,
              stretch: true,
              collapsedHeight: kToolbarHeight,
              stretchTriggerOffset: 50,
              pinned: true,

            foregroundColor: MyColors.appbarTextColor,
              // Only show title when collapsed
              title: LayoutBuilder(
                builder: (context, constraints) {
                  // When the app bar is fully collapsed, its height is kToolbarHeight
                  final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
                  final isCollapsed = settings != null && settings.currentExtent <= kToolbarHeight + 10;
                  return AnimatedOpacity(
                    opacity: isCollapsed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      style: const TextStyle(
                        //color: MyColors.appbarTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
              expandedHeight: (MediaQuery.of(context).size.width * 2) * 0.9,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: AnimeCover(animeData: widget.animeData),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                ...List.generate(
                  100,
                  (index) => Text("     Episode ${index}", style: TextStyle(color: Colors.white)),
                ),
              ]),
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
        CachedNetworkImage(
          
          imageUrl: imageUrl,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          placeholder:
              (context, url) => Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.black12,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
        ),
        Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, MyColors.backgroundColor],
                stops: [.4, .8]
              )
            ),
          ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              bottom: 24.0,
            ), // adjust as needed
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
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      animeData["media"]["averageScore"].toString() == "null"
                          ? "0.0"
                          : Tools.insertAt(
                            animeData["media"]["averageScore"].toString(),
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
                SizedBox(height: 2,),
                const Text(
                  "Synopsis",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4,),
                Text(
                  description,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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

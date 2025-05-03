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
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // You may need to adjust this value depending on your expandedHeight
    final collapseOffset =
        (MediaQuery.of(context).size.width * 2) * 0.9 - kToolbarHeight - 10;
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
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          //scrollDirection: Axis.vertical,
          //shrinkWrap: true,
          slivers: [
            SliverAppBar(
              backgroundColor: MyColors.appbarColor,
              foregroundColor: MyColors.appbarTextColor,
              stretch: true,
              //collapsedHeight: kToolbarHeight,
              //stretchTriggerOffset: 10,
              pinned: true,
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              expandedHeight: (MediaQuery.of(context).size.height) * 0.8,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: AnimeCover(animeData: widget.animeData),
              ),
            ),
            AnimeEpisodes(),
          ],
        ),
      ),
    );
  }
}

class AnimeEpisodes extends StatelessWidget {
  const AnimeEpisodes({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        Container(
          // extension picker, start watching button, tabs
          color: MyColors.backgroundColor,
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: DropdownMenu(
                  width: 600,
                  enableSearch: false,
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(
                      MyColors.backgroundColor,
                    ),
                  ),
                  initialSelection: "null",
                  label: const Text("Extensions"),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: TextStyle(
                      color: MyColors.coolPurple,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    suffixIconColor: MyColors.coolPurple,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyColors.coolPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyColors.coolPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyColors.coolPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: MyColors.coolPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  textStyle: TextStyle(
                    color: MyColors.unselectedColor,
                    
                  ),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: "null",
                      label: "No Extensions Installed",
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          MyColors.unselectedColor,
                        ),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: "animepahe",
                      label: "AnimePahe",
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          MyColors.unselectedColor,
                        ),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: "hianime",
                      label: "HiAnime",
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(
                          MyColors.unselectedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        Transform.translate(
          offset: Offset(0, 4),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, MyColors.backgroundColor],
                //stops: [.5, 1],
              ),
            ),
          ),
        ),

        Align(
          // the text data of the anime
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              bottom: 16.0,
              right: 16.0,
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
                const SizedBox(height: 4),
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

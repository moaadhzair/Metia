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
        child: DefaultTabController(
          length: 10,
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder:
                (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    backgroundColor: MyColors.appbarColor,
                    foregroundColor: MyColors.appbarTextColor,
                    stretch: true,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                      ),
                      child: Column(
                        children: [
                          // DropdownMenu (extension picker)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                labelStyle: const TextStyle(
                                  color: MyColors.coolPurple,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                suffixIconColor: MyColors.coolPurple,
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: MyColors.coolPurple,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: MyColors.coolPurple,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: MyColors.coolPurple,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: MyColors.coolPurple,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              textStyle: const TextStyle(
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
                              ],
                            ),
                          ),
                          // Start Watching Button
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  foregroundColor: MyColors.coolGreen,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: MyColors.coolGreen,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                label: const Text(
                                  "START WATCHING ",
                                  style: TextStyle(
                                    color: MyColors.coolGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.play_arrow_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            body: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Column(
                children: [
                  // TabBar
                  Builder(
                    builder: (context) {
                      final TabController tabController =
                          DefaultTabController.of(context);
                      return StatefulBuilder(
                        builder: (context, setState) {
                          tabController.addListener(() {
                            setState(() {});
                          });
                          List<String> labels = [
                            "1 - 99",
                            "100 - 199",
                            "200 - 299",
                            "300 - 399",
                            "400 - 499",
                            "500 - 599",
                            "600 - 699",
                            "700 - 799",
                            "800 - 899",
                            "900 - 999",
                          ];
                          return TabBar(
                            tabAlignment: TabAlignment.start,
                            labelPadding: EdgeInsets.zero,
                            isScrollable: true,
                            indicatorColor: Colors.transparent,
                            dividerColor: Colors.transparent,
                            tabs: List.generate(labels.length, (i) {
                              final bool selected = tabController.index == i;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
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
                                              : const Color(0xFF9A989B),
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
                  // TabBarView
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TabBarView(
                        //physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(10, (tabIndex) {
                          return ListView.separated(
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 7),
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: 100,
                            itemBuilder: (context, index) {
                              return AnimeEpisode(onClicked: (details){
                                Tools.Toast(context, "lmao");
                              }, episodeData: "");
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimeEpisode extends StatelessWidget {
  const AnimeEpisode({
    super.key, required this.onClicked, required this.episodeData,
  });

  final void Function(TapUpDetails)? onClicked;
  final dynamic episodeData;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onClicked,
      child: Container(
        padding: const EdgeInsets.all(4),
        width: double.infinity,
        decoration: BoxDecoration(
          color: MyColors.coolPurple2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 80,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    6,
                  ),
                  child: CachedNetworkImage(
                    imageUrl:
                        "https://imgsrv.crunchyroll.com/cdn-cgi/image/fit=contain,format=auto,quality=70,width=320,height=180/catalog/crunchyroll/51f4f0e6b0122b8497ddd1044a27c6c4.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: SizedBox(
                height:
                    80, // Match the image height for alignment
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween, // <-- This spaces items evenly
                    children: [
                      Text(
                        "Fire Force Season 3",
                        style: TextStyle(
                          color:
                              MyColors
                                  .unselectedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "S3 E1 - Indomitable Resolve",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Dub | Sub",
                        style: TextStyle(
                          color:
                              MyColors
                                  .unselectedColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              bottom: 16.0,
              right: 16.0,
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

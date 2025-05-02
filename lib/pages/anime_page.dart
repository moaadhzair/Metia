import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';

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
              stretch: true,
              collapsedHeight: kToolbarHeight,
              stretchTriggerOffset: 50,
              pinned: true,
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              expandedHeight: (MediaQuery.of(context).size.width * 2) * 0.75,
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
                  (index) => Text("dummy data number ${index}"),
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

  @override
  Widget build(BuildContext context) {

    final imageUrl = animeData["media"]["coverImage"]["extraLarge"];
    final title =
        animeData["media"]["title"]["english"] ??
        animeData["media"]["title"]["romaji"] ??
        animeData["media"]["title"]["native"] ??
        "Unknown Title";

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
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
    );
  }
}

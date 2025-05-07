import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metia/constants/Colors.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

class ExtensionsPage extends StatefulWidget {
  const ExtensionsPage({super.key});

  @override
  State<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends State<ExtensionsPage> {
  // Example data for available extensions
  List<Map<String, dynamic>> availableExtensions = [
    {
      "title": "AnimePahe",
      "iconUrl": "https://assets.apk.live/com.animepahe.show_animes--128-icon.png",
      "dub": true,
      "sub": true,
      "language": "English",
    },{
      "title": "HiAnime",
      "iconUrl": "https://cdn2.steamgriddb.com/icon_thumb/a0e7be097b3b5eb71d106dd32f2312ac.png",
      "dub": true,
      "sub": true,
      "language": "English",
    },{
      "title": "GojoWTF",
      "iconUrl": "https://gojo.wtf/android-chrome-512x512.png",
      "dub": true,
      "sub": true,
      "language": "English",
    },{
      "title": "AnimeKai",
      "iconUrl": "https://i.postimg.cc/jttw9rQ9/Screenshot-2025-05-07-191754.png?dl=1",
      "dub": true,
      "sub": true,
      "language": "English",
    },
    // Add more extensions here if needed
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: MyColors.backgroundColor,
        appBar: AppBar(
          foregroundColor: MyColors.appbarTextColor,
          backgroundColor: MyColors.appbarColor,
          title: const Row(
            children: [
              SizedBox(width: 20),
              Text(
                "Extensions",
                style: TextStyle(
                  color: MyColors.appbarTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: const Color.fromARGB(255, 69, 69, 70),
            dividerHeight: 1,
            indicatorColor: MyColors.appbarTextColor,
            labelColor: MyColors.appbarTextColor,
            unselectedLabelColor: MyColors.unselectedColor,
            tabs: const [
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Available Extensions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Installed Extensions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.separated(
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemCount: availableExtensions.length,
                itemBuilder: (context, index) {
                  final ext = availableExtensions[index];
                  return ExtensionTile(
                    title: ext["title"],
                    iconUrl: ext["iconUrl"],
                    dub: ext["dub"],
                    sub: ext["sub"],
                    language: ext["language"],
                    onDeleted: (context) {
                      setState(() {
                        availableExtensions.removeAt(index);
                      });
                    },
                  );
                },
              ),
            ),
            ListView.builder(
              //installed Extensions
              itemBuilder: (context, index) {
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ExtensionTile extends StatelessWidget {
  final String title;
  final String iconUrl;
  final bool dub;
  final bool sub;
  final String language;
  final void Function(BuildContext) onDeleted;

  const ExtensionTile({
    super.key,
    required this.title,
    required this.iconUrl,
    required this.dub,
    required this.sub,
    required this.language,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              foregroundColor: MyColors.appbarTextColor,
              autoClose: true,
              backgroundColor: Colors.transparent,
              label: "Delete",
              icon: Icons.delete,
              onPressed: onDeleted,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: MyColors.coolPurple2,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                height: 70,
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: iconUrl,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$language - ${dub & sub
                          ? "Dub | Sub"
                          : sub
                          ? "Sub"
                          : dub
                          ? "Dub"
                          : "not specified"}",
                      style: const TextStyle(
                        color: MyColors.unselectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

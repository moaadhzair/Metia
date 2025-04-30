import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:metia/constants/Colors.dart';

class AnimePage extends StatefulWidget {
  final Map<String, dynamic> animeData;

  const AnimePage({super.key, required this.animeData});

  @override
  State<AnimePage> createState() => _AnimePageState();
}

class _AnimePageState extends State<AnimePage> {
  Future<Uint8List> _fetchAndCropImage(String url) async {
    final response = await http.get(Uri.parse(url));
    final original = img.decodeImage(response.bodyBytes);
    if (original == null) {
      throw Exception('Failed to decode image');
    }
    final cropTop = (original.height * 0.15).round();
    final cropHeight = (original.height * 0.7).round();
    final safeCropHeight =
        (cropTop + cropHeight > original.height)
            ? original.height - cropTop
            : cropHeight;
    final cropped = img.copyCrop(
      original,
      x: 0,
      y: cropTop,
      width: original.width,
      height: safeCropHeight,
    );
    return Uint8List.fromList(img.encodeJpg(cropped));
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.animeData["media"]["coverImage"]["extraLarge"];
    final title = widget.animeData["media"]["title"]["english"] ??
        widget.animeData["media"]["title"]["romaji"] ??
        widget.animeData["media"]["title"]["native"] ??
        "Unknown Title";

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: Stack(
        children: [
          // Main Cropped Image
          FutureBuilder<Uint8List>(
            future: _fetchAndCropImage(imageUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Failed to load image'));
              }
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,      // Fully visible at the top
                      Colors.transparent // Fully transparent at the bottom
                    ],
                    stops: [0.1, 1.0],   // Fade starts at 70%, ends at 100%
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.memory(
                  snapshot.data!,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              );
            },
          ),
          // Glassy Floating AppBar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35), // subtle white border
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.white.withOpacity(0.18),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30,),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

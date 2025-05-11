import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimeCard2 extends StatelessWidget {
  final int index;
  
  final String title;
  final String imageUrl;
  final void Function(String title)? onTap;

  const AnimeCard2({
    super.key,
    required this.index,
    //required this.data,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Column(
            children: [
              Expanded(
                flex: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.hardEdge,
                  child: AspectRatio(
                    aspectRatio: 2/3,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.fitHeight,
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
              const SizedBox(height: 5),
              Expanded(
                // Title
                flex: 2,
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.5,
                  ),
                ),
              ),
              ],
          ),
        ),
        GestureDetector(
          onTap: () => onTap?.call(title),
          behavior: HitTestBehavior.translucent, // Ensures taps are registered
        ),
      ],
    );
  }
}

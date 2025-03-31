import 'package:flutter/material.dart';
import 'package:metia/tools.dart';

class AnimeCard extends StatelessWidget {
  final String tabName;
  final int index;
  final Map<String, dynamic> data;

  const AnimeCard({
    super.key,
    required this.tabName,
    required this.index,
    required this.data, // Require the poster URL
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Tools.Toast(context, data.toString());
      },
      child: Image.network(
        
        data["coverImage"]["extraLarge"], // Use the passed poster URL
        fit: BoxFit.fitHeight,
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Icon(Icons.error, color: Colors.red));
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

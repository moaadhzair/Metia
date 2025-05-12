import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.StreamData});

  final List<dynamic> StreamData;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController videoPlayerController;

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: AspectRatio(
          aspectRatio: videoPlayerController.value.aspectRatio,
          child: VideoPlayer(videoPlayerController),
        ),
      ),
    );
  }
  
  void initializeVideoPlayer() async{
    videoPlayerController = VideoPlayerController.network(
      widget.StreamData[0]["m3u8"],
    );
    await videoPlayerController.initialize();
    setState(() {});
  }
}

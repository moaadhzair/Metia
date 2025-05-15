import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

import 'package:flutter/services.dart';
import 'package:metia/api/extension.dart';
import 'dart:async';

import 'package:metia/constants/Colors.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.extensionStreamData,
    required this.anilistData,
    required this.episodeNumber,
    required this.extensionEpisodeData,
    required this.episodeCount,
    required this.currentExtension,
    required this.episodeList,
  });

  final dynamic extensionStreamData;
  final dynamic anilistData;
  final int episodeNumber;
  final dynamic extensionEpisodeData;
  final int episodeCount;
  final Extension? currentExtension;
  final List<dynamic> episodeList;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late dynamic extensionStreamData = widget.extensionStreamData;
  late dynamic anilistData = widget.anilistData;
  late int episodeNumber = widget.episodeNumber;
  late dynamic extensionEpisodeData = widget.extensionEpisodeData;
  late int episodeCount = widget.episodeCount;
  late Extension? currentExtension = widget.currentExtension;
  late List<dynamic> episodeList = widget.episodeList;

  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  String totalTime = "00:00";
  String currentTime = "00:00";
  bool hasHours = false;

  Timer? _hideTimer;
  Timer? _seekTimer;
  Timer? _seekDisplayTimer;

  bool _showControls = true;
  bool _showSeekDisplay = false;
  int _seekSeconds = 0;
  DateTime? _lastDoubleTapTime;
  Offset? _lastTapPosition;

  String _formatDuration(Duration duration, {bool forceHours = false}) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0 || forceHours) {
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 2700), () {
      // Change this line
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void nextEpisode() {
    currentExtension?.getStreamData(episodeList[episodeNumber]["id"]).then((value) {
      // Parse the stream data response

      List<dynamic> providers = value;

      // Sort providers by quality (assuming quality is in the provider name)
      providers.sort((a, b) {
        // Extract quality numbers (e.g. "720p" -> 720)
        int qualityA =
            int.tryParse(RegExp(r'(\d+)p').firstMatch(a["provider"])?.group(1) ?? "0") ?? 0;
        int qualityB =
            int.tryParse(RegExp(r'(\d+)p').firstMatch(b["provider"])?.group(1) ?? "0") ?? 0;
        return qualityB.compareTo(qualityA); // Higher quality first
      });

      // First try to find highest quality dubbed version
      var preferedProvider = providers.firstWhere(
        (provider) => provider["dub"] == true,
        orElse: () => providers.first, // If no dub found, take highest quality
      );

      extensionEpisodeData = episodeList[episodeNumber];
      extensionStreamData = value;
      anilistData;
      episodeNumber++;

      player.open(Media(preferedProvider["m3u8"])).then((value) {
        _startHideTimer();
      });
    });
  }

  void pastEpisode() {
    currentExtension?.getStreamData(episodeList[episodeNumber - 2]["id"]).then((value) {
      // Parse the stream data response

      List<dynamic> providers = value;

      // Sort providers by quality (assuming quality is in the provider name)
      providers.sort((a, b) {
        // Extract quality numbers (e.g. "720p" -> 720)
        int qualityA =
            int.tryParse(RegExp(r'(\d+)p').firstMatch(a["provider"])?.group(1) ?? "0") ?? 0;
        int qualityB =
            int.tryParse(RegExp(r'(\d+)p').firstMatch(b["provider"])?.group(1) ?? "0") ?? 0;
        return qualityB.compareTo(qualityA); // Higher quality first
      });

      // First try to find highest quality dubbed version
      var preferedProvider = providers.firstWhere(
        (provider) => provider["dub"] == true,
        orElse: () => providers.first, // If no dub found, take highest quality
      );

      extensionEpisodeData = episodeList[episodeNumber - 2];
      extensionStreamData = value;
      anilistData;
      episodeNumber--;

      player.open(Media(preferedProvider["m3u8"])).then((value) {
        _startHideTimer();
      });
    });
  }

  @override
  void initState() {
    super.initState();

    // Force landscape only when this page is visible
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listen to player state changes
    player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() {
          hasHours = duration.inHours > 0;
          totalTime = _formatDuration(duration);
        });
      }
    });

    // Listen to position changes
    player.stream.position.listen((position) {
      if (mounted) {
        setState(() {
          currentTime = _formatDuration(position, forceHours: hasHours);
        });
      }
    });

    player.open(Media(extensionStreamData["m3u8"])).then((value) {
      _startHideTimer();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekTimer?.cancel();
    _seekDisplayTimer?.cancel();
    // Restore your app's normal orientations when leaving this page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Video(
            controller: controller,
            aspectRatio: 16.0 / 9.0,
            controls: (state) {
              return GestureDetector(
                onDoubleTapDown: (details) {
                  _lastTapPosition = details.globalPosition;
                },
                onDoubleTap: () {
                  if (_lastTapPosition == null) return;

                  final screenWidth = MediaQuery.of(context).size.width;
                  final isLeftSide = _lastTapPosition!.dx < screenWidth / 2;

                  final now = DateTime.now();
                  if (_lastDoubleTapTime != null &&
                      now.difference(_lastDoubleTapTime!).inSeconds <= 1) {
                    setState(() {
                      _seekSeconds += isLeftSide ? -10 : 10;
                    });
                  } else {
                    setState(() {
                      _seekSeconds = isLeftSide ? -10 : 10;
                    });
                  }
                  _lastDoubleTapTime = now;

                  player.seek(player.state.position + Duration(seconds: isLeftSide ? -10 : 10));

                  setState(() {
                    _showSeekDisplay = true;
                  });

                  // If controls are visible, reset the hide timer
                  if (_showControls) {
                    _startHideTimer();
                  }

                  _seekDisplayTimer?.cancel();
                  _seekDisplayTimer = Timer(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _showSeekDisplay = false;
                      });
                      // Reset the seek seconds after the fade animation is complete
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _seekSeconds = 0;
                          });
                        }
                      });
                    }
                  });
                },
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                    if (_showControls) {
                      _startHideTimer();
                    } else {
                      _hideTimer?.cancel();
                    }
                  });
                },
                child: Stack(
                  children: [
                    // This transparent container ensures the GestureDetector covers the full area
                    Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // Seek indicator with fade animation
                    Positioned(
                      left:
                          _seekSeconds < 0
                              ? MediaQuery.of(context).size.width * 0.25 -
                                  50 // Subtract half of approximate container width
                              : MediaQuery.of(context).size.width * 0.75 -
                                  50, // Subtract half of approximate container width
                      top:
                          MediaQuery.of(context).size.height * 0.5 -
                          25, // Subtract half of approximate container height
                      child: AnimatedOpacity(
                        opacity: _showSeekDisplay ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_seekSeconds > 0 ? "+" : ""}${_seekSeconds}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child:
                          _showControls
                              ? Stack(
                                key: const ValueKey<String>('controls'),
                                children: [
                                  Container(
                                    color: Colors.black.withOpacity(0.5),
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Column(
                                    children: [
                                      //top  => back icon, title. done
                                      Container(
                                        padding: const EdgeInsets.only(left: 6),
                                        width: double.infinity,
                                        height: MediaQuery.of(context).size.height * 0.3,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(Icons.arrow_back),
                                            ),
                                            const SizedBox(width: 6),
                                            Center(
                                              child: Text(
                                                extensionEpisodeData["name"],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      //middle => play, pause, next episode, past episode. done
                                      SizedBox(
                                        width: double.infinity,
                                        height: MediaQuery.of(context).size.height * 0.4,
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            spacing: 40,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  _startHideTimer();
                                                  if (episodeNumber == 1) {
                                                    return;
                                                  }
                                                  print("returned");
                                                  // Add your back episode logic here
                                                  pastEpisode();
                                                },
                                                icon: Icon(
                                                  Icons.arrow_back,
                                                  size: 40,
                                                  color:
                                                      episodeNumber == 1
                                                          ? MyColors.unselectedColor
                                                          : Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  _startHideTimer();
                                                  setState(() {
                                                    player.playOrPause();
                                                  });
                                                },
                                                icon: Icon(
                                                  player.state.playing
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  // Add your next episode logic here
                                                  if (episodeNumber == episodeCount) {
                                                    return;
                                                  }
                                                  nextEpisode();
                                                  _startHideTimer();
                                                },
                                                icon: Icon(
                                                  Icons.arrow_forward,
                                                  size: 40,
                                                  color:
                                                      episodeNumber == episodeCount
                                                          ? MyColors.unselectedColor
                                                          : Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      //bottom => current time, seekbar, duration
                                      Container(
                                        alignment: Alignment.bottomCenter,
                                        width: double.infinity,
                                        height: MediaQuery.of(context).size.height * 0.3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                currentTime,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Expanded(
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Buffering progress
                                                    SliderTheme(
                                                      data: SliderThemeData(
                                                        trackHeight: 2.0,
                                                        thumbShape: SliderComponentShape.noThumb,
                                                        overlayShape:
                                                            SliderComponentShape.noOverlay,
                                                        activeTrackColor: Colors.white.withOpacity(
                                                          0.3,
                                                        ),
                                                        inactiveTrackColor: Colors.white
                                                            .withOpacity(0.1),
                                                      ),
                                                      child: Slider(
                                                        min: 0,
                                                        max:
                                                            player.state.duration.inSeconds
                                                                .toDouble(),
                                                        value:
                                                            player.state.buffer.inSeconds
                                                                .toDouble(),
                                                        onChanged: null,
                                                      ),
                                                    ),
                                                    // Playback progress
                                                    SliderTheme(
                                                      data: const SliderThemeData(
                                                        trackHeight: 2.0,
                                                        activeTrackColor: MyColors.coolPurple,
                                                        inactiveTrackColor: MyColors.coolPurple2,
                                                      ),
                                                      child: Slider(
                                                        min: 0,
                                                        max:
                                                            player.state.duration.inSeconds
                                                                .toDouble(),
                                                        value:
                                                            player.state.position.inSeconds
                                                                .toDouble(),
                                                        onChanged: (value) {
                                                          _startHideTimer();
                                                          if (mounted) {
                                                            setState(() {
                                                              player.seek(
                                                                Duration(seconds: value.toInt()),
                                                              );
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                totalTime,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

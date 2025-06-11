import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

import 'package:flutter/services.dart';
import 'package:metia/api/anilist_api.dart';
import 'package:metia/api/extension.dart';
import 'dart:async';

import 'package:metia/constants/Colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

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

  bool _isFullscreen = false;

  String totalTime = "00:00";
  String currentTime = "00:00";
  bool hasHours = false;

  Timer? _hideTimer;
  Timer? _seekTimer;
  Timer? _seekDisplayTimer;
  double? _dragValue;

  bool _showControls = true;
  bool _showSeekDisplay = false;
  int _seekSeconds = 0;
  DateTime? _lastDoubleTapTime;
  Offset? _lastTapPosition;

  bool firstTime = true;
  Timer? _positionSaveTimer;

  bool _isPlaying = true;

  bool _is2xRate = false;


  Duration parseDuration(String timeString) {
  final parts = timeString.split(':').map(int.parse).toList();

  if (parts.length == 2) {
    return Duration(minutes: parts[0], seconds: parts[1]);
  } else if (parts.length == 3) {
    return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
  } else {
    throw const FormatException("Invalid time format");
  }
}


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
    _hideTimer = Timer(const Duration(seconds: 5), () {
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
        int qualityA = int.tryParse(RegExp(r'(\d+)p').firstMatch(a["provider"])?.group(1) ?? "0") ?? 0;
        int qualityB = int.tryParse(RegExp(r'(\d+)p').firstMatch(b["provider"])?.group(1) ?? "0") ?? 0;
        return qualityB.compareTo(qualityA); // Higher quality first
      });

      // First try to find highest quality dubbed version
      var preferedProvider = providers.firstWhere(
        (provider) => provider["dub"] == true,
        orElse: () => providers.first, // If no dub found, take highest quality
      );

      if ((anilistData["progress"] ?? 0) < episodeNumber) {
        AnilistApi.updateAnimeTracking(
          mediaId: anilistData["media"]["id"],
          progress: episodeNumber,
          status: anilistData["media"]["episodes"] == episodeNumber ? "COMPLETED" : "CURRENT",
        );
      }

      extensionEpisodeData = episodeList[episodeNumber];
      extensionStreamData = preferedProvider;
      anilistData;
      episodeNumber++;

      player.open(Media(preferedProvider["m3u8"])).then((value) {
        firstTime = true;
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
        int qualityA = int.tryParse(RegExp(r'(\d+)p').firstMatch(a["provider"])?.group(1) ?? "0") ?? 0;
        int qualityB = int.tryParse(RegExp(r'(\d+)p').firstMatch(b["provider"])?.group(1) ?? "0") ?? 0;
        return qualityB.compareTo(qualityA); // Higher quality first
      });

      // First try to find highest quality dubbed version
      var preferedProvider = providers.firstWhere(
        (provider) => provider["dub"] == true,
        orElse: () => providers.first, // If no dub found, take highest quality
      );

      extensionEpisodeData = episodeList[episodeNumber - 2];
      extensionStreamData = preferedProvider;
      anilistData;
      episodeNumber--;

      player.open(Media(preferedProvider["m3u8"])).then((value) {
        firstTime = true;
        _startHideTimer();
      });
    });
  }

  void _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
    }
  }

  @override
  void initState() {
    super.initState();

    // Force landscape only when this page is visible
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
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

    // Listen to player state changes for play/pause
    player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    // Listen to position changes
    firstTime = true;
    SharedPreferences.getInstance().then((prefs) {
      player.stream.position.listen((position) async {
        prefs.setStringList('last_position_${anilistData["media"]["id"].toString()}_${(episodeNumber - 1).toString()}', [
          position.inMilliseconds.toString(),
          parseDuration(totalTime).inMilliseconds.toString()
        ]);
      });
      
    });

    player.stream.position.listen((position) async {
      // Check if episode is near completion (2 minutes left)
      if (player.state.duration.inSeconds != 0) {
        if (position.inSeconds >= player.state.duration.inSeconds - 120) {
          // Update Anilist tracking for next episode
          if (firstTime) {
            firstTime = false;
            if ((anilistData["progress"] ?? 0) < episodeNumber) {
              AnilistApi.updateAnimeTracking(
                mediaId: anilistData["media"]["id"],
                progress: episodeNumber,
                status: anilistData["media"]["episodes"] == episodeNumber ? "COMPLETED" : "CURRENT",
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          currentTime = _formatDuration(position, forceHours: hasHours);
        });
      }
    });

    initPlayer();
  }

  Future<void> initPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> prefss = prefs.getStringList("last_position_${anilistData["media"]["id"].toString()}_${(episodeNumber - 1).toString()}") ?? [];

    final int lastPosPref = int.parse(prefss.isNotEmpty ? prefss[0] :"0");
    final lastPos = lastPosPref ?? 0;

    await player.open(
      Media(extensionStreamData["m3u8"] ?? extensionStreamData["link"], httpHeaders: {"referer": extensionStreamData["referer"] ?? ""}),
      play: true,
    );

    if (lastPos > 0) {
      // Wait for the duration to be available before seeking
      late StreamSubscription sub;
      sub = player.stream.duration.listen((duration) async {
        if (duration.inSeconds > 0) {
          await player.seek(Duration(milliseconds: lastPos));
          await sub.cancel();
        }
      });
    }
    _startHideTimer();
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
    if (!(Platform.isAndroid || Platform.isIOS)) windowManager.setFullScreen(false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RawKeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKey: (RawKeyEvent event) async {
            if (event is RawKeyDownEvent) {
              // Spacebar: Play/Pause
              if (event.logicalKey == LogicalKeyboardKey.space) {
                if (player.state.playing) {
                  player.pause();
                } else {
                  player.play();
                }
              }
              // Left Arrow: Seek backward 10 seconds
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                player.seek(player.state.position - const Duration(seconds: 10));
              }
              // Right Arrow: Seek forward 10 seconds
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                player.seek(player.state.position + const Duration(seconds: 10));
              }
              if (event.logicalKey == LogicalKeyboardKey.f12) {
                if (_isFullscreen) {
                  await windowManager.setFullScreen(true);
                } else {
                  await windowManager.setFullScreen(false);
                }
              }
            }
          },
          child: Stack(
            children: [
              Video(
                controller: controller,
                aspectRatio: 16.0 / 9.0,
                controls: (state) {
                  return GestureDetector(
                    onLongPressStart: (details) async {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isLeftSide = details.globalPosition.dx > screenWidth / 2;
                      if (isLeftSide) {
                        player.setRate(2.0);
                        _is2xRate = true;
                      }
                    },
                    onLongPressEnd: (details) {
                      player.setRate(1.0);
                      _is2xRate = false;
                    },
                    onDoubleTapDown: (details) {
                      _lastTapPosition = details.globalPosition;
                    },
                    onDoubleTap: () {
                      if (_lastTapPosition == null) return;

                      final screenWidth = MediaQuery.of(context).size.width;
                      final isLeftSide = _lastTapPosition!.dx < screenWidth / 2;

                      final now = DateTime.now();
                      if (_lastDoubleTapTime != null && now.difference(_lastDoubleTapTime!).inSeconds <= 1) {
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
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          // This transparent container ensures the GestureDetector covers the full area
                          Container(color: Colors.transparent, width: double.infinity, height: double.infinity),

                          // Seek indicator with fade animation
                          Positioned(
                            left:
                                _seekSeconds < 0
                                    ? MediaQuery.of(context).size.width * 0.25 -
                                        50 // Subtract half of approximate container width
                                    : MediaQuery.of(context).size.width * 0.75 - 50, // Subtract half of approximate container width
                            top: MediaQuery.of(context).size.height * 0.5 - 25, // Subtract half of approximate container height
                            child: AnimatedOpacity(
                              opacity: _showSeekDisplay ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${_seekSeconds > 0 ? "+" : ""}${_seekSeconds}s',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left:
                                _seekSeconds < 0
                                    ? MediaQuery.of(context).size.width * 0.25 -
                                        50 // Subtract half of approximate container width
                                    : MediaQuery.of(context).size.width * 0.75 - 50, // Subtract half of approximate container width
                            top: MediaQuery.of(context).size.height * 0.5 - 25, // Subtract half of approximate container height
                            child: AnimatedOpacity(
                              opacity: _is2xRate ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                                child: const Text("2X speed", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            reverseDuration: const Duration(milliseconds: 300),
                            duration: const Duration(milliseconds: 300),
                            child:
                                _showControls
                                    ? Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.85), // Top
                                                Colors.transparent, // Just above middle
                                                Colors.transparent, // Just below middle
                                                Colors.black.withOpacity(0.85), // Bottom
                                              ],
                                              stops: const [
                                                0.0, // Top
                                                0.45, // Fade to transparent
                                                0.55, // Stay transparent
                                                1.0, // Fade back to black
                                              ],
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            //top  => back icon, title. done
                                            Container(
                                              //height: MediaQuery.of(context).size.height * 0.3,
                                              width: double.maxFinite,
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop("setState");
                                                    },
                                                    icon: const Icon(Icons.arrow_back, color: MyColors.unselectedColor),
                                                  ),
                                                  Container(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          extensionEpisodeData["name"].toString(),
                                                          style: const TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.w500),
                                                        ),
                                                        Text(
                                                          extensionStreamData["title"].toString(),
                                                          style: const TextStyle(
                                                            fontSize: 17,
                                                            color: MyColors.unselectedColor,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            //middle => play, pause, next episode, past episode. done
                                            SizedBox(
                                              width: double.infinity,
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  spacing: 40,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(50),
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          _startHideTimer();
                                                          if (episodeNumber == 1) {
                                                            return;
                                                          }
                                                          pastEpisode();
                                                        },
                                                        icon: Icon(
                                                          Icons.arrow_back,
                                                          size: 40,
                                                          color: episodeNumber == 1 ? const Color.fromARGB(255, 51, 50, 51) : Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(50),
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          if (player.state.playing) {
                                                            player.pause();
                                                          } else {
                                                            player.play();
                                                          }
                                                        },
                                                        icon: Icon(
                                                          player.state.playing ? Icons.pause : Icons.play_arrow,
                                                          size: 40,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(50),
                                                      ),
                                                      child: IconButton(
                                                        onPressed: () {
                                                          if (episodeNumber == episodeCount) {
                                                            return;
                                                          }
                                                          nextEpisode();
                                                          _startHideTimer();
                                                        },
                                                        icon: Icon(
                                                          Icons.arrow_forward,
                                                          size: 40,
                                                          color: episodeNumber == episodeCount ? const Color.fromARGB(255, 51, 50, 51) : Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            //bottom => current time, seekbar, duration
                                            Container(
                                              alignment: Alignment.center,
                                              width: double.infinity,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  spacing: 10,
                                                  children: [
                                                    Text(
                                                      currentTime,
                                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                                    ),
                                                    // ...inside your build method...
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 30,
                                                        child: Stack(
                                                          alignment: Alignment.centerLeft,
                                                          children: [
                                                            // Buffering bar (background)
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                                              child: Stack(
                                                                children: [
                                                                  Container(
                                                                    height: 4,
                                                                    decoration: BoxDecoration(
                                                                      color: MyColors.coolPurple.withOpacity(0.3),
                                                                      borderRadius: BorderRadius.circular(2),
                                                                    ),
                                                                  ),
                                                                  // Buffered progress
                                                                  FractionallySizedBox(
                                                                    widthFactor:
                                                                        player.state.duration.inSeconds == 0
                                                                            ? 0
                                                                            : player.state.buffer.inSeconds / player.state.duration.inSeconds,
                                                                    child: Container(
                                                                      height: 4,
                                                                      decoration: BoxDecoration(
                                                                        color: MyColors.coolPurple,
                                                                        borderRadius: BorderRadius.circular(2),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  // Playback progress (white)
                                                                  // Playback progress (white)
                                                                  FractionallySizedBox(
                                                                    widthFactor:
                                                                        player.state.duration.inSeconds == 0
                                                                            ? 0
                                                                            : (_dragValue ?? player.state.position.inSeconds.toDouble()) /
                                                                                player.state.duration.inSeconds,
                                                                    child: Container(
                                                                      height: 4,
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        borderRadius: BorderRadius.circular(2),
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  // Slider thumb (interactive)
                                                                ],
                                                              ),
                                                            ),
                                                            SliderTheme(
                                                              data: SliderTheme.of(context).copyWith(
                                                                trackHeight: 0,
                                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                                                activeTrackColor: Colors.transparent,
                                                                inactiveTrackColor: Colors.transparent,
                                                              ),
                                                              child: Slider(
                                                                min: 0,
                                                                max: player.state.duration.inSeconds.toDouble(),
                                                                value:
                                                                    _dragValue ??
                                                                    player.state.position.inSeconds.toDouble().clamp(
                                                                      0,
                                                                      player.state.duration.inSeconds.toDouble(),
                                                                    ),
                                                                onChanged: (value) {
                                                                  _startHideTimer();
                                                                  setState(() {
                                                                    _dragValue = value;
                                                                  });
                                                                },
                                                                onChangeEnd: (value) {
                                                                  setState(() {
                                                                    _dragValue = null;
                                                                  });
                                                                  player.seek(Duration(seconds: value.toInt()));
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      totalTime,
                                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                                    ),
                                                    !(Platform.isIOS || Platform.isAndroid)
                                                        ? IconButton(
                                                          icon: Icon(
                                                            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                                            size: 30,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed: _toggleFullscreen,
                                                        )
                                                        : const SizedBox(),
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

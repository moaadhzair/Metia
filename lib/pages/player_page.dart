import 'package:flutter/material.dart';

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

import 'package:flutter/services.dart';
import 'dart:async';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.StreamData});

  final dynamic StreamData;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  String totalTime = "00:00";
  String currentTime = "00:00";
  bool hasHours = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideTimer;
  int _seekAmount = 0;
  Timer? _seekTimer;
  bool _showSeekIndicator = false;
  int _lastSeekDirection = 0; // -1 for rewind, 1 for forward, 0 for none

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
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideTimer();
  }

  void _showSeekIndicatorTemporarily() {
    _seekTimer?.cancel();
    setState(() {
      _showSeekIndicator = true;
    });
    _seekTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSeekIndicator = false;
          // Do NOT reset _seekAmount here
        });
      }
    });
  }

  void _handleSeek(Duration seekDuration) {
    int direction = seekDuration.inSeconds.sign;
    // If direction changes, reset the accumulated seek
    if (_lastSeekDirection != direction) {
      _seekAmount = 0;
    }
    _lastSeekDirection = direction;

    _showSeekIndicatorTemporarily();
    setState(() {
      _seekAmount += seekDuration.inSeconds;
    });
    final duration = player.state.duration;
    final newPosition = player.state.position + seekDuration;
    // Prevent seeking past the start/end
    if (newPosition < Duration.zero) {
      player.seek(Duration.zero);
    } else if (newPosition > duration) {
      player.seek(duration);
    } else {
      player.seek(newPosition);
    }
  }

  @override
  void initState() {
    super.initState();
    // Force landscape only when this page is visible
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

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

    player.open(Media(widget.StreamData["m3u8"]));

    _startHideTimer();
  }

  void _toggleFullscreen(VideoState state) {
    if (!mounted) return;

    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        state.enterFullscreen();
      } else {
        state.exitFullscreen();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekTimer?.cancel();
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
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9.0 / 16.0,
          child: GestureDetector(
            onTap: _showControlsTemporarily,
            child: Video(
              controller: controller,
              aspectRatio: 16.0 / 9.0,
              controls: (state) {
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          _showControlsTemporarily();
                          _handleSeek(const Duration(seconds: -10));
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _showSeekIndicator && _seekAmount < 0 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '${_seekAmount}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right side for fast forward
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          _showControlsTemporarily();
                          _handleSeek(const Duration(seconds: 10));
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _showSeekIndicator && _seekAmount > 0 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  '+${_seekAmount}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Header with episode title
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Icon(Icons.arrow_back_sharp, size: 30, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Episode 1",
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Video controls
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _showControlsTemporarily();
                                  if (player.state.playing) {
                                    player.pause();
                                  } else {
                                    player.play();
                                  }
                                },
                                icon: Icon(
                                  player.state.playing ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              Text(
                                currentTime,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              Expanded(
                                child: Slider(
                                  value: player.state.position.inSeconds.toDouble(),
                                  min: 0,
                                  max: player.state.duration.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    _showControlsTemporarily();
                                    if (mounted) {
                                      setState(() {
                                        player.seek(Duration(seconds: value.toInt()));
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text(
                                totalTime,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showControlsTemporarily();
                                  _toggleFullscreen(state);
                                },
                                icon: Icon(
                                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Left side for rewind
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class WorkoutVideoPlayer extends StatefulWidget {
  final String videoUrl;
  
  // FIX: Added 'required this.videoUrl' to the constructor
  const WorkoutVideoPlayer({super.key, required this.videoUrl});

  @override
  WorkoutVideoPlayerState createState() => WorkoutVideoPlayerState();
}

class WorkoutVideoPlayerState extends State<WorkoutVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // FIX: used networkUrl instead of deprecated .network
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {}); 
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
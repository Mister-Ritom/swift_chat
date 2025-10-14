import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String video; // local path or network URL
  final bool isNetwork;
  final double width;
  final double height;

  const VideoThumbnailWidget({
    super.key,
    required this.video,
    this.isNetwork = false,
    this.width = 80,
    this.height = 80,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isNetwork) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video))
        ..initialize().then((_) {
          setState(() {
            _initialized = true; // thumbnail ready
          });
        });
    } else {
      _controller = VideoPlayerController.file(File(widget.video))
        ..initialize().then((_) {
          setState(() {
            _initialized = true; // thumbnail ready
          });
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(_controller),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
        : Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 36,
              color: Colors.black54,
            ),
          ),
        );
  }
}

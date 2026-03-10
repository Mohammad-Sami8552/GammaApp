import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoTile extends StatefulWidget{
 final String videoUrl;
 final String username;
 final String caption;
 final String likes;
 const VideoTile({
  super.key,
  required this.videoUrl,
  required this.username,
  required this.caption,
  required this.likes
  });
 @override 
 State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
late VideoPlayerController _controller;
bool _isInitialized = false;
@override 
void initState() {
  super.initState();
  _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
     ..initialize().then((_) {
      setState(() {
        _isInitialized = true;
        _controller.setLooping(true);
        _controller.play();
      });
     });
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

@
override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: _isInitialized ? 
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
            )
            : const CircularProgressIndicator(color: Colors.white,)
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                if(kIsWeb && _controller.value.volume == 0.0) {
                  _controller.setVolume(1.0);
                }
                else {
                _controller.value.isPlaying ? _controller.pause():_controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: _isInitialized
              ? (_controller.value.volume == 0.0  && kIsWeb) 
              ? const Icon(Icons.volume_off, size: 50, color: Colors.white54)
              : !_controller.value.isPlaying 
              ? const Icon(Icons.play_arrow, size: 60, color: Colors.white54,) 
              :null
            :null
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 20, color: Colors.black,),
                    ),
                    const SizedBox(width: 10,),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10,),
                Text(
                  widget.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            right: 10,
            child: Column(
              children: [
                _buildActionButton(Icons.favorite, widget.likes, Colors.red),
                const SizedBox(height: 20,),
                _buildActionButton(Icons.comment, "45", Colors.white),
                _buildActionButton(Icons.share, "Shares", Colors.white)
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 35, color: color),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12),)
      ],
    );
  }
}
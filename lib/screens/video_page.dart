// Not integrated yet in future will see to include it
import 'package:flutter/material.dart';
import 'package:gamma_app/widgets/video_tile.dart';

class VideoFeedScreen extends StatelessWidget {
 VideoFeedScreen({super.key});
  final List<Map<String, String>> _videos = [
{
      "url": "https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-1232-large.mp4",
      "username": "@neon_girl",
      "caption": "Loving the city lights! 🌃 #nightlife",
      "likes": "1.2k"
    },

    {
      "url": "https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4",
      "username": "@nature_lover",
      "caption": "Spring is here! 🌸 #flowers #nature",
      "likes": "850"
    },

    {
      "url": "https://assets.mixkit.co/videos/preview/mixkit-mother-with-her-little-daughter-eating-a-marshmallow-in-nature-39764-large.mp4",
      "username": "@family_time",
      "caption": "Marshmallows! 🍬 #camping",
      "likes": "2.1k"
    },


  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation:0,
        title: const Text("Reels", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt)),
        ],
        ),
        body: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            return VideoTile(videoUrl: _videos[index]['url']!, username: _videos[index]['username']!, caption: _videos[index]['caption']!, likes: _videos[index]['likes']!);
          }
          ),
      
    );
  }
  
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YouTubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String videoId = '';
    // YouTube player iframe uses YoutubePlayerController.fromVideoId
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null) {
      if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
        videoId = uri.queryParameters['v'] ?? '';
      } else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      }
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0,
       ),
      body: ListView(
        children: [
          YoutubePlayer(
             controller: _controller,
             aspectRatio: 16 / 9,
           ),
           Padding(
            padding: const EdgeInsets.all(20.0),
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                Text(
                   widget.title,
                  style: const TextStyle(
                     fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                 const SizedBox(height: 12),
                 const Text(
                   "Video Lesson",
                   style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                 ),
                 const SizedBox(height: 24),
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: const Color(0xFF1B5E20).withOpacity(0.05),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.1)),
                   ),
                   child: const Row(
                     children: [
                       Icon(Icons.info_outline, color: Color(0xFF1B5E20)),
                       SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           "You are viewing this content natively inside the Vaagai App.",
                           style: TextStyle(fontSize: 13, height: 1.4),
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}

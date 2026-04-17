import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt_iframe;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt_flutter;

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
  yt_iframe.YoutubePlayerController? _iframeController;
  yt_flutter.YoutubePlayerController? _flutterController;
  String? videoId;

  @override
  void initState() {
    super.initState();
    _extractVideoId();

    if (videoId != null && videoId!.isNotEmpty) {
      if (kIsWeb) {
        _initIframeController();
      } else {
        _initFlutterController();
      }
    }
  }

  void _extractVideoId() {
    // Try both packages' converters
    videoId = yt_iframe.YoutubePlayerController.convertUrlToId(widget.videoUrl);
    videoId ??= yt_flutter.YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId == null && widget.videoUrl.contains('/shorts/')) {
      final match = RegExp(r'shorts/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      if (match != null) videoId = match.group(1);
    }
  }

  void _initIframeController() {
    _iframeController = yt_iframe.YoutubePlayerController.fromVideoId(
      videoId: videoId!,
      autoPlay: true,
      params: const yt_iframe.YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        enableJavaScript: true,
        origin: 'https://www.youtube.com',
      ),
    );
  }

  void _initFlutterController() {
    _flutterController = yt_flutter.YoutubePlayerController(
      initialVideoId: videoId!,
      flags: const yt_flutter.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _iframeController?.close();
    _flutterController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Widget _buildPlayer() {
    if (videoId == null || videoId!.isEmpty) {
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(child: Text("Invalid YouTube URL", style: TextStyle(color: Colors.red))),
      );
    }

    if (kIsWeb && _iframeController != null) {
      return yt_iframe.YoutubePlayer(
        controller: _iframeController!,
        aspectRatio: 16 / 9,
      );
    } else if (!kIsWeb && _flutterController != null) {
      return yt_flutter.YoutubePlayer(
        controller: _flutterController!,
        showVideoProgressIndicator: true,
      );
    }

    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
  }

  @override
  Widget build(BuildContext context) {
    // The iframe package provides a specialized scaffold for full screen handling
    if (kIsWeb && _iframeController != null) {
      return yt_iframe.YoutubePlayerScaffold(
        controller: _iframeController!,
        aspectRatio: 16 / 9,
        builder: (context, player) => _buildScaffoldContext(player),
      );
    }
    
    // For native mobile, use standard flutter architecture
    return _buildScaffoldContext(_buildPlayer());
  }

  Widget _buildScaffoldContext(Widget playerWidget) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: ListView(
        children: [
          playerWidget,
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
                  child: const Column(
                    children: [
                      Row(
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
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "If error 150/152 occurs, please ensure 'Allow embedding' is enabled in your YouTube video settings.",
                              style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
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

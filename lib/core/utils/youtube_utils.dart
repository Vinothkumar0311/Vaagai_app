import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeUtils {
  /// Safely extracts the YouTube video ID from various YouTube URL formats.
  /// Supports:
  /// - Standard: youtube.com/watch?v=xxx
  /// - Shortened: youtu.be/xxx
  /// - Shorts: youtube.com/shorts/xxx
  /// - Live: youtube.com/live/xxx
  static String? convertUrlToId(String url) {
    // 1. Try standard parser from youtube_player_flutter
    String? id = YoutubePlayer.convertUrlToId(url);
    if (id != null && id.isNotEmpty) return id;

    final trimmed = url.trim();

    // 2. Fallback for YouTube Shorts
    if (trimmed.contains('/shorts/')) {
      final match = RegExp(r'shorts/([a-zA-Z0-9_-]{11})').firstMatch(trimmed) ??
                    RegExp(r'shorts/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) return match.group(1);
    }

    // 3. Fallback for YouTube Live streams
    if (trimmed.contains('/live/')) {
      final match = RegExp(r'live/([a-zA-Z0-9_-]{11})').firstMatch(trimmed) ??
                    RegExp(r'live/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) return match.group(1);
    }

    return null;
  }

  /// Validates whether a URL is a correct YouTube video link (Watch, Shortened, Shorts, or Live).
  static bool isValidYouTubeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;

    final isYouTubeDomain = uri.host == 'youtu.be' ||
        uri.host == 'www.youtube.com' ||
        uri.host == 'youtube.com' ||
        uri.host == 'm.youtube.com';
    if (!isYouTubeDomain) return false;

    // Must have a valid structure or video ID extracted
    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty;
    }

    return uri.queryParameters.containsKey('v') ||
        uri.pathSegments.contains('shorts') ||
        uri.pathSegments.contains('live');
  }
}

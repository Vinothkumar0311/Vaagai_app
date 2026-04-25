import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt_iframe;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as yt_flutter;
import 'package:provider/provider.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import '../../core/models/doubt_model.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? courseId;
  final String? courseName;
  final String? courseImage;
  final String? videoDocId;

  const YouTubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.courseId,
    this.courseName,
    this.courseImage,
    this.videoDocId,
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
    videoId = yt_iframe.YoutubePlayerController.convertUrlToId(widget.videoUrl);
    videoId ??= yt_flutter.YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId == null && widget.videoUrl.contains('/shorts/')) {
      final match =
          RegExp(r'shorts/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
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
        child: const Center(
            child: Text("Invalid YouTube URL",
                style: TextStyle(color: Colors.red))),
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

    return const SizedBox(
        height: 200, child: Center(child: CircularProgressIndicator()));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _iframeController != null) {
      return yt_iframe.YoutubePlayerScaffold(
        controller: _iframeController!,
        aspectRatio: 16 / 9,
        builder: (context, player) => _buildScaffoldContext(player),
      );
    }
    return _buildScaffoldContext(_buildPlayer());
  }

  Future<void> _showAskDoubtModal(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to ask doubts')));
      return;
    }

    int timestamp = 0;
    if (kIsWeb) {
      final value = await _iframeController?.currentTime;
      timestamp = (value ?? 0).toInt();
    } else {
      final value = _flutterController?.value.position;
      timestamp = value?.inSeconds ?? 0;
    }

    final tc = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: StatefulBuilder(builder: (context, setStateModal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("சந்தேகம் கேட்க (Ask a Doubt)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("At ${_formatTimestamp(timestamp)}",
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tc,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "உங்கள் கேள்வியை இங்கே பதிவு செய்யவும்...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (tc.text.trim().isEmpty) return;
                          final text = tc.text.trim();

                          setStateModal(() => isSubmitting = true);

                          final doubtProvider = Provider.of<DoubtProvider>(
                              context,
                              listen: false);

                          if (widget.courseId != null) {
                            await doubtProvider.submitDoubt(
                              studentId: authProvider.userModel!.uid,
                              studentName: authProvider.userModel!.name,
                              courseId: widget.courseId!,
                              courseName: widget.courseName ?? 'Unknown Course',
                              courseImage: widget.courseImage,
                              videoId: widget.videoDocId ?? videoId ?? 'unknown',
                              videoTitle: widget.title,
                              timestampSeconds: timestamp,
                              message: text,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('உங்கள் கேள்வி ஆசிரியருக்கு அனுப்பப்பட்டது'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text("அனுப்புக (Submit Doubt)",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildScaffoldContext(Widget playerWidget) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: ListView(
        children: [
          playerWidget,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                const SizedBox(height: 4),
                const Text(
                  "Video Lesson",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (widget.courseId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ElevatedButton.icon(
                onPressed: () => _showAskDoubtModal(context),
                icon: const Icon(Icons.help_outline, color: Colors.white),
                label: const Text('சந்தேகம் கேட்க (Ask a Doubt)',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (widget.videoDocId != null || videoId != null)
            _GlobalDoubtsFeed(
              videoId: widget.videoDocId ?? videoId ?? 'unknown',
              onSeek: (seconds) {
                if (kIsWeb) {
                  _iframeController?.seekTo(
                      seconds: seconds.toDouble(), allowSeekAhead: true);
                } else {
                  _flutterController?.seekTo(Duration(seconds: seconds));
                }
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GlobalDoubtsFeed extends StatelessWidget {
  final String videoId;
  final Function(int) onSeek;

  const _GlobalDoubtsFeed({required this.videoId, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final doubtProvider = Provider.of<DoubtProvider>(context, listen: false);

    return StreamBuilder<List<DoubtModel>>(
      stream: doubtProvider.getVideoDoubts(videoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final doubts = snapshot.data!;

        if (doubts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("சந்தேகங்கள் எதுவும் இல்லை",
                style: TextStyle(color: Colors.grey)),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${doubts.length} சந்தேகங்கள் (Doubts)",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: doubts.length,
                itemBuilder: (context, i) {
                  final doubt = doubts[i];
                  return _DoubtThreadWidget(doubt: doubt, onSeek: onSeek);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoubtThreadWidget extends StatelessWidget {
  final DoubtModel doubt;
  final Function(int) onSeek;

  const _DoubtThreadWidget({required this.doubt, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.person, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('மாணவர் (Student)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              InkWell(
                onTap: () => onSeek(doubt.timestampSeconds),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _formatTimestamp(doubt.timestampSeconds),
                    style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(doubt.message,
              style:
                  const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
          if (doubt.staffReply != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified,
                          size: 14, color: Colors.green),
                      SizedBox(width: 6),
                      Text('ஆசிரியர் பதில் (Staff Reply)',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(doubt.staffReply!,
                      style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

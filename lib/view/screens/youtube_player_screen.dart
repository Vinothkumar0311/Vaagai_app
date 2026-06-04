import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt_iframe;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as yt_flutter;
import 'package:provider/provider.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import 'package:vaagai/providers/progress_provider.dart';
import 'dart:async';
import '../../core/models/doubt_model.dart';
import '../../core/utils/youtube_utils.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? courseId;
  final String? courseName;
  final String? courseImage;
  final String? videoDocId;
  final int totalVideosInCourse;
  final int? startAt;

  const YouTubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    this.courseId,
    this.courseName,
    this.courseImage,
    this.videoDocId,
    this.totalVideosInCourse = 0,
    this.startAt,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  yt_iframe.YoutubePlayerController? _iframeController;
  yt_flutter.YoutubePlayerController? _flutterController;
  Timer? _progressSyncTimer;
  int _ticksSinceLastCloudSync = 0;
  static const int _cloudSyncIntervalTicks = 24; // 2 minutes (if tick is 5s)

  ProgressProvider? _cachedProgressProvider;
  String? _cachedUid;
  bool _isMovingToNext = false;

  // Reactive State for In-Player Transitions
  late String _currentVideoId;
  late String _currentTitle;
  late String _currentUrl;
  late String _currentVideoDocId;

  @override
  void initState() {
    super.initState();
    _cachedProgressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    _cachedUid =
        Provider.of<AuthProvider>(context, listen: false).userModel?.uid;

    // Initialize Reactive State
    _currentVideoId = '';
    _currentTitle = widget.title;
    _currentUrl = widget.videoUrl;
    _currentVideoDocId = widget.videoDocId ?? 'unknown';

    _extractVideoId();

    if (_currentVideoId.isNotEmpty) {
      if (kIsWeb) {
        _initIframeController();
      } else {
        _initFlutterController();
      }
      _startProgressSync();
    }
  }

  void _startProgressSync() {
    if (widget.courseId == null || _currentVideoDocId == 'unknown') return;

    _ticksSinceLastCloudSync = 0; // Essential Reset for new video
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    progressProvider.startVideoSession(widget.courseId!, _currentVideoDocId);

    _progressSyncTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel == null) return;

      int currentPos = 0;
      int totalDur = 0;
      bool isPlaying = false;
      bool isEnded = false;

      if (kIsWeb && _iframeController != null) {
        final state = await _iframeController!.playerState;
        final cur = await _iframeController!.currentTime;
        final dur = await _iframeController!.duration;
        currentPos = cur.toInt();
        totalDur = dur.toInt();
        isPlaying = state == yt_iframe.PlayerState.playing;
        isEnded = state == yt_iframe.PlayerState.ended;
      } else if (!kIsWeb && _flutterController != null) {
        currentPos = _flutterController!.value.position.inSeconds;
        totalDur = _flutterController!.value.metaData.duration.inSeconds;
        isPlaying = _flutterController!.value.isPlaying;
        isEnded = _flutterController!.value.playerState ==
            yt_flutter.PlayerState.ended;
      }

      if (isEnded && !_isMovingToNext) {
        _isMovingToNext = true;
        _handleVideoTransition();
        return;
      }

      if (totalDur > 0) {
        // Validation: Must have actually played 90% of unique seconds
        final playedCount = progressProvider.getWatchedSecondsCount(_currentVideoDocId);
        bool isTrulyCompleted = (playedCount / totalDur) >= 0.9;
        bool durationReached = (currentPos / totalDur) >= 0.95; 

        if ((isTrulyCompleted || durationReached) && !_isMovingToNext) {
           _isMovingToNext = true;
           _handleVideoTransition();
           return;
        }

        // Tracker segment played (if playing)
        if (isPlaying || kIsWeb) {
          progressProvider.trackPlayedSecond(_currentVideoDocId, currentPos);
        }

        // High Frequency Local Save
        progressProvider.saveProgressLocally(
            courseId: widget.courseId!,
            videoId: _currentVideoDocId,
            timestamp: currentPos);

        // 3. Low Frequency Cloud Sync (Fallback)
        _ticksSinceLastCloudSync++;
        if (_ticksSinceLastCloudSync >= _cloudSyncIntervalTicks) {
          _triggerCloudSync();
          _ticksSinceLastCloudSync = 0;
        }
      }
    });
  }

  Future<void> _handleVideoTransition() async {
     _progressSyncTimer?.cancel();
     
     final nextVideo = await _findNextVideo();
     await _triggerCloudSync(forceComplete: true, nextVideoId: nextVideo?['id']);
     
     if (nextVideo != null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text("அடுத்த பாடத்திற்கு மாறுகிறது: ${nextVideo['title']}"),
         backgroundColor: const Color(0xFF1B5E20),
         duration: const Duration(seconds: 2),
       ));
       _resetLocalSession(nextVideo['id'], nextVideo['title'], nextVideo['url']);
     } else {
       _goBackToCourse();
     }
  }

  Future<Map<String, dynamic>?> _findNextVideo() async {
    if (widget.courseId == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('course_videos')
          .where('courseDocId', isEqualTo: widget.courseId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data())['createdAt'] as Timestamp?;
          final bTime = (b.data())['createdAt'] as Timestamp?;
          return (aTime ?? Timestamp(0, 0)).compareTo(bTime ?? Timestamp(0, 0));
        });

        int currentIndex = docs.indexWhere((doc) => doc.id == _currentVideoDocId);

        if (currentIndex != -1 && currentIndex + 1 < docs.length) {
          final nextDoc = docs[currentIndex + 1];
          final data = nextDoc.data();
          return {
            'id': nextDoc.id,
            'title': data['title'] ?? 'Next Chapter',
            'url': data['youtubeUrl'] ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint("Error finding next video: $e");
    }
    return null;
  }

  /// Reset all local state components for a fresh video session
  void _resetLocalSession(String newVideoDocId, String newTitle, String newUrl) {
    if (!mounted) return;
    
    setState(() {
      _isMovingToNext = false;
      _currentVideoDocId = newVideoDocId;
      _currentTitle = newTitle;
      _currentUrl = newUrl;
      
      _extractVideoId();
    });

    _loadVideoInPlayer();
    _startProgressSync();
  }

  void _loadVideoInPlayer() {
    if (_currentVideoId.isEmpty) return;
    
    if (kIsWeb && _iframeController != null) {
      _iframeController!.loadVideoById(videoId: _currentVideoId);
    } else if (!kIsWeb && _flutterController != null) {
      _flutterController!.load(_currentVideoId);
    }
  }

  void _goBackToCourse() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("அனைத்து வீடியோக்களும் முடிந்துவிட்டன!"),
      backgroundColor: Colors.green,
    ));
    Navigator.pop(context);
  }

  Future<void> _triggerCloudSync(
      {bool isDisposing = false, bool forceComplete = false, String? nextVideoId}) async {
    if (!isDisposing && !mounted) return;
    if (_cachedProgressProvider == null || _cachedUid == null) return;

    int currentPos = 0;
    int totalDur = 0;

    if (kIsWeb && _iframeController != null) {
      final cur = await _iframeController!.currentTime;
      final dur = await _iframeController!.duration;
      currentPos = cur.toInt();
      totalDur = dur.toInt();
    } else if (!kIsWeb && _flutterController != null) {
      currentPos = _flutterController!.value.position.inSeconds;
      totalDur = _flutterController!.value.metaData.duration.inSeconds;
    }

    if (totalDur > 0 && widget.courseId != null) {
      await _cachedProgressProvider!.syncProgressToCloud(
        studentId: _cachedUid!,
        courseId: widget.courseId!,
        videoId: _currentVideoDocId,
        currentTimestamp: currentPos,
        totalDuration: totalDur,
        totalVideosInCourse: widget.totalVideosInCourse,
        forceComplete: forceComplete,
        nextVideoId: nextVideoId,
      );
    }
  }

  void _extractVideoId() {
    _currentVideoId = YoutubeUtils.convertUrlToId(_currentUrl) ?? '';
  }

  void _initIframeController() {
    _iframeController = yt_iframe.YoutubePlayerController.fromVideoId(
      videoId: _currentVideoId,
      autoPlay: true,
      params: const yt_iframe.YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        enableJavaScript: true,
        origin: 'https://www.youtube.com',
      ),
    );
    if (widget.startAt != null && widget.startAt! > 0) {
      // A simple fallback for older API versions
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted)
          _iframeController!.seekTo(
              seconds: widget.startAt!.toDouble(), allowSeekAhead: true);
      });
    }
  }

  void _initFlutterController() {
    _flutterController = yt_flutter.YoutubePlayerController(
      initialVideoId: _currentVideoId,
      flags: const yt_flutter.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
        disableDragSeek: true, // Disables sliding finger horizontally on player to seek/drag
      ),
    );
    // seek if required
    if (widget.startAt != null && widget.startAt! > 0) {
      _flutterController!.seekTo(Duration(seconds: widget.startAt!));
    }
  }

  @override
  void dispose() {
    // Sync to cloud one last time on exit
    _triggerCloudSync(isDisposing: true);
    _progressSyncTimer?.cancel();
    _iframeController?.close();
    _flutterController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Widget _buildPlayer() {
    if (_currentVideoId.isEmpty) {
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

    if (_flutterController != null) {
      return yt_flutter.YoutubePlayerBuilder(
        player: yt_flutter.YoutubePlayer(
          controller: _flutterController!,
          showVideoProgressIndicator: true,
        ),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text("At ${_formatTimestamp(timestamp)}",
                    style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
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
                              videoId: _currentVideoDocId,
                              videoTitle: _currentTitle,
                              timestampSeconds: timestamp,
                              message: text,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'உங்கள் கேள்வி ஆசிரியருக்கு அனுப்பப்பட்டது'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text("அனுப்புக (Submit Doubt)",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
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
        title: Text(_currentTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  _currentTitle,
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
          _GlobalDoubtsFeed(
            key: ValueKey(_currentVideoDocId), // Forces reset of stream/state
            videoId: _currentVideoDocId,
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

class _GlobalDoubtsFeed extends StatefulWidget {
  final String videoId;
  final Function(int) onSeek;

  const _GlobalDoubtsFeed({super.key, required this.videoId, required this.onSeek});

  @override
  State<_GlobalDoubtsFeed> createState() => _GlobalDoubtsFeedState();
}

class _GlobalDoubtsFeedState extends State<_GlobalDoubtsFeed> {
  late Stream<List<DoubtModel>> _doubtStream;

  @override
  void initState() {
    super.initState();
    _doubtStream = _buildStream(widget.videoId);
  }

  @override
  void didUpdateWidget(_GlobalDoubtsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Belt-and-suspenders: if videoId changes without a key change, reset stream
    if (oldWidget.videoId != widget.videoId) {
      setState(() {
        _doubtStream = _buildStream(widget.videoId);
      });
    }
  }

  Stream<List<DoubtModel>> _buildStream(String videoId) {
    return FirebaseFirestore.instance
        .collection('doubts')
        .where('videoId', isEqualTo: videoId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => DoubtModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DoubtModel>>(
      stream: _doubtStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
                  SizedBox(height: 12),
                  Text("சந்தேகங்களைச் சரிபார்க்கிறது...",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        final doubts = snapshot.data ?? [];

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
                  return _DoubtThreadWidget(doubt: doubt, onSeek: widget.onSeek);
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
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
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
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              style: const TextStyle(
                  fontSize: 15, color: Colors.black87, height: 1.5)),
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
                      Icon(Icons.verified, size: 14, color: Colors.green),
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
                          fontSize: 14,
                          height: 1.4)),
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

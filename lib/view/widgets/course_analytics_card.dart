import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/course_progress_model.dart';

class CourseAnalyticsCard extends StatefulWidget {
  final String courseId;

  const CourseAnalyticsCard({super.key, required this.courseId});

  @override
  State<CourseAnalyticsCard> createState() => _CourseAnalyticsCardState();
}

class _CourseAnalyticsCardState extends State<CourseAnalyticsCard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('course_progress')
          .where('course_id', isEqualTo: widget.courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                "மாணவர்கள் இன்னும் பாடத்தை தொடங்கவில்லை", // No students started yet
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final allProgress = snapshot.data!.docs
            .map((e) => CourseProgressModel.fromFirestore(e))
            .toList();

        final totalStudents = allProgress.length;
        int completedCount = 0;
        double sumProgress = 0;

        int range0_25 = 0;
        int range25_50 = 0;
        int range50_75 = 0;
        int range75_100 = 0;

        // Drop-off tracking: count how many users stopped at each video
        Map<String, int> droppedAtVideo = {};
        
        for (var p in allProgress) {
          if (p.progressPercentage >= 100) completedCount++;
          sumProgress += p.progressPercentage;

          if (p.progressPercentage < 25) {
            range0_25++;
          } else if (p.progressPercentage < 50) {
            range25_50++;
          } else if (p.progressPercentage < 75) {
            range50_75++;
          } else {
            range75_100++;
          }

          if (p.progressPercentage < 100 && p.lastVideoId != null) {
            droppedAtVideo[p.lastVideoId!] = (droppedAtVideo[p.lastVideoId!] ?? 0) + 1;
          }
        }

        final avgProgress = sumProgress / totalStudents;
        final completionRate = (completedCount / totalStudents) * 100;

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PROGRESS ANALYTICS",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.orange)),
                      
              const SizedBox(height: 20),
               
              Row(
                children: [
                   Expanded(
                     child: _StatBox(
                       title: "Avg Progress",
                       value: "${avgProgress.toStringAsFixed(1)}%",
                       color: Colors.blue,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _StatBox(
                       title: "Completion Rate",
                       value: "${completionRate.toStringAsFixed(1)}%",
                       color: Colors.green,
                     ),
                   ),
                ]
              ),
              const SizedBox(height: 12),
              _StatBox(
                 title: "Total Students Started",
                 value: "$totalStudents",
                 color: Colors.purple,
                 isFullWidth: true,
              ),

              const SizedBox(height: 24),
              const Text("STUDENT DISTRIBUTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              
              // Distribution Bars
              _DistributionBar(label: "0-25% (Low Engagement)", count: range0_25, total: totalStudents, color: Colors.red),
              _DistributionBar(label: "25-50% (Early Learners)", count: range25_50, total: totalStudents, color: Colors.orange),
              _DistributionBar(label: "50-75% (Active Learners)", count: range50_75, total: totalStudents, color: Colors.blue),
              _DistributionBar(label: "75-100% (Near Completion)", count: range75_100, total: totalStudents, color: Colors.green),

              const SizedBox(height: 24),
              const Text("DROP-OFF POINTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              if (droppedAtVideo.isEmpty) 
                const Text("No significant drop-offs detected.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
              else ...[
                const Text("Videos where students mostly stopped watching:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                ...(() {
                  final list = droppedAtVideo.entries.toList();
                  list.sort((a,b) => b.value.compareTo(a.value));
                  return list.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Video ID: ${e.key}", style: const TextStyle(fontWeight: FontWeight.bold))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text("${e.value} students", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                      ],
                    ),
                  )).toList();
                }()),
              ]

            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isFullWidth;

  const _StatBox({required this.title, required this.value, required this.color, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    double pct = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$count students", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

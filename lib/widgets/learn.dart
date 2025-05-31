import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  void _launchYouTubeVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Soft yellow background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D), // Orange
        title: const Text(
          "🎉 Let's Learn!",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Pick a fun level below! 🧸📚",
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFFB8C00),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildCard(
                    context, "Level 1 🐣", "https://youtu.be/aRcXutXvfmM"),
                _buildCard(
                    context, "Level 2 🐥", "https://youtu.be/aRcXutXvfmM"),
                _buildCard(context, "Level 3 🐤", "https://www.youtube.com/"),
                _buildCard(context, "Level 4 🦉", "https://www.youtube.com/"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String videoUrl) {
    return GestureDetector(
      onTap: () => _launchYouTubeVideo(videoUrl),
      child: Card(
        color: const Color(0xFFFFF3E0), // Light orange
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFBF360C), // Darker orange
              ),
            ),
          ),
        ),
      ),
    );
  }
}

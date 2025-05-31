import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceQuestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Quest for Kids',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LevelMapScreen(),
    );
  }
}

class Level {
  final int id;
  final String title;
  final String videoUrl;
  final String quizQuestion;

  Level(
      {required this.id,
      required this.title,
      required this.videoUrl,
      required this.quizQuestion});
}

class LevelMapScreen extends StatefulWidget {
  @override
  _LevelMapScreenState createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final List<Level> levels = [
    Level(
        id: 1,
        title: 'What is Money?',
        videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
        quizQuestion: 'What do we use money for?'),
    Level(
        id: 2,
        title: 'Saving vs Spending',
        videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
        quizQuestion: 'Why is saving important?'),
    Level(
        id: 3,
        title: 'Banks and Piggy Banks',
        videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
        quizQuestion: 'What is a piggy bank?'),
  ];

  Set<int> unlockedLevels = {1};
  Map<int, int> starRatings = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked =
        prefs.getStringList('unlockedLevels')?.map(int.parse).toSet() ?? {1};
    final stars = <int, int>{};
    for (var level in levels) {
      stars[level.id] = prefs.getInt('stars_${level.id}') ?? 0;
    }
    setState(() {
      unlockedLevels = unlocked;
      starRatings = stars;
    });
  }

  Future<void> _completeLevel(int levelId, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    starRatings[levelId] = stars;
    await prefs.setInt('stars_$levelId', stars);
    if (!unlockedLevels.contains(levelId + 1)) {
      unlockedLevels.add(levelId + 1);
      await prefs.setStringList(
          'unlockedLevels', unlockedLevels.map((e) => e.toString()).toList());
    }
    setState(() {});
  }

  void _openLevel(Level level) {
    if (unlockedLevels.contains(level.id)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LevelScreen(
            level: level,
            onComplete: (stars) => _completeLevel(level.id, stars),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finance Quest for Kids')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: levels.map((level) {
          final isUnlocked = unlockedLevels.contains(level.id);
          final stars = starRatings[level.id] ?? 0;
          return GestureDetector(
            onTap: () => _openLevel(level),
            child: Container(
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Level ${level.id}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(level.title, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('★' * stars + '☆' * (3 - stars),
                      style: TextStyle(color: Colors.amber)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LevelScreen extends StatefulWidget {
  final Level level;
  final Function(int) onComplete;

  LevelScreen({required this.level, required this.onComplete});

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.level.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.level.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            const SizedBox(height: 16),
            Text('Quiz: ${widget.level.quizQuestion}',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [1, 2, 3]
                  .map((star) => ElevatedButton(
                        onPressed: () {
                          widget.onComplete(star);
                          Navigator.pop(context);
                        },
                        child: Text('$star ★'),
                      ))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

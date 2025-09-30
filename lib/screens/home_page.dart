import 'package:flutter/material.dart';
import '../widgets/mood_button.dart';
import '../widgets/activity_button.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import 'timeline_page.dart';
import 'weekly_review_page.dart';
import 'daily_hub_page.dart';
import 'habit_tracker_page.dart';
import 'ai_insights_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isNavigating = false;

  Future<void> _safePush(Widget page) async {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }
  String? selectedMood;
  List<String> selectedActivities = [];
  List<String> selectedTriggers = [];
  int intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  bool isSaving = false;
  bool isSaved = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }



  void _selectMood(String mood) {
    setState(() {
      selectedMood = mood;
    });
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (selectedActivities.contains(activity)) {
        selectedActivities.remove(activity);
      } else {
        selectedActivities.add(activity);
      }
    });
  }

  void _toggleTrigger(String trigger) {
    setState(() {
      if (selectedTriggers.contains(trigger)) {
        selectedTriggers.remove(trigger);
      } else {
        selectedTriggers.add(trigger);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null) {
      _showSnackBar('Please select a mood first!');
      return;
    }

    setState(() {
      isSaving = true;
      isSaved = false;
    });

    try {
      final entry = MoodEntry(
        mood: selectedMood!,
        intensity: intensity,
        activities: selectedActivities,
        triggers: selectedTriggers,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      await StorageService.saveMoodEntry(entry);
      
      setState(() {
        isSaving = false;
        isSaved = true;
      });

      _showSnackBar('Entry saved successfully! 🌱');
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showSnackBar('Error saving entry. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final triggerOptions = const ['Work', 'Family', 'Health', 'Sleep', 'Money', 'Weather', 'Social', 'Diet'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Bloom'),
        actions: [
          IconButton(
            tooltip: 'Weekly Review',
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyReviewPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Open Timeline',
            icon: const Icon(Icons.history),
            onPressed: () async {
              // Import locally to avoid circular imports at top-level if any
              // ignore: avoid_dynamic_calls
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimelinePage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Open Daily Hub',
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyHubPage()),
              );
            },
          ),
            IconButton(
              tooltip: 'Habit Tracker',
              icon: const Icon(Icons.psychology),
              onPressed: _isNavigating ? null : () => _safePush(const HabitTrackerPage()),
            ),
            IconButton(
              tooltip: 'AI Insights',
              icon: const Icon(Icons.auto_awesome),
              onPressed: _isNavigating ? null : () => _safePush(const AIInsightsPage()),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MoodButton(
                  emoji: '😊',
                  mood: 'Happy',
                  isSelected: selectedMood == 'Happy',
                  onTap: () => _selectMood('Happy'),
                ),
                MoodButton(
                  emoji: '😔',
                  mood: 'Sad',
                  isSelected: selectedMood == 'Sad',
                  onTap: () => _selectMood('Sad'),
                ),
                MoodButton(
                  emoji: '😡',
                  mood: 'Angry',
                  isSelected: selectedMood == 'Angry',
                  onTap: () => _selectMood('Angry'),
                ),
                MoodButton(
                  emoji: '😌',
                  mood: 'Calm',
                  isSelected: selectedMood == 'Calm',
                  onTap: () => _selectMood('Calm'),
                ),
                MoodButton(
                  emoji: '😴',
                  mood: 'Tired',
                  isSelected: selectedMood == 'Tired',
                  onTap: () => _selectMood('Tired'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Intensity slider
            if (selectedMood != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Intensity'),
                  Text('$intensity/10'),
                ],
              ),
              Slider(
                value: intensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$intensity',
                onChanged: (v) => setState(() => intensity = v.round()),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'What did you do today?',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActivityButton(
                  activity: 'Work',
                  isSelected: selectedActivities.contains('Work'),
                  onTap: () => _toggleActivity('Work'),
                ),
                ActivityButton(
                  activity: 'Study',
                  isSelected: selectedActivities.contains('Study'),
                  onTap: () => _toggleActivity('Study'),
                ),
                ActivityButton(
                  activity: 'Exercise',
                  isSelected: selectedActivities.contains('Exercise'),
                  onTap: () => _toggleActivity('Exercise'),
                ),
                ActivityButton(
                  activity: 'Social',
                  isSelected: selectedActivities.contains('Social'),
                  onTap: () => _toggleActivity('Social'),
                ),
                ActivityButton(
                  activity: 'Rest',
                  isSelected: selectedActivities.contains('Rest'),
                  onTap: () => _toggleActivity('Rest'),
                ),
                ActivityButton(
                  activity: 'Creative',
                  isSelected: selectedActivities.contains('Creative'),
                  onTap: () => _toggleActivity('Creative'),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // Triggers
            Align(
              alignment: Alignment.centerLeft,
              child: Text('What influenced your mood?', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: triggerOptions.map((t) {
                final selected = selectedTriggers.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => _toggleTrigger(t),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            // Note
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Why do you feel this way? (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            if (selectedMood != null || selectedActivities.isNotEmpty)
              Column(
                children: [
                  if (selectedMood != null)
                    Text(
                      'Mood: $selectedMood (Intensity: $intensity/10)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  if (selectedActivities.isNotEmpty)
                    Text(
                      'Activities: ${selectedActivities.join(', ')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  if (selectedTriggers.isNotEmpty)
                    Text(
                      'Triggers: ${selectedTriggers.join(', ')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            if (selectedMood != null)
              ElevatedButton(
                onPressed: isSaving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isSaved ? 'Saved! 🌱' : 'Save Entry',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/mood_button.dart';
import '../widgets/activity_button.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import 'timeline_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedMood;
  List<String> selectedActivities = [];
  bool isSaving = false;
  bool isSaved = false;

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
        activities: selectedActivities,
        date: DateTime.now(),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Bloom'),
        actions: [
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
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(height: 40),
            const Text(
              'What did you do today?',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
            if (selectedMood != null || selectedActivities.isNotEmpty)
              Column(
                children: [
                  if (selectedMood != null)
                    Text(
                      'Mood: $selectedMood',
                      style: const TextStyle(fontSize: 18),
                    ),
                  if (selectedActivities.isNotEmpty)
                    Text(
                      'Activities: ${selectedActivities.join(', ')}',
                      style: const TextStyle(fontSize: 18),
                    ),
                ],
              ),
            const SizedBox(height: 30),
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

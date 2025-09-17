import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/mood_entry.dart';

class TimelinePage extends StatefulWidget {
    const TimelinePage({super.key});

    @override
    State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
    Future<List<MoodEntry>> _loadEntries() async {
        final entries = await StorageService.getMoodEntries();
        entries.sort((a, b) => b.date.compareTo(a.date));
        return entries;
    }

    String _formatDate(DateTime date) {
        final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final wd = weekdayNames[date.weekday - 1];
        final m = monthNames[date.month - 1];
        final d = date.day.toString().padLeft(2, '0');
        final y = date.year;
        return '$wd, $m $d, $y';
    }

    // Function to get mood emoji
    String _getMoodEmoji(String mood) {
        switch (mood) {
            case 'Happy':
                return '😊';
            case 'Sad':
                return '😔';
            case 'Angry':
                return '😡';
            case 'Calm':
                return '😌';
            case 'Tired':
                return '😴';
            default:
                return '😊'; // Default emoji for unknown moods
        }
    }

    // Function to show entry details dialog
    void _showEntryDetails(MoodEntry entry) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text('Entry Details'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Date: ${_formatDate(entry.date)}'),
                        SizedBox(height: 8),
                        Text('Mood: ${_getMoodEmoji(entry.mood)} ${entry.mood}'),
                        SizedBox(height: 8),
                        Text('Activities: ${entry.activities.join(', ')}'),
                    ],
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                    ),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Timeline'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                            setState(() {
                                // This will trigger a rebuild and reload data
                            });
                        },
                    ),
                ],
            ),
            body: FutureBuilder<List<MoodEntry>>(
                future: _loadEntries(),
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                        return Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                    Icon(Icons.error_outline, color: Colors.red, size: 32),
                                    SizedBox(height: 8),
                                    Text("Couldn't load entries. Please try again."),
                                ],
                            ),
                        );
                    }
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                        return const Center(
                            child: Text('No entries yet. Save one from Home!'),
                        );
                    }
                    return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                            final entry = entries[index];
                            final dateText = _formatDate(entry.date);
                            final activitiesText = entry.activities.isEmpty
                                ? 'No activities recorded'
                                : entry.activities.join(', ');
                            return GestureDetector(
                                onTap: () => _showEntryDetails(entry),
                                child: ListTile(
                                    leading: Text(_getMoodEmoji(entry.mood), style: const TextStyle(fontSize: 24)),
                                    title: Text(dateText),
                                    subtitle: Text(activitiesText),
                                    trailing: Text(entry.mood),
                                ),
                            );
                        },
                    );
                },
            ),
        );
    }
}
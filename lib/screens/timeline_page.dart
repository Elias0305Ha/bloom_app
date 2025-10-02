import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/mood_entry.dart';

class TimelinePage extends StatefulWidget {
    const TimelinePage({super.key});

    @override
    State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
    late Future<List<MoodEntry>> _future;
    final Set<String> _activeMoodFilters = {};
    bool _compactView = true;

    @override
    void initState() {
        super.initState();
        _future = _loadEntries();
    }

    Future<List<MoodEntry>> _loadEntries() async {
        final entries = await StorageService.getMoodEntries();
        entries.sort((a, b) => b.date.compareTo(a.date));
        return entries;
    }

    Future<void> _refresh() async {
        setState(() {
            _future = _loadEntries();
        });
        await _future;
    }

    List<MoodEntry> _applyFilters(List<MoodEntry> entries) {
        if (_activeMoodFilters.isEmpty) return entries;
        return entries.where((e) => _activeMoodFilters.contains(e.mood)).toList();
    }

    Map<DateTime, List<MoodEntry>> _groupByDay(List<MoodEntry> entries) {
        final map = <DateTime, List<MoodEntry>>{};
        for (final e in entries) {
            final key = DateTime(e.date.year, e.date.month, e.date.day);
            (map[key] ??= []).add(e);
        }
        final sortedKeys = map.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return {for (final k in sortedKeys) k: map[k]!};
    }

    Widget _buildDateHeader(DateTime day, int count) {
        return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
                children: [
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.25)),
                        ),
                        child: Text('${_formatDate(day)}  ·  $count entries', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
            ),
        );
    }

    Widget _buildTimelineTile({
        required MoodEntry entry,
        required bool isFirst,
        required bool isLast,
    }) {
        final activitiesText = entry.activities.isEmpty ? 'No activities' : entry.activities.join(', ');
        final triggersText = entry.triggers.isEmpty ? null : entry.triggers.join(', ');
        final notePreview = (entry.note ?? '').isEmpty ? null : entry.note;

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    // Timeline rail
                    SizedBox(
                        width: 28,
                        child: Column(
                            children: [
                                Expanded(
                                    child: Container(
                                        width: 2,
                                        color: isFirst ? Colors.transparent : Colors.grey.shade300,
                                    ),
                                ),
                                Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
                                        ],
                                    ),
                                ),
                                Expanded(
                                    child: Container(
                                        width: 2,
                                        color: isLast ? Colors.transparent : Colors.grey.shade300,
                                    ),
                                ),
                            ],
                        ),
                    ),
                    // Card
                    Expanded(
                        child: GestureDetector(
                            onTap: () => _showEntryDetails(entry),
                            child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(_getMoodEmoji(entry.mood), style: const TextStyle(fontSize: 28)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Row(
                                                            children: [
                                                                Expanded(
                                                                    child: Text(entry.mood, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                                ),
                                                                Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                    decoration: BoxDecoration(
                                                                        color: Colors.blue.withOpacity(0.08),
                                                                        borderRadius: BorderRadius.circular(10),
                                                                    ),
                                                                    child: Text('${entry.intensity}/10', style: const TextStyle(fontSize: 12)),
                                                                ),
                                                            ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(_formatDate(entry.date), style: TextStyle(color: Colors.grey.shade700)),
                                                        const SizedBox(height: 6),
                                                        if (_compactView) ...[
                                                            Text(activitiesText, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                        ] else ...[
                                                            Text('Activities: $activitiesText'),
                                                            if (triggersText != null) ...[
                                                                const SizedBox(height: 2),
                                                                Text('Triggers: $triggersText', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                                            ],
                                                            if (notePreview != null) ...[
                                                                const SizedBox(height: 2),
                                                                Text('Note: $notePreview', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                                            ],
                                                        ],
                                                    ],
                                                ),
                                            ),
                                            const SizedBox(width: 8),
                                            PopupMenuButton<String>(
                                                itemBuilder: (_) => [
                                                    const PopupMenuItem(value: 'details', child: Text('View details')),
                                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                                ],
                                                onSelected: (value) async {
                                                    if (value == 'details') {
                                                        _showEntryDetails(entry);
                                                    } else if (value == 'delete') {
                                                        if (await _confirmDelete()) {
                                                            await StorageService.deleteMoodEntry(entry);
                                                            if (!mounted) return;
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry deleted')));
                                                            _refresh();
                                                        }
                                                    }
                                                },
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ),
                ],
              ),
            ),
        );
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
                        Text('Mood: ${_getMoodEmoji(entry.mood)} ${entry.mood} (${entry.intensity}/10)'),
                        SizedBox(height: 8),
                        Text('Activities: ${entry.activities.join(', ')}'),
                        if (entry.triggers.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text('Triggers: ${entry.triggers.join(', ')}'),
                        ],
                        if ((entry.note ?? '').isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text('Note: ${entry.note}'),
                        ],
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

    Future<bool> _confirmDelete() async {
        final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                title: Text('Delete Entry'),
                content: Text('Are you sure you want to delete this entry?'),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
                ],
            ),
        );
        return ok == true;
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Timeline'),
                actions: [
                    IconButton(
                        tooltip: _compactView ? 'Expanded view' : 'Compact view',
                        icon: Icon(_compactView ? Icons.view_agenda : Icons.view_compact),
                        onPressed: () => setState(() => _compactView = !_compactView),
                    ),
                    IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refresh,
                    ),
                ],
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<MoodEntry>>(
                future: _future,
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
                    final entries = _applyFilters(snapshot.data ?? []);
                    if (entries.isEmpty) {
                        return const Center(
                            child: Text('No entries yet. Save one from Home!'),
                        );
                    }
                    // Filters + grouped timeline
                    final grouped = _groupByDay(entries);
                    final moodChips = ['Happy','Sad','Angry','Calm','Tired'];
                    return ListView(
                        children: [
                            // Filters row
                            Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                                child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                        ...moodChips.map((m) {
                                            final selected = _activeMoodFilters.contains(m);
                                            return FilterChip(
                                                label: Text('${_getMoodEmoji(m)}  $m'),
                                                selected: selected,
                                                onSelected: (v) => setState(() {
                                                    if (selected) {
                                                        _activeMoodFilters.remove(m);
                                                    } else {
                                                        _activeMoodFilters.add(m);
                                                    }
                                                }),
                                            );
                                        }),
                                        if (_activeMoodFilters.isNotEmpty)
                                            TextButton.icon(
                                                onPressed: () => setState(() => _activeMoodFilters.clear()),
                                                icon: const Icon(Icons.clear),
                                                label: const Text('Clear'),
                                            ),
                                    ],
                                ),
                            ),
                            const Divider(height: 1),
                            // Groups
                            for (final day in grouped.keys) ...[
                                _buildDateHeader(day, grouped[day]!.length),
                                for (int i = 0; i < grouped[day]!.length; i++)
                                    _buildTimelineTile(
                                        entry: grouped[day]![i],
                                        isFirst: i == 0,
                                        isLast: i == grouped[day]!.length - 1,
                                    ),
                            ],
                            const SizedBox(height: 24),
                        ],
                    );
                },
              ),
            ),
        );
    }
}
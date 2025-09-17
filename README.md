# 🌱 Bloom - Emotional & Activity Growth Tracker

A Flutter app that helps you track your daily emotions and activities to understand patterns and grow into your best self.

## Features

- **Daily Mood Logging**: Select from 5 mood options (Happy, Sad, Angry, Calm, Tired)
- **Activity Tracking**: Log 2-5 key activities per day
- **Timeline View**: See all your entries in chronological order
- **Cloud Storage**: Data stored in MongoDB Atlas for persistence
- **Interactive UI**: Tap entries for details, swipe to delete

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Database**: MongoDB Atlas
- **State Management**: Flutter StatefulWidget

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Android Studio / VS Code
- MongoDB Atlas account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/bloom_app.git
cd bloom_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up MongoDB Atlas:
   - Create a MongoDB Atlas account
   - Create a new database called `bloom_app`
   - Create a collection called `mood_entries`
   - Get your connection string

4. Update the connection string in `lib/services/mongodb_service.dart`

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── mood_entry.dart      # Data model for mood entries
├── screens/
│   ├── home_page.dart       # Main mood logging screen
│   └── timeline_page.dart   # Timeline view of all entries
├── services/
│   ├── storage_service.dart # Storage abstraction layer
│   └── mongodb_service.dart # MongoDB Atlas integration
└── widgets/
    └── mood_button.dart     # Reusable mood selection button
```

## Usage

1. **Log Your Mood**: Select how you're feeling today
2. **Add Activities**: Choose what you did today
3. **Save Entry**: Tap save to store your data
4. **View Timeline**: See all your past entries
5. **Manage Entries**: Tap for details, swipe to delete

## Future Features

- Weekly review charts
- Mood insights and patterns
- Voice logging
- AI-powered suggestions
- Wearable integration

## Contributing

This is a personal project, but feel free to fork and modify for your own use!

## License

MIT License - feel free to use this code for your own projects.
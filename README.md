# 🏎️ MakeWay Car Tracker

A Flutter desktop application for tracking your MakeWay car collection and game sessions. Keep track of which cars you've driven, set favorites with keyboard shortcuts, and analyze your gameplay statistics.

![MakeWay Car Tracker](https://img.shields.io/badge/Flutter-Desktop-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### 🚗 Car Collection Management
- Track all 28 MakeWay cars in your collection
- Mark cars as driven/not driven with a single click
- Add custom notes to each car
- Search and filter your collection
- Sort alphabetically or by status

### ⭐ Favorites & Keyboard Shortcuts
- Mark up to 10 cars as favorites
- Assign keyboard shortcuts (1-9, 0) to your favorite cars
- Quickly increment "times driven" counter with a single keypress
- Reorder favorites with drag-and-drop interface

### 🎮 Game Session Tracking
- Start and track live game sessions
- Automatically save session history
- View detailed session statistics
- Track total rounds and cars driven per session
- Delete individual or all saved sessions

### 📊 Statistics & Analytics
- Visual charts showing most driven cars (pie chart)
- Driving history bar chart
- Session statistics (total sessions, rounds played)
- Overview cards with key metrics
- Track your progress over time

### ⚙️ Settings & Customization
- **Appearance**: Toggle between light and dark mode
- **Favorites**: Manage favorite cars and keyboard shortcuts
- **Files**: Choose custom storage location for all data
- **About**: View app information and statistics

## 🖼️ Screenshots

*Collection View - Track all your cars*
```
[Banner with MakeWay logo]
Cars Driven: 15 / 28
[Progress bar]

[List of cars with checkboxes, star icons, and edit buttons]
```

*Session Mode - Live tracking during gameplay*
```
[Active session with timer]
Round: 5 | Cars Driven: 12

[Real-time car counter with animations]
Press 1-9 or 0 to increment favorite cars
```

*Statistics - Analyze your gameplay*
```
[Pie chart of most driven cars]
[Bar chart of driving history]
[Session statistics cards]
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Desktop development enabled for Flutter

### Installation

1. **Clone the repository**
```bash
   git clone https://github.com/yourusername/makeway-car-tracker.git
   cd makeway-car-tracker
```

2. **Install dependencies**
```bash
   flutter pub get
```

3. **Run the application**
```bash
   flutter run -d windows  # For Windows
   flutter run -d macos    # For macOS
   flutter run -d linux    # For Linux
```

### Building for Production

**Windows:**
```bash
flutter build windows --release
```

**macOS:**
```bash
flutter build macos --release
```

**Linux:**
```bash
flutter build linux --release
```

## 📁 Data Storage

All data is stored locally in the `MakeWayTracker` folder:
```
Documents/MakeWayTracker/
├── settings.json              # App settings (theme, preferences)
├── cars.json                  # Car collection data
└── gameplay_sessions/         # Saved game sessions
    ├── session_abc123.json
    └── session_def456.json
```

You can change the base storage location in Settings > Files.

## 🎯 Usage

### Basic Workflow

1. **Track Your Cars**
   - Click checkboxes to mark cars as driven
   - Use the star icon to add cars to favorites
   - Click edit icon to add notes or modify car details

2. **Set Up Keyboard Shortcuts**
   - Go to Settings > Favorites
   - Your first 10 favorites automatically get shortcuts (1-9, 0)
   - Reorder favorites using arrow buttons

3. **Start a Session**
   - Navigate to Session tab
   - Click "Start Session" to begin tracking
   - Press keyboard shortcuts (1-9, 0) to track cars during gameplay
   - Timer shows elapsed time
   - Session automatically saves when stopped

4. **View Statistics**
   - Go to Statistics tab
   - See pie chart of most driven cars
   - View bar chart of driving history
   - Check session statistics

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1-9` | Increment times driven for favorites 1-9 |
| `0` | Increment times driven for favorite 10 |

*Note: Keyboard shortcuts only work for your first 10 favorite cars*

## 🛠️ Technical Details

### Built With
- **Flutter** - UI framework
- **Dart** - Programming language
- **fl_chart** - Charts and graphs
- **shared_preferences** - Local settings storage
- **file_picker** - File system access
- **path_provider** - Platform-specific paths

### Architecture
- **Service-based architecture** for clean separation of concerns
- **Singleton pattern** for services (CarService, SettingsService, SessionService)
- **JSON-based** persistent storage
- **Material Design 3** UI components

### Key Components
```
lib/
├── main.dart                 # App entry point
├── car_tracker_page.dart    # Main collection view
├── session_page.dart        # Live session tracking
├── statistics_page.dart     # Statistics and charts
├── settings_page.dart       # App settings
├── models.dart              # Data models
├── car_service.dart         # Car data management
├── session_service.dart     # Session data management
└── settings_service.dart    # App settings management
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request  

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- MakeWay game for the inspiration and amazing game


## 📮 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/makeway-car-tracker](https://github.com/yourusername/makeway-car-tracker)

---

Made with ❤️ by [Your Name]
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'settings_service.dart';
import 'session_service.dart';
import 'session_page.dart';
import 'statistics_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final String? currentFilePath;
  final Function(String?) onFilePathChanged;
  final List<Car> cars;
  final List<String> favoriteOrder;
  final Function(List<String>) onFavoriteOrderChanged;
  final Function(String) onRemoveFavorite;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.currentFilePath,
    required this.onFilePathChanged,
    required this.cars,
    required this.favoriteOrder,
    required this.onFavoriteOrderChanged,
    required this.onRemoveFavorite,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final SettingsService _settingsService = SettingsService();
  final SessionService _sessionService = SessionService();
  late TabController _tabController;
  late List<String> _localFavoriteOrder;
  String? displayPath;
  int totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    displayPath = widget.currentFilePath;
    _localFavoriteOrder = List<String>.from(widget.favoriteOrder);
    _loadSessionCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favoriteOrder != oldWidget.favoriteOrder) {
      setState(() {
        _localFavoriteOrder = List<String>.from(widget.favoriteOrder);
      });
    }
  }

  Future<void> _loadSessionCount() async {
    final sessions = await _sessionService.loadAllSessions();
    setState(() {
      totalSessions = sessions.length;
    });
  }

  Future<void> _pickBaseFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose base folder for MakeWay Tracker',
      );

      if (selectedDirectory != null) {
        final newBasePath = '$selectedDirectory/MakeWayTracker';
        await _settingsService.setCustomBasePath(newBasePath);
        await widget.onFilePathChanged(newBasePath);
        
        setState(() {
          displayPath = newBasePath;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Base folder updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking folder: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    await _settingsService.setCustomBasePath(null);
    await widget.onFilePathChanged(null);
    
    setState(() {
      displayPath = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to default location')),
      );
    }
  }

  Future<void> _deleteAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Sessions?'),
        content: const Text('This will permanently delete all saved game sessions. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sessionService.deleteAllSessions();
      await _loadSessionCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All sessions deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Banner header with navigation tabs
          Stack(
            children: [
              Container(
                height: 280,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/banner.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: Theme.of(context).brightness == Brightness.dark
                                  ? [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)]
                                  : [const Color(0xFF4A9FD8), const Color(0xFFFFA842)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/mw-logo4app.png',
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.settings, size: 40, color: Colors.white),
                                const SizedBox(height: 8),
                                const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customize your experience',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation tabs overlay
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavTab(context, 'Collection', Icons.collections, false,
                              () => Navigator.popUntil(context, (route) => route.isFirst)),
                          const SizedBox(width: 8),
                          _buildNavTab(context, 'Session', Icons.sports_esports, false, () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionPage(
                                  onThemeChanged: widget.onThemeChanged,
                                  cars: widget.cars,
                                  favoriteOrder: widget.favoriteOrder,
                                  customFilePath: widget.currentFilePath,
                                  onFilePathChanged: widget.onFilePathChanged,
                                  onFavoriteOrderChanged: widget.onFavoriteOrderChanged,
                                  onRemoveFavorite: widget.onRemoveFavorite,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          _buildNavTab(context, 'Statistics', Icons.bar_chart, false, () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatisticsPage(
                                  cars: widget.cars,
                                  onThemeChanged: widget.onThemeChanged,
                                  currentFilePath: widget.currentFilePath,
                                  onFilePathChanged: widget.onFilePathChanged,
                                  favoriteOrder: widget.favoriteOrder,
                                  onFavoriteOrderChanged: widget.onFavoriteOrderChanged,
                                  onRemoveFavorite: widget.onRemoveFavorite,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          _buildNavTab(context, 'Settings', Icons.settings, true, () {}),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Category tabs under banner
          Container(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFFFA842),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              tabs: const [
                Tab(icon: Icon(Icons.palette, size: 20), text: 'Appearance'),
                Tab(icon: Icon(Icons.star, size: 20), text: 'Favorites'),
                Tab(icon: Icon(Icons.folder, size: 20), text: 'Files'),
                Tab(icon: Icon(Icons.info_outline, size: 20), text: 'About'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppearanceTab(theme),
                _buildFavoritesTab(theme),
                _buildFilesTab(theme),
                _buildAboutTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: _settingsService.isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _settingsService.isDarkMode = value;
                    });
                    _settingsService.saveSettings();
                    widget.onThemeChanged(value);
                  },
                  secondary: Icon(
                    _settingsService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use arrow buttons to reorder favorites and set keyboard shortcuts (1-9, 0)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                if (_localFavoriteOrder.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No favorites yet. Mark cars as favorites using the star icon.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localFavoriteOrder.length > 10 ? 10 : _localFavoriteOrder.length,
                    itemBuilder: (context, index) {
                      final carName = _localFavoriteOrder[index];
                      final car = widget.cars.firstWhere(
                        (c) => c.name == carName,
                        orElse: () => Car(name: carName),
                      );
                      final keyLabel = index == 9 ? '0' : '${index + 1}';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                keyLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            carName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Times driven: ${car.timesDriven}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                iconSize: 20,
                                color: index == 0 
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                    : theme.colorScheme.primary,
                                onPressed: index == 0 ? null : () {
                                  setState(() {
                                    final item = _localFavoriteOrder.removeAt(index);
                                    _localFavoriteOrder.insert(index - 1, item);
                                  });
                                  widget.onFavoriteOrderChanged(_localFavoriteOrder);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                iconSize: 20,
                                color: index == _localFavoriteOrder.length - 1 
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                                    : theme.colorScheme.primary,
                                onPressed: index == _localFavoriteOrder.length - 1 ? null : () {
                                  setState(() {
                                    final item = _localFavoriteOrder.removeAt(index);
                                    _localFavoriteOrder.insert(index + 1, item);
                                  });
                                  widget.onFavoriteOrderChanged(_localFavoriteOrder);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    _localFavoriteOrder.remove(carName);
                                  });
                                  widget.onRemoveFavorite(carName);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                if (_localFavoriteOrder.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Only the first 10 favorites can have keyboard shortcuts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Current base folder:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _settingsService.basePath,
                  builder: (context, snapshot) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: SelectableText(
                        snapshot.data ?? 'Loading...',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickBaseFolder,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Change Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.brightness == Brightness.dark
                              ? const Color(0xFF5A8FAF)
                              : const Color(0xFF4A9FD8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (displayPath != null) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _resetToDefault,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.brightness == Brightness.dark
                              ? const Color(0xFFCC6B5A)
                              : const Color(0xFFFF6B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'All app data (cars, settings, and sessions) will be stored in the MakeWayTracker folder at this location.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.sports_esports,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Total Sessions'),
                  subtitle: Text('$totalSessions saved sessions'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: totalSessions > 0 ? _deleteAllSessions : null,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Sessions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/mw-logo4app.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'MakeWay Car Tracker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your MakeWay car collection and game sessions. Keep track of which cars you\'ve driven, set favorites with keyboard shortcuts, and analyze your gameplay statistics.\n\nDeveloped with <3 by GLLB Apps.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.collections, color: theme.colorScheme.primary),
                  title: Text('${widget.cars.length} cars in collection'),
                ),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text('${widget.favoriteOrder.length} favorite cars'),
                ),
                ListTile(
                  leading: Icon(Icons.sports_esports, color: theme.colorScheme.primary),
                  title: Text('$totalSessions game sessions'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavTab(BuildContext context, String label, IconData icon, bool isActive, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF5A8FAF)
                    : const Color(0xFF4A9FD8))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
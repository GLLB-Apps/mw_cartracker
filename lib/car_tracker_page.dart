import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'app_update_service.dart';
import 'background_hotkey_service.dart';
import 'car_service.dart';
import 'settings_service.dart';
import 'session_page.dart';
import 'statistics_page.dart';
import 'settings_page.dart';

class CarTrackerPage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const CarTrackerPage({super.key, required this.onThemeChanged});

  @override
  State<CarTrackerPage> createState() => _CarTrackerPageState();
}

class _CarTrackerPageState extends State<CarTrackerPage> with SingleTickerProviderStateMixin {
  final CarService _carService = CarService();
  final SettingsService _settingsService = SettingsService();
  final AppUpdateService _updateService = AppUpdateService();
  final BackgroundHotkeyService _backgroundHotkeyService = BackgroundHotkeyService();
  late TabController _tabController;
  bool isLoading = true;
  String _sortBy = 'name';
  String _filterBy = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<List<Car>> _undoStack = [];
  final List<List<Car>> _redoStack = [];
  final int _maxHistorySize = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateService.addListener(_onUpdateStateChanged);
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _updateService.removeListener(_onUpdateStateChanged);
    _backgroundHotkeyService.unregisterAll();
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onUpdateStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _settingsService.loadSettings();
      await _carService.loadCars();
      await _registerBackgroundHotkeys();
      await _updateService.checkForUpdates();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _saveState() {
    final currentState = _carService.cars.map((car) => Car(
      name: car.name,
      isDriven: car.isDriven,
      notes: car.notes,
      isFavorite: car.isFavorite,
      timesDriven: car.timesDriven,
      timesDrivenOffline: car.timesDrivenOffline,
      timesDrivenOnline: car.timesDrivenOnline,
    )).toList();

    _undoStack.add(currentState);

    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    final currentState = _carService.cars.map((car) => Car(
      name: car.name,
      isDriven: car.isDriven,
      notes: car.notes,
      isFavorite: car.isFavorite,
      timesDriven: car.timesDriven,
      timesDrivenOffline: car.timesDrivenOffline,
      timesDrivenOnline: car.timesDrivenOnline,
    )).toList();
    _redoStack.add(currentState);

    final previousState = _undoStack.removeLast();
    setState(() {
      _carService.cars = previousState.map((car) => Car(
        name: car.name,
        isDriven: car.isDriven,
        notes: car.notes,
        isFavorite: car.isFavorite,
        timesDriven: car.timesDriven,
        timesDrivenOffline: car.timesDrivenOffline,
        timesDrivenOnline: car.timesDrivenOnline,
      )).toList();
    });

    _carService.saveCars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Undone'), duration: Duration(seconds: 1)),
    );
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    final currentState = _carService.cars.map((car) => Car(
      name: car.name,
      isDriven: car.isDriven,
      notes: car.notes,
      isFavorite: car.isFavorite,
      timesDriven: car.timesDriven,
      timesDrivenOffline: car.timesDrivenOffline,
      timesDrivenOnline: car.timesDrivenOnline,
    )).toList();
    _undoStack.add(currentState);

    final nextState = _redoStack.removeLast();
    setState(() {
      _carService.cars = nextState.map((car) => Car(
        name: car.name,
        isDriven: car.isDriven,
        notes: car.notes,
        isFavorite: car.isFavorite,
        timesDriven: car.timesDriven,
        timesDrivenOffline: car.timesDrivenOffline,
        timesDrivenOnline: car.timesDrivenOnline,
      )).toList();
    });

    _carService.saveCars();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redone'), duration: Duration(seconds: 1)),
    );
  }

  List<Car> get filteredAndSortedCars {
    List<Car> filtered = _carService.cars;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((car) =>
        car.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (_filterBy == 'driven') {
      filtered = filtered.where((car) => car.isDriven).toList();
    } else if (_filterBy == 'notDriven') {
      filtered = filtered.where((car) => !car.isDriven).toList();
    }

    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'status') {
      filtered.sort((a, b) {
        if (a.isDriven == b.isDriven) return a.name.compareTo(b.name);
        return a.isDriven ? 1 : -1;
      });
    }

    return filtered;
  }

  void _markAllDriven() {
    _saveState();
    setState(() {
      _carService.markAllDriven();
    });
    _carService.saveCars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All cars marked as driven!')),
    );
  }

  void _markAllNotDriven() {
    _saveState();
    setState(() {
      _carService.markAllNotDriven();
    });
    _carService.saveCars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All cars marked as not driven!')),
    );
  }

  void toggleCarStatus(int index) {
    _saveState();
    setState(() {
      _carService.toggleCarStatus(index);
    });
    _carService.saveCars();
  }

  void toggleFavorite(int index) {
    _saveState();
    setState(() {
      _carService.toggleFavorite(index);
    });
    _carService.saveCars();
  }

  Future<void> _registerBackgroundHotkeys() async {
    await _backgroundHotkeyService.register(
      onFavoriteSlot: (slotIndex) async {
        if (slotIndex >= 0 && slotIndex < _carService.favoriteOrder.length) {
          incrementTimesDriven(
            _carService.favoriteOrder[slotIndex],
            isOnline: true,
            showSnackBar: false,
          );
        }
      },
    );
  }

  void incrementTimesDriven(
    String carName, {
    bool isOnline = false,
    bool showSnackBar = true,
  }) {
    final carIndex = _carService.cars.indexWhere((car) => car.name == carName);
    if (carIndex != -1) {
      _saveState();
      setState(() {
        _carService.incrementTimesDriven(carName, isOnline: isOnline);
      });
      _carService.saveCars();

      if (showSnackBar) {
        final modeLabel = isOnline ? 'Online' : 'Offline';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_carService.cars[carIndex].name}: ${_carService.cars[carIndex].timesDriven} times driven ($modeLabel +1)'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void decrementTimesDriven(
    String carName, {
    bool isOnline = false,
    bool showSnackBar = true,
  }) {
    final carIndex = _carService.cars.indexWhere((car) => car.name == carName);
    if (carIndex == -1 || _carService.cars[carIndex].timesDriven <= 0) return;

    _saveState();
    setState(() {
      _carService.decrementTimesDriven(carName, isOnline: isOnline);
    });
    _carService.saveCars();

    if (showSnackBar) {
      final modeLabel = isOnline ? 'Online' : 'Offline';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_carService.cars[carIndex].name}: ${_carService.cars[carIndex].timesDriven} times driven ($modeLabel -1)'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void showAddCarDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Add New Car',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Car Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _carService.addCar(Car(
                    name: nameController.text,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  ));
                });
                _carService.saveCars();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF5A8FAF)
                  : const Color(0xFF4A9FD8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showEditCarDialog(int index) {
    final nameController = TextEditingController(text: _carService.cars[index].name);
    final notesController = TextEditingController(text: _carService.cars[index].notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Car',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Car Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _carService.removeCar(index);
              });
              _carService.saveCars();
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _carService.cars[index].name = nameController.text;
                  _carService.cars[index].notes = notesController.text.isEmpty
                      ? null
                      : notesController.text;
                });
                _carService.saveCars();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF5A8FAF)
                  : const Color(0xFF4A9FD8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivenCount = _carService.cars.where((car) => car.isDriven).length;
    final totalCount = _carService.cars.length;

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          final label = event.logicalKey.keyLabel.toUpperCase();
          if (label == 'F1') {
            _tabController.animateTo(0);
            return;
          }
          if (label == 'F2') {
            _tabController.animateTo(1);
            return;
          }
          if (label == 'F3') {
            _tabController.animateTo(2);
            return;
          }
          if (label == 'F4') {
            _tabController.animateTo(3);
            return;
          }
        }

        if (event is RawKeyDownEvent && _tabController.index == 0) {
          final label = event.logicalKey.keyLabel;
          if (label.length == 1) {
            int? keyNum;

            if (label == '0') {
              keyNum = 9;
            } else if (int.tryParse(label) != null) {
              keyNum = int.parse(label) - 1;
            }

            if (keyNum != null && keyNum >= 0 && keyNum < _carService.favoriteOrder.length) {
              incrementTimesDriven(_carService.favoriteOrder[keyNum]);
            }
          }
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_tabController.index == 0) {
              _focusNode.requestFocus();
            }
          },
          child: Column(
            children: [
              // Banner
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/banner.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: Theme.of(context).brightness == Brightness.dark
                                    ? [
                                        const Color(0xFF3A3A3A),
                                        const Color(0xFF2A2A2A),
                                      ]
                                    : [
                                        const Color(0xFF4A9FD8),
                                        const Color(0xFFFFA842),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          );
                        },
                      ),
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
                      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
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
                                const Icon(
                                  Icons.directions_car,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cars Driven',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$drivenCount / $totalCount',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: showAddCarDialog,
                                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                      label: const Text(
                                        'Add Car',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFFCC6B5A)
                                            : const Color(0xFFFF6B4A),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: LinearProgressIndicator(
                                    value: totalCount > 0 ? drivenCount / totalCount : 0,
                                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFFCC6B5A)
                                          : const Color(0xFFFF6B4A),
                                    ),
                                    minHeight: 15,
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
              // TabBar
              Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFFFA842),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  tabs: [
                    const Tab(icon: Icon(Icons.collections, size: 20), text: 'Collection'),
                    const Tab(icon: Icon(Icons.sports_esports, size: 20), text: 'Session'),
                    const Tab(icon: Icon(Icons.bar_chart, size: 20), text: 'Statistics'),
                    Tab(
                      icon: _buildUpdateBadgeIcon(
                        icon: Icons.settings,
                        showBadge: _updateService.hasUpdate,
                      ),
                      text: 'Settings',
                    ),
                  ],
                ),
              ),
              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCollectionContent(),
                    SessionPage(),
                    StatisticsPage(cars: _carService.cars),
                    SettingsPage(
                      onThemeChanged: widget.onThemeChanged,
                      currentFilePath: _settingsService.customBasePath,
                      onFilePathChanged: (path) async {
                        await _settingsService.setCustomBasePath(path);
                        await _carService.loadCars();
                        setState(() {});
                      },
                      cars: _carService.cars,
                      favoriteOrder: _carService.favoriteOrder,
                      onFavoriteOrderChanged: (newOrder) {
                        setState(() {
                          _carService.favoriteOrder = newOrder;
                        });
                        _carService.saveCars();
                      },
                      onRemoveFavorite: (carName) {
                        final carIndex = _carService.cars.indexWhere((car) => car.name == carName);
                        if (carIndex != -1) {
                          setState(() {
                            _carService.cars[carIndex].isFavorite = false;
                            _carService.favoriteOrder.remove(carName);
                          });
                          _carService.saveCars();
                        }
                      },
                      onRefreshRequested: _loadData,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBadgeIcon({
    required IconData icon,
    required bool showBadge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 20),
        if (showBadge)
          const Positioned(
            right: -2,
            top: -2,
            child: SizedBox(
              width: 10,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : const Color(0xFFFFA842),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'Bulk actions',
                    onSelected: (value) {
                      if (value == 'markAllDriven') {
                        _markAllDriven();
                      } else if (value == 'markAllNotDriven') {
                        _markAllNotDriven();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'markAllDriven',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Text('Mark All Driven'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'markAllNotDriven',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.orange),
                            SizedBox(width: 12),
                            Text('Mark All Not Driven'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: _undoStack.isEmpty
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white,
                    ),
                    tooltip: 'Undo',
                    onPressed: _undoStack.isEmpty ? null : _undo,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo,
                      color: _redoStack.isEmpty
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.white,
                    ),
                    tooltip: 'Redo',
                    onPressed: _redoStack.isEmpty ? null : _redo,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? (_searchQuery.isNotEmpty ? const Color(0xFF8FBADB) : Colors.white)
                          : (_searchQuery.isNotEmpty ? const Color(0xFF4A9FD8) : Colors.white),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: Text(
                            'Search Cars',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF8FBADB)
                                  : const Color(0xFF4A9FD8),
                            ),
                          ),
                          content: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Type car name...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          actions: [
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text('Clear'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? (_filterBy != 'all' ? const Color(0xFF8FBADB) : Colors.white)
                          : (_filterBy != 'all' ? const Color(0xFF4A9FD8) : Colors.white),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: Text(
                            'Filter Cars',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF8FBADB)
                                  : const Color(0xFF4A9FD8),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<String>(
                                title: const Text('All Cars'),
                                value: 'all',
                                groupValue: _filterBy,
                                onChanged: (value) {
                                  setState(() {
                                    _filterBy = value!;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Driven'),
                                value: 'driven',
                                groupValue: _filterBy,
                                onChanged: (value) {
                                  setState(() {
                                    _filterBy = value!;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('Not Driven'),
                                value: 'notDriven',
                                groupValue: _filterBy,
                                onChanged: (value) {
                                  setState(() {
                                    _filterBy = value!;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: Text(
                            'Sort Cars',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF8FBADB)
                                  : const Color(0xFF4A9FD8),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<String>(
                                title: const Text('Alphabetical (A-Z)'),
                                value: 'name',
                                groupValue: _sortBy,
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('By Status'),
                                subtitle: const Text('Not driven first'),
                                value: 'status',
                                groupValue: _sortBy,
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Car list
        Expanded(
          child: filteredAndSortedCars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No cars found'
                            : _filterBy == 'all'
                                ? 'No cars yet!'
                                : _filterBy == 'driven'
                                    ? 'No driven cars yet!'
                                    : 'All cars driven!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Text('Clear search'),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAndSortedCars.length,
                  itemBuilder: (context, index) {
                    final car = filteredAndSortedCars[index];
                    final originalIndex = _carService.cars.indexOf(car);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF5A8FAF)
                                : const Color(0xFF4A9FD8),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Checkbox(
                            value: car.isDriven,
                            onChanged: (value) =>
                                toggleCarStatus(originalIndex),
                            activeColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF5A8FAF)
                                : const Color(0xFF4A9FD8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          title: Text(
                            car.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF8FBADB)
                                  : const Color(0xFF4A9FD8),
                              decoration: car.isDriven
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: car.notes != null
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4),
                                  child: Text(
                                    car.notes!,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : Colors.black.withValues(alpha: 0.6),
                                    ),
                                  ),
                                )
                              : null,
                          trailing: SizedBox(
                            width: 168,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF8FBADB)
                                      : const Color(0xFF4A9FD8),
                                  onPressed: () => incrementTimesDriven(car.name),
                                  tooltip: 'Mark driven once (+1)',
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFFCC6B5A)
                                      : const Color(0xFFFF6B4A),
                                  onPressed: car.timesDriven > 0
                                      ? () => decrementTimesDriven(car.name)
                                      : null,
                                  tooltip: 'Remove driven once (-1)',
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: Icon(
                                    car.isFavorite ? Icons.star : Icons.star_border,
                                  ),
                                  color: car.isFavorite
                                      ? Colors.amber
                                      : (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : Colors.black.withValues(alpha: 0.5)),
                                  onPressed: () => toggleFavorite(originalIndex),
                                  tooltip: 'Toggle favorite',
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFFCC6B5A)
                                      : const Color(0xFFFF6B4A),
                                  onPressed: () => showEditCarDialog(originalIndex),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => toggleCarStatus(originalIndex),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

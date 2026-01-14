import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models.dart';
import 'session_page.dart';
import 'settings_page.dart';

class StatisticsPage extends StatefulWidget {
  final List<Car> cars;
  final Function(bool) onThemeChanged;
  final String? currentFilePath;
  final Function(String?) onFilePathChanged;
  final List<String> favoriteOrder;
  final Function(List<String>) onFavoriteOrderChanged;
  final Function(String) onRemoveFavorite;

  const StatisticsPage({
    super.key,
    required this.cars,
    required this.onThemeChanged,
    required this.currentFilePath,
    required this.onFilePathChanged,
    required this.favoriteOrder,
    required this.onFavoriteOrderChanged,
    required this.onRemoveFavorite,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int touchedIndex = -1;
  List<GameSession> sessionHistory = [];
  bool isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<String> get _sessionPath async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _sessionFile async {
    final path = await _sessionPath;
    return File('$path/makeway_sessions.json');
  }

  Future<void> _loadSessionData() async {
    try {
      final file = await _sessionFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final dynamic jsonData = json.decode(contents);
        
        setState(() {
          sessionHistory = (jsonData['history'] as List?)
              ?.map((s) => GameSession.fromJson(s))
              .toList() ?? [];
          isLoadingSessions = false;
        });
      } else {
        setState(() {
          isLoadingSessions = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingSessions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get cars with times driven > 0
    final drivencars = widget.cars.where((car) => car.timesDriven > 0).toList();
    drivencars.sort((a, b) => b.timesDriven.compareTo(a.timesDriven));
    
    // Calculate stats
    final totalDriven = widget.cars.where((car) => car.isDriven).length;
    final totalTimesDriven = widget.cars.fold<int>(0, (sum, car) => sum + car.timesDriven);
    final totalFavorites = widget.cars.where((car) => car.isFavorite).length;
    
    // Session stats
    final totalSessions = sessionHistory.length;
    final totalRounds = sessionHistory.fold<int>(0, (sum, session) => sum + session.totalRounds);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Container(),
              flexibleSpace: Stack(
                children: [
                  FlexibleSpaceBar(
                    background: Stack(
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
                                        ? [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)]
                                        : [const Color(0xFF4A9FD8), const Color(0xFFFFA842)],
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
                                    const Icon(Icons.bar_chart, size: 40, color: Colors.white),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Statistics',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Track your driving history',
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
                    collapseMode: CollapseMode.parallax,
                  ),
                  // Tabs overlay
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
                              _buildTab(context, 'Collection', Icons.collections, false,
                                  () => Navigator.popUntil(context, (route) => route.isFirst)),
                              const SizedBox(width: 8),
                              _buildTab(context, 'Session', Icons.sports_esports, false, () {
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
                              _buildTab(context, 'Statistics', Icons.bar_chart, true, () {}),
                              const SizedBox(width: 8),
                              _buildTab(context, 'Settings', Icons.settings, false, () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SettingsPage(
                                      onThemeChanged: widget.onThemeChanged,
                                      currentFilePath: widget.currentFilePath,
                                      onFilePathChanged: widget.onFilePathChanged,
                                      cars: widget.cars,
                                      favoriteOrder: widget.favoriteOrder,
                                      onFavoriteOrderChanged: widget.onFavoriteOrderChanged,
                                      onRemoveFavorite: widget.onRemoveFavorite,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview stats cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, size: 40, color: Colors.green),
                          const SizedBox(height: 8),
                          Text(
                            '$totalDriven',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Text('Cars Driven'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.star, size: 40, color: Colors.amber),
                          const SizedBox(height: 8),
                          Text(
                            '$totalFavorites',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Text('Favorites'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total times driven card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.repeat, size: 40, color: theme.colorScheme.secondary),
                    const SizedBox(height: 8),
                    Text(
                      '$totalTimesDriven',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'Total Times Driven',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Session statistics
            if (!isLoadingSessions && totalSessions > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_esports,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Session Statistics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.sports_score,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalSessions',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sessions Played',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.casino,
                                    size: 32,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalRounds',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Rounds',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (totalSessions > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF5A8FAF).withValues(alpha: 0.2)
                                : const Color(0xFF4A9FD8).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Average ${(totalRounds / totalSessions).toStringAsFixed(1)} rounds per session',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pie chart
            if (drivencars.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Most Driven Cars',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: List.generate(
                              drivencars.length > 10 ? 10 : drivencars.length,
                              (i) {
                                final isTouched = i == touchedIndex;
                                final fontSize = isTouched ? 18.0 : 14.0;
                                final radius = isTouched ? 110.0 : 100.0;
                                final car = drivencars[i];
                                
                                final colors = [
                                  Colors.blue,
                                  Colors.red,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.teal,
                                  Colors.pink,
                                  Colors.amber,
                                  Colors.cyan,
                                  Colors.lime,
                                ];

                                return PieChartSectionData(
                                  color: colors[i % colors.length],
                                  value: car.timesDriven.toDouble(),
                                  title: '${car.timesDriven}',
                                  radius: radius,
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: List.generate(
                          drivencars.length > 10 ? 10 : drivencars.length,
                          (i) {
                            final car = drivencars[i];
                            final colors = [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                              Colors.pink,
                              Colors.amber,
                              Colors.cyan,
                              Colors.lime,
                            ];
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colors[i % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  car.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bar chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driving History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (drivencars.first.timesDriven + 2).toDouble(),
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= drivencars.length) return const Text('');
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        drivencars[value.toInt()].name,
                                        style: const TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            barGroups: List.generate(
                              drivencars.length > 10 ? 10 : drivencars.length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: drivencars[i].timesDriven.toDouble(),
                                    color: theme.colorScheme.primary,
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No driving data yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use keyboard shortcuts (1-9, 0) to track times driven',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, IconData icon, bool isActive, VoidCallback onTap) {
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
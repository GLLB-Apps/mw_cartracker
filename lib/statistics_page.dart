import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models.dart';

class StatisticsPage extends StatefulWidget {
  final List<Car> cars;

  const StatisticsPage({
    super.key,
    required this.cars,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int touchedIndex = -1;
  List<GameSession> sessionHistory = [];
  bool isLoadingSessions = true;
  DriveStatsMode selectedDriveStatsMode = DriveStatsMode.offline;

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

    final driveCountLabel = selectedDriveStatsMode == DriveStatsMode.offline
        ? 'Offline'
        : 'Online';

    int driveCountFor(Car car) {
      return selectedDriveStatsMode == DriveStatsMode.offline
          ? car.timesDrivenOffline
          : car.timesDrivenOnline;
    }

    // Get cars with times driven > 0 in selected mode
    final drivencars = widget.cars.where((car) => driveCountFor(car) > 0).toList();
    drivencars.sort((a, b) => driveCountFor(b).compareTo(driveCountFor(a)));

    // Calculate stats
    final totalDriven = widget.cars.where((car) => car.isDriven).length;
    final totalTimesDriven = widget.cars.fold<int>(0, (sum, car) => sum + car.timesDriven);
    final totalFavorites = widget.cars.where((car) => car.isFavorite).length;

    // Session stats
    final totalSessions = sessionHistory.length;
    final totalRounds = sessionHistory.fold<int>(0, (sum, session) => sum + session.totalRounds);

    return ListView(
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
                              const Icon(
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Most Driven Car Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SegmentedButton<DriveStatsMode>(
                  segments: const [
                    ButtonSegment(
                      value: DriveStatsMode.offline,
                      label: Text('Offline'),
                      icon: Icon(Icons.computer),
                    ),
                    ButtonSegment(
                      value: DriveStatsMode.online,
                      label: Text('Online'),
                      icon: Icon(Icons.public),
                    ),
                  ],
                  selected: {selectedDriveStatsMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      selectedDriveStatsMode = selection.first;
                      touchedIndex = -1;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (drivencars.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Driven Cars ($driveCountLabel)',
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
                              value: driveCountFor(car).toDouble(),
                              title: '${driveCountFor(car)}',
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
                    'Driving History ($driveCountLabel)',
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
                                toY: driveCountFor(drivencars[i]).toDouble(),
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
                      'No $driveCountLabel driving data yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDriveStatsMode == DriveStatsMode.offline
                          ? 'Use in-app shortcuts (1-9, 0) or + buttons to track offline drives'
                          : 'Use background hotkeys (Ctrl+Alt+1..0) to track online drives',
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
    );
  }
}

enum DriveStatsMode {
  offline,
  online,
}

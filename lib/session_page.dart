import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'statistics_page.dart';
import 'settings_page.dart';

class SessionPage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final List<Car> cars;
  final List<String> favoriteOrder;
  final String? customFilePath;
  final Function(String?) onFilePathChanged;
  final Function(List<String>) onFavoriteOrderChanged;
  final Function(String) onRemoveFavorite;

  const SessionPage({
    super.key,
    required this.onThemeChanged,
    required this.cars,
    required this.favoriteOrder,
    required this.customFilePath,
    required this.onFilePathChanged,
    required this.onFavoriteOrderChanged,
    required this.onRemoveFavorite,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  GameSession? activeSession;
  List<GameSession> sessionHistory = [];
  List<SessionTemplate> templates = [];
  bool isLoading = true;
  final FocusNode _sessionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _sessionFocusNode.dispose();
    super.dispose();
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
          if (jsonData['activeSession'] != null) {
            activeSession = GameSession.fromJson(jsonData['activeSession']);
          }
          sessionHistory = (jsonData['history'] as List?)
              ?.map((s) => GameSession.fromJson(s))
              .toList() ?? [];
          templates = (jsonData['templates'] as List?)
              ?.map((t) => SessionTemplate.fromJson(t))
              .toList() ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    }
  }

  Future<void> _saveSessionData() async {
    try {
      final file = await _sessionFile;
      final jsonData = {
        'activeSession': activeSession?.toJson(),
        'history': sessionHistory.map((s) => s.toJson()).toList(),
        'templates': templates.map((t) => t.toJson()).toList(),
      };
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sessions: $e')),
        );
      }
    }
  }

  void _deleteSession(GameSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Session?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
          ),
        ),
        content: Text('Delete this session permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                sessionHistory.remove(session);
              });
              _saveSessionData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearAllSessions() {
    if (sessionHistory.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Clear All Sessions?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
          ),
        ),
        content: Text('Delete all ${sessionHistory.length} sessions permanently? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                sessionHistory.clear();
              });
              _saveSessionData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All sessions cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsModal(GameSession session) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF8FBADB)
                                : const Color(0xFF4A9FD8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(session.startTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Session info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      Icons.timer,
                      'Duration',
                      session.endTime != null
                          ? '${session.endTime!.difference(session.startTime).inMinutes}min'
                          : 'Active',
                    ),
                    _buildStatItem(
                      context,
                      Icons.sports_score,
                      'Rounds',
                      '${session.totalRounds}',
                    ),
                    _buildStatItem(
                      context,
                      Icons.group,
                      'Players',
                      '${session.players.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Chart
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (session.players.map((p) => p.score).fold(0, (a, b) => a > b ? a : b) + 2).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final player = session.players[group.x.toInt()];
                          return BarTooltipItem(
                            '${player.name}\n${player.score} wins',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= session.players.length) return const Text('');
                            final player = session.players[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                player.name,
                                style: const TextStyle(fontSize: 12),
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
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    barGroups: List.generate(
                      session.players.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: session.players[i].score.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Player scores list
              Text(
                'Final Scores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...session.players.map((player) {
                final winner = session.players.reduce((a, b) => a.score > b.score ? a : b);
                final isWinner = player == winner;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWinner
                          ? Colors.amber
                          : Theme.of(context).colorScheme.outline,
                      width: isWinner ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isWinner)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                        ),
                      Expanded(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${player.score} wins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.amber.shade700 : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _startNewSession({SessionTemplate? template}) {
    final playerCount = template?.playerNames.length ?? 2;
    showDialog(
      context: context,
      builder: (context) {
        int numPlayers = playerCount;
        List<TextEditingController> nameControllers = List.generate(
          6,
          (index) => TextEditingController(
            text: template != null && index < template.playerNames.length
                ? template.playerNames[index]
                : 'Player ${index + 1}',
          ),
        );
        bool saveAsTemplate = false;
        TextEditingController templateNameController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Start New Session',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF8FBADB)
                      : const Color(0xFF4A9FD8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Players',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: numPlayers,
                      isExpanded: true,
                      items: List.generate(5, (index) => index + 2)
                          .map((num) => DropdownMenuItem(
                                value: num,
                                child: Text('$num Players'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          numPlayers = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Player Names',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(numPlayers, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: nameControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Player ${index + 1} (Key: ${index + 1})',
                            border: const OutlineInputBorder(),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Save as Template'),
                      value: saveAsTemplate,
                      onChanged: (value) {
                        setDialogState(() {
                          saveAsTemplate = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (saveAsTemplate) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: templateNameController,
                        decoration: const InputDecoration(
                          labelText: 'Template Name',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., "Regular Group", "Family"',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final players = List.generate(
                      numPlayers,
                      (index) => Player(
                        name: nameControllers[index].text.isEmpty
                            ? 'Player ${index + 1}'
                            : nameControllers[index].text,
                      ),
                    );

                    if (saveAsTemplate && templateNameController.text.isNotEmpty) {
                      final newTemplate = SessionTemplate(
                        name: templateNameController.text,
                        playerNames: players.map((p) => p.name).toList(),
                      );
                      setState(() {
                        templates.add(newTemplate);
                      });
                    }

                    setState(() {
                      activeSession = GameSession(
                        id: const Uuid().v4(),
                        players: players,
                        startTime: DateTime.now(),
                      );
                    });
                    _saveSessionData();
                    Navigator.pop(context);

                    // Request focus after dialog closes
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _sessionFocusNode.requestFocus();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF5A8FAF)
                        : const Color(0xFF4A9FD8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Session'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _endSession() {
    if (activeSession == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'End Session?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
          ),
        ),
        content: const Text('Do you want to end the current session and save it to history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                activeSession!.endTime = DateTime.now();
                activeSession!.isActive = false;
                sessionHistory.insert(0, activeSession!);
                activeSession = null;
              });
              _saveSessionData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCC6B5A)
                  : const Color(0xFFFF6B4A),
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Template?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8FBADB)
                : const Color(0xFF4A9FD8),
          ),
        ),
        content: Text('Delete "${templates[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                templates.removeAt(index);
              });
              _saveSessionData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _incrementPlayerScore(int playerIndex) {
    if (activeSession == null || playerIndex >= activeSession!.players.length) return;

    setState(() {
      activeSession!.players[playerIndex].score++;
    });
    _saveSessionData();

    // Show feedback
    final player = activeSession!.players[playerIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${player.name}: ${player.score} wins!'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        width: 200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RawKeyboardListener(
      focusNode: _sessionFocusNode,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent && activeSession != null) {
          // Handle Escape to end session
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _endSession();
            return;
          }
          
          // Handle number keys for scoring
          final label = event.logicalKey.keyLabel;
          if (label.length == 1) {
            final keyNum = int.tryParse(label);
            if (keyNum != null && keyNum >= 1 && keyNum <= activeSession!.players.length) {
              _incrementPlayerScore(keyNum - 1);
            }
          }
        }
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _sessionFocusNode.requestFocus();
          },
          child: NestedScrollView(
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
                                        const Icon(Icons.sports_esports, size: 40, color: Colors.white),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Session',
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          activeSession != null
                                              ? '${activeSession!.totalRounds} rounds played'
                                              : 'No active session',
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
                      // Tabs
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTab(
                                  context,
                                  'Collection',
                                  Icons.collections,
                                  false,
                                  () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                _buildTab(
                                  context,
                                  'Session',
                                  Icons.sports_esports,
                                  true,
                                  () {},
                                ),
                                const SizedBox(width: 8),
                                _buildTab(
                                  context,
                                  'Statistics',
                                  Icons.bar_chart,
                                  false,
                                  () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StatisticsPage(
                                          cars: widget.cars,
                                          onThemeChanged: widget.onThemeChanged,
                                          currentFilePath: widget.customFilePath,
                                          onFilePathChanged: widget.onFilePathChanged,
                                          favoriteOrder: widget.favoriteOrder,
                                          onFavoriteOrderChanged: widget.onFavoriteOrderChanged,
                                          onRemoveFavorite: widget.onRemoveFavorite,
                                        ),
                                      ),
                                    );
                                    _sessionFocusNode.requestFocus();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildTab(
                                  context,
                                  'Settings',
                                  Icons.settings,
                                  false,
                                  () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SettingsPage(
                                          onThemeChanged: widget.onThemeChanged,
                                          currentFilePath: widget.customFilePath,
                                          onFilePathChanged: widget.onFilePathChanged,
                                          cars: widget.cars,
                                          favoriteOrder: widget.favoriteOrder,
                                          onFavoriteOrderChanged: widget.onFavoriteOrderChanged,
                                          onRemoveFavorite: widget.onRemoveFavorite,
                                        ),
                                      ),
                                    );
                                    _sessionFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Active Session Card
                      if (activeSession != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Active Session',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _endSession,
                                      icon: const Icon(Icons.stop, size: 18),
                                      label: const Text('End (ESC)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.brightness == Brightness.dark
                                            ? const Color(0xFFCC6B5A)
                                            : const Color(0xFFFF6B4A),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Press keys 1-${activeSession!.players.length} to score wins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Player scores with bar chart
                                SizedBox(
                                  height: 400,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: (activeSession!.players.map((p) => p.score).fold(0, (a, b) => a > b ? a : b) + 2).toDouble(),
                                      barTouchData: BarTouchData(enabled: true),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 60,
                                            getTitlesWidget: (value, meta) {
                                              if (value.toInt() >= activeSession!.players.length) return const Text('');
                                              final player = activeSession!.players[value.toInt()];
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.primary,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '${value.toInt() + 1}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      player.name,
                                                      style: const TextStyle(fontSize: 10),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ],
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
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      gridData: FlGridData(show: true),
                                      borderData: FlBorderData(show: true),
                                      barGroups: List.generate(
                                        activeSession!.players.length,
                                        (i) => BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: activeSession!.players[i].score.toDouble(),
                                              color: theme.colorScheme.primary,
                                              width: 30,
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
                        const SizedBox(height: 16),
                      ],

                      // Start Session / Templates (only show when no active session)
                      if (activeSession == null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Start New Session',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _startNewSession(),
                                    icon: const Icon(Icons.play_arrow, size: 24),
                                    label: const Text(
                                      'New Session',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.brightness == Brightness.dark
                                          ? const Color(0xFF5A8FAF)
                                          : const Color(0xFF4A9FD8),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                if (templates.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    'Quick Start from Template',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...templates.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final template = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.group,
                                            color: theme.colorScheme.primary,
                                          ),
                                          title: Text(
                                            template.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text('${template.playerNames.length} players: ${template.playerNames.join(", ")}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.play_arrow),
                                                color: Colors.green,
                                                onPressed: () => _startNewSession(template: template),
                                                tooltip: 'Start from template',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () => _deleteTemplate(index),
                                                tooltip: 'Delete template',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Session History (only show when no active session)
                        if (sessionHistory.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Session History',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_sweep),
                                        color: Colors.red,
                                        onPressed: _clearAllSessions,
                                        tooltip: 'Clear all sessions',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...sessionHistory.take(10).map((session) {
                                    final winner = session.players.reduce((a, b) => a.score > b.score ? a : b);
                                    final duration = session.endTime != null
                                        ? session.endTime!.difference(session.startTime)
                                        : Duration.zero;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.emoji_events,
                                            color: Colors.amber,
                                          ),
                                          title: Text(
                                            '${winner.name} won!',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            '${_formatDate(session.startTime)} • ${duration.inMinutes}min • ${session.totalRounds} rounds',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.bar_chart),
                                                color: theme.colorScheme.primary,
                                                onPressed: () => _showSessionDetailsModal(session),
                                                tooltip: 'View details',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                color: Colors.red,
                                                onPressed: () => _deleteSession(session),
                                                tooltip: 'Delete session',
                                              ),
                                            ],
                                          ),
                                          onTap: () => _showSessionDetailsModal(session),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
          ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
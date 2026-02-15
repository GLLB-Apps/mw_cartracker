

// Car Model
class Car {
  String name;
  bool isDriven;
  String? notes;
  bool isFavorite;
  int timesDriven;
  int timesDrivenOffline;
  int timesDrivenOnline;

  Car({
    required this.name,
    this.isDriven = false,
    this.notes,
    this.isFavorite = false,
    this.timesDriven = 0,
    int? timesDrivenOffline,
    this.timesDrivenOnline = 0,
  }) : timesDrivenOffline = timesDrivenOffline ?? timesDriven;

  Map<String, dynamic> toJson() => {
        'name': name,
        'isDriven': isDriven,
        'notes': notes,
        'isFavorite': isFavorite,
        'timesDriven': timesDriven,
        'timesDrivenOffline': timesDrivenOffline,
        'timesDrivenOnline': timesDrivenOnline,
      };

  factory Car.fromJson(Map<String, dynamic> json) {
    final legacyTotal = json['timesDriven'] ?? 0;
    final offline = json['timesDrivenOffline'] ?? legacyTotal;
    final online = json['timesDrivenOnline'] ?? 0;

    return Car(
      name: json['name'],
      isDriven: json['isDriven'] ?? false,
      notes: json['notes'],
      isFavorite: json['isFavorite'] ?? false,
      timesDriven: offline + online,
      timesDrivenOffline: offline,
      timesDrivenOnline: online,
    );
  }
}

// Session Models
class Player {
  String name;
  int score;

  Player({
    required this.name,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'],
        score: json['score'] ?? 0,
      );
}

class GameSession {
  String? id;
  List<Player> players;
  DateTime startTime;
  DateTime? endTime;
  bool isActive;
  Map<String, Map<String, int>>? _playerCarWins;

  Map<String, Map<String, int>> get playerCarWins => _playerCarWins ??= {};
  set playerCarWins(Map<String, Map<String, int>>? value) {
    _playerCarWins = value ?? {};
  }

  GameSession({
    this.id,
    required this.players,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    Map<String, Map<String, int>>? playerCarWins,
  }) : _playerCarWins = playerCarWins ?? {};

  int get totalRounds => players.fold(0, (sum, player) => sum + player.score);

  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isActive': isActive,
        'playerCarWins': playerCarWins.map(
          (playerName, carWins) => MapEntry(playerName, carWins),
        ),
      };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawPlayerCarWins = (json['playerCarWins'] as Map?) ?? {};
    final parsedPlayerCarWins = <String, Map<String, int>>{};

    rawPlayerCarWins.forEach((playerName, carWins) {
      if (playerName is String && carWins is Map) {
        final parsedCarWins = <String, int>{};
        carWins.forEach((carName, winCount) {
          if (carName is String) {
            parsedCarWins[carName] = (winCount as num?)?.toInt() ?? 0;
          }
        });
        parsedPlayerCarWins[playerName] = parsedCarWins;
      }
    });

    return GameSession(
      id: json['id'],
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isActive: json['isActive'] ?? false,
      playerCarWins: parsedPlayerCarWins,
    );
  }
}

class SessionTemplate {
  String name;
  List<String> playerNames;

  SessionTemplate({
    required this.name,
    required this.playerNames,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'playerNames': playerNames,
      };

  factory SessionTemplate.fromJson(Map<String, dynamic> json) => SessionTemplate(
        name: json['name'],
        playerNames: List<String>.from(json['playerNames']),
      );
}

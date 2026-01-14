

// Car Model
class Car {
  String name;
  bool isDriven;
  String? notes;
  bool isFavorite;
  int timesDriven;

  Car({
    required this.name,
    this.isDriven = false,
    this.notes,
    this.isFavorite = false,
    this.timesDriven = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isDriven': isDriven,
        'notes': notes,
        'isFavorite': isFavorite,
        'timesDriven': timesDriven,
      };

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        name: json['name'],
        isDriven: json['isDriven'] ?? false,
        notes: json['notes'],
        isFavorite: json['isFavorite'] ?? false,
        timesDriven: json['timesDriven'] ?? 0,
      );
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

  GameSession({
    this.id,
    required this.players,
    required this.startTime,
    this.endTime,
    this.isActive = true,
  });

  int get totalRounds => players.fold(0, (sum, player) => sum + player.score);

  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isActive': isActive,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'],
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList(),
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        isActive: json['isActive'] ?? false,
      );
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
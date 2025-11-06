import 'dart:convert';

class MatchModel {
  final String id;
  final DateTime createdAt;
  List<String> teamA; // player ids
  List<String> teamB;
  int scoreA;
  int scoreB;
  int durationMinutes; // planned duration
  MatchStatus status;
  DateTime? startTime;
  DateTime? endTime;
  int elapsedSeconds; // running elapsed seconds
  List<MatchEvent> events;

  MatchModel({
    required this.id,
    required this.createdAt,
    required this.teamA,
    required this.teamB,
    this.scoreA = 0,
    this.scoreB = 0,
    this.durationMinutes = 15,
    this.status = MatchStatus.aguardando,
    this.startTime,
    this.endTime,
    this.elapsedSeconds = 0,
    List<MatchEvent>? events,
  }) : events = events ?? [];

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      teamA: (map['teamA'] as List?)?.cast<String>() ?? <String>[],
      teamB: (map['teamB'] as List?)?.cast<String>() ?? <String>[],
      scoreA: map['scoreA'] as int? ?? 0,
      scoreB: map['scoreB'] as int? ?? 0,
      durationMinutes: map['durationMinutes'] as int? ?? 15,
      status: MatchStatus.values.byName(map['status'] as String? ??
          MatchStatus.aguardando.name),
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'])
          : null,
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'])
          : null,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      events: (map['events'] as List?)
              ?.map((e) => MatchEvent.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          <MatchEvent>[],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'teamA': teamA,
        'teamB': teamB,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'durationMinutes': durationMinutes,
        'status': status.name,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'events': events.map((e) => e.toMap()).toList(),
      };

  @override
  String toString() => jsonEncode(toMap());
}

enum MatchStatus { aguardando, emAndamento, finalizada }

class MatchEvent {
  final String id;
  final EventType type;
  final String? primaryPlayerId;
  final String? secondaryPlayerId;
  final String team; // 'A' or 'B'
  final int minute;

  MatchEvent({
    required this.id,
    required this.type,
    required this.team,
    required this.minute,
    this.primaryPlayerId,
    this.secondaryPlayerId,
  });

  factory MatchEvent.fromMap(Map<String, dynamic> map) {
    return MatchEvent(
      id: map['id'] as String,
      type: EventType.values.byName(map['type'] as String),
      team: map['team'] as String? ?? 'A',
      minute: map['minute'] as int? ?? 0,
      primaryPlayerId: map['primaryPlayerId'] as String?,
      secondaryPlayerId: map['secondaryPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'team': team,
        'minute': minute,
        'primaryPlayerId': primaryPlayerId,
        'secondaryPlayerId': secondaryPlayerId,
      };
}

enum EventType { gol, amarelo, vermelho }

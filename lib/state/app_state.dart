import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/v4.dart';

import 'package:futegestor/models/models.dart';
import 'package:futegestor/storage/local_storage.dart';
import 'package:futegestor/services/notification_service.dart';
import 'package:futegestor/services/team_balancer.dart';

class AppState extends ChangeNotifier {
  final _storage = LocalStorage.instance;
  final _notificationService = NotificationService.instance;

  // Data
  final Map<String, Player> _playersById = {};
  final List<String> _arrivalOrder = []; // player ids
  AppSettings settings = AppSettings();

  MatchModel? currentMatch;
  final List<MatchModel> _history = [];

  // Prepared teams (preview before starting match)
  List<String>? preparedTeamA;
  List<String>? preparedTeamB;
  bool get hasTeamsPrepared => preparedTeamA != null && preparedTeamB != null;

  // Timer
  Timer? _timer;
  bool get timerRunning => _timer != null;

  // PUBLIC GETTERS
  List<Player> get players => _playersById.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  List<String> get arrivalOrder => List.unmodifiable(_arrivalOrder);
  List<MatchModel> get history => List.unmodifiable(_history);

  // LOAD/SAVE
  Future<void> load() async {
    // Players
    final List<dynamic>? rawPlayers = _storage.read('players');
    if (rawPlayers != null) {
      for (final e in rawPlayers) {
        try {
          final p = Player.fromMap(Map<String, dynamic>.from(e));
          _playersById[p.id] = p;
        } catch (_) {}
      }
    }
    // Arrival
    final List<dynamic>? rawArrival = _storage.read('arrival');
    if (rawArrival != null) {
      for (final id in rawArrival) {
        if (id is String && _playersById.containsKey(id)) {
          _arrivalOrder.add(id);
        }
      }
    }
    // Settings
    settings = AppSettings.fromMap(_storage.read('settings'));
    // History
    final List<dynamic>? rawHistory = _storage.read('history');
    if (rawHistory != null) {
      for (final e in rawHistory) {
        try {
          _history.add(MatchModel.fromMap(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    // Current match
    final Map<String, dynamic>? rawMatch = _storage.read('currentMatch');
    if (rawMatch != null) {
      currentMatch = MatchModel.fromMap(rawMatch);
    }
    notifyListeners();
  }

  Future<void> _persistAll() async {
    await _storage.write('players', _playersById.values.map((e) => e.toMap()).toList());
    await _storage.write('arrival', _arrivalOrder);
    await _storage.write('settings', settings.toMap());
    await _storage.write('history', _history.map((e) => e.toMap()).toList());
    if (currentMatch == null) {
      await _storage.remove('currentMatch');
    } else {
      await _storage.write('currentMatch', currentMatch!.toMap());
    }
  }

  // PLAYER MANAGEMENT
  String _id() => const UuidV4().generate();

  Player addPlayer(String name, {Position? position, SkillLevel? level}) {
    final p = Player(id: _id(), name: name, position: position, level: level);
    _playersById[p.id] = p;
    _persistAll();
    notifyListeners();
    return p;
  }

  /// Add an existing player to the arrival queue
  void addPlayerToArrival(String playerId) {
    if (!_playersById.containsKey(playerId)) return;
    if (_arrivalOrder.contains(playerId)) return;
    _arrivalOrder.add(playerId);
    _persistAll();
    notifyListeners();
  }

  /// Remove player from arrival queue (not from registry)
  void removePlayerFromArrival(String playerId) {
    _arrivalOrder.removeWhere((id) => id == playerId);
    _persistAll();
    notifyListeners();
  }

  void editPlayer(String id, {String? name, Position? position, SkillLevel? level}) {
    final p = _playersById[id];
    if (p == null) return;
    p.name = name ?? p.name;
    p.position = position;
    p.level = level;
    _persistAll();
    notifyListeners();
  }

  void removePlayer(String id) {
    _playersById.remove(id);
    _arrivalOrder.removeWhere((e) => e == id);
    // Also remove from match
    if (currentMatch != null) {
      currentMatch!.teamA.remove(id);
      currentMatch!.teamB.remove(id);
    }
    _persistAll();
    notifyListeners();
  }

  void reorderArrival(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _arrivalOrder.removeAt(oldIndex);
    _arrivalOrder.insert(newIndex, item);
    _persistAll();
    notifyListeners();
  }

  void replaceArrival(List<String> newOrder) {
    _arrivalOrder
      ..clear()
      ..addAll(newOrder.where((id) => _playersById.containsKey(id)));
    _persistAll();
    notifyListeners();
  }

  // TESTING UTILITIES
  // Quickly create 8 sample players and add them to the arrival list.
  // Useful for manual testing and demos.
  void seedTestPlayers() {
    final samples = <({String name, Position pos, SkillLevel lvl})>[
      (name: 'João', pos: Position.goleiro, lvl: SkillLevel.medio),
      (name: 'Pedro', pos: Position.defesa, lvl: SkillLevel.avancado),
      (name: 'Lucas', pos: Position.defesa, lvl: SkillLevel.medio),
      (name: 'Mateus', pos: Position.meio, lvl: SkillLevel.iniciante),
      (name: 'Rafael', pos: Position.meio, lvl: SkillLevel.avancado),
      (name: 'Gabriel', pos: Position.ataque, lvl: SkillLevel.medio),
      (name: 'Bruno', pos: Position.ataque, lvl: SkillLevel.iniciante),
      (name: 'Thiago', pos: Position.defesa, lvl: SkillLevel.medio),
    ];

    for (final s in samples) {
      final p = Player(
        id: _id(),
        name: s.name,
        position: s.pos,
        level: s.lvl,
      );
      _playersById[p.id] = p;
      _arrivalOrder.add(p.id);
    }
    _persistAll();
    notifyListeners();
  }

  // SETTINGS
  void updateSettings(AppSettings newSettings) {
    settings = newSettings;
    _persistAll();
    notifyListeners();
  }

  bool get hasMinPlayers => _arrivalOrder.length >= settings.minPlayersToStart;

  // MATCH PREPARATION
  /// Prepare teams based on settings (arrival order or balanced)
  void prepareTeams({bool useBalancedTeams = false}) {
    if (!hasMinPlayers) {
      throw StateError('Not enough players to prepare teams');
    }

    final perTeam = settings.playersPerTeam;
    final totalPlayers = perTeam * 2;

    try {
      if (useBalancedTeams && settings.drawModeActive) {
        // Use balanced teams based on skill and position
        final selectedPlayers = _arrivalOrder
            .take(totalPlayers)
            .map((id) => _playersById[id])
            .whereType<Player>()
            .toList();

        if (selectedPlayers.length < totalPlayers) {
          throw StateError('Some players in the queue no longer exist');
        }

        final balanced = settings.drawCriterion == 'posicao'
            ? TeamBalancer.balanceTeamsWithPositions(
                players: selectedPlayers,
                playersPerTeam: perTeam,
              )
            : TeamBalancer.balanceTeams(
                players: selectedPlayers,
                playersPerTeam: perTeam,
              );

        preparedTeamA = balanced.teamA.map((p) => p.id).toList();
        preparedTeamB = balanced.teamB.map((p) => p.id).toList();
      } else {
        // Use arrival order
        preparedTeamA = _arrivalOrder.take(perTeam).toList();
        preparedTeamB = _arrivalOrder.skip(perTeam).take(perTeam).toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error preparing teams: $e');
      }
      rethrow;
    }
  }

  /// Clear prepared teams
  void clearPreparedTeams() {
    preparedTeamA = null;
    preparedTeamB = null;
    notifyListeners();
  }

  // MATCH
  /// Start match with prepared teams
  void startMatch() {
    if (!hasTeamsPrepared) {
      throw StateError('Teams must be prepared before starting a match');
    }
    if (currentMatch != null) {
      throw StateError('A match is already in progress');
    }

    try {
      currentMatch = MatchModel(
        id: _id(),
        createdAt: DateTime.now(),
        teamA: List.from(preparedTeamA!),
        teamB: List.from(preparedTeamB!),
        durationMinutes: settings.matchMinutes,
        status: MatchStatus.emAndamento,
        startTime: DateTime.now(),
      );

      // Clear prepared teams after starting
      preparedTeamA = null;
      preparedTeamB = null;

      _startTimer();
      _persistAll();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error starting match: $e');
      }
      rethrow;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (currentMatch == null) return;
      currentMatch!.elapsedSeconds += 1;
      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resumeTimer() {
    if (currentMatch == null || timerRunning) return;
    _startTimer();
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;
    if (currentMatch != null) currentMatch!.elapsedSeconds = 0;
    notifyListeners();
  }

  void changeScore({required String team, required int delta}) {
    if (currentMatch == null) return;
    if (team == 'A') {
      currentMatch!.scoreA = max(0, currentMatch!.scoreA + delta);
    } else {
      currentMatch!.scoreB = max(0, currentMatch!.scoreB + delta);
    }
    _persistAll();
    notifyListeners();
  }

  void reorderTeam(String team, int oldIndex, int newIndex) {
    if (currentMatch == null) return;
    final list = team == 'A' ? currentMatch!.teamA : currentMatch!.teamB;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _persistAll();
    notifyListeners();
  }

  void moveBetweenTeams({required String from, required int index}) {
    if (currentMatch == null) return;
    final src = from == 'A' ? currentMatch!.teamA : currentMatch!.teamB;
    final dst = from == 'A' ? currentMatch!.teamB : currentMatch!.teamA;
    if (index < 0 || index >= src.length) return;
    final item = src.removeAt(index);
    dst.add(item);
    _persistAll();
    notifyListeners();
  }

  void removeFromTeam(String team, int index) {
    if (currentMatch == null) return;
    final list = team == 'A' ? currentMatch!.teamA : currentMatch!.teamB;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _persistAll();
    notifyListeners();
  }

  void addToTeam(String team, String playerId) {
    if (currentMatch == null) return;
    final list = team == 'A' ? currentMatch!.teamA : currentMatch!.teamB;
    if (!list.contains(playerId)) list.add(playerId);
    _persistAll();
    notifyListeners();
  }

  void addEvent(MatchEvent event) {
    if (currentMatch == null) return;
    currentMatch!.events.insert(0, event);
    // Update counters for goals shortcut
    if (event.type == EventType.gol) {
      changeScore(team: event.team, delta: 1);
    } else {
      _persistAll();
      notifyListeners();
    }
  }

  void finalizeMatch() {
    if (currentMatch == null) return;
    pauseTimer();
    currentMatch!
      ..status = MatchStatus.finalizada
      ..endTime = DateTime.now();

    // Send notification
    _notificationService.showMatchEndNotification(
      durationMinutes: currentMatch!.elapsedSeconds ~/ 60,
      teamAScore: '${currentMatch!.scoreA}',
      teamBScore: '${currentMatch!.scoreB}',
    );

    _history.insert(0, currentMatch!);
    currentMatch = null;
    _persistAll();
    notifyListeners();
  }

  /// Prepare next match with player rotation
  /// Returns the teams for the next match (teamA, teamB, waitingPlayers)
  /// Winning team stays, losing team is replaced by waiting players
  ({List<String> teamA, List<String> teamB, List<String> waiting})? prepareNextMatch() {
    if (!hasMinPlayers) return null;

    final perTeam = settings.playersPerTeam;
    final totalNeeded = perTeam * 2;

    if (_arrivalOrder.length < totalNeeded) return null;

    final lastMatch = _history.isNotEmpty ? _history.first : null;

    if (lastMatch == null) {
      // First match: select from arrival order
      final teamA = _arrivalOrder.take(perTeam).toList();
      final teamB = _arrivalOrder.skip(perTeam).take(perTeam).toList();
      final waiting = _arrivalOrder.skip(totalNeeded).toList();
      return (teamA: teamA, teamB: teamB, waiting: waiting);
    }

    // Determine winner and loser
    final teamAWon = lastMatch.scoreA > lastMatch.scoreB;
    final teamBWon = lastMatch.scoreB > lastMatch.scoreA;
    final wasTie = lastMatch.scoreA == lastMatch.scoreB;

    List<String> winningTeam;
    List<String> losingTeam;
    bool winnerIsTeamA;

    if (wasTie) {
      // In case of tie, treat both teams equally (rotate both)
      final playersWhoPlayed = [...lastMatch.teamA, ...lastMatch.teamB];
      _arrivalOrder.removeWhere((id) => playersWhoPlayed.contains(id));
      _arrivalOrder.addAll(playersWhoPlayed);

      final teamA = _arrivalOrder.take(perTeam).toList();
      final teamB = _arrivalOrder.skip(perTeam).take(perTeam).toList();
      final waiting = _arrivalOrder.skip(totalNeeded).toList();
      return (teamA: teamA, teamB: teamB, waiting: waiting);
    } else if (teamAWon) {
      winningTeam = List.from(lastMatch.teamA);
      losingTeam = List.from(lastMatch.teamB);
      winnerIsTeamA = true;
    } else {
      winningTeam = List.from(lastMatch.teamB);
      losingTeam = List.from(lastMatch.teamA);
      winnerIsTeamA = false;
    }

    // Remove players who played from arrival queue
    final playersWhoPlayed = [...lastMatch.teamA, ...lastMatch.teamB];
    _arrivalOrder.removeWhere((id) => playersWhoPlayed.contains(id));

    // Build new team from waiting players
    List<String> newTeam = [];
    final waitingPlayers = List<String>.from(_arrivalOrder);

    // Take players from waiting list
    for (int i = 0; i < perTeam && waitingPlayers.isNotEmpty; i++) {
      newTeam.add(waitingPlayers.removeAt(0));
    }

    // If not enough waiting players, fill with players from losing team (in order)
    if (newTeam.length < perTeam) {
      final needed = perTeam - newTeam.length;
      for (int i = 0; i < needed && i < losingTeam.length; i++) {
        newTeam.add(losingTeam[i]);
      }
    }

    // Add losing team to end of queue
    _arrivalOrder.addAll(losingTeam);

    // Return teams maintaining winner's position
    if (winnerIsTeamA) {
      return (teamA: winningTeam, teamB: newTeam, waiting: waitingPlayers);
    } else {
      return (teamA: newTeam, teamB: winningTeam, waiting: waitingPlayers);
    }
  }

  /// Start match with specific teams (for rotation)
  void startMatchWithTeams(List<String> teamA, List<String> teamB) {
    currentMatch = MatchModel(
      id: _id(),
      createdAt: DateTime.now(),
      teamA: teamA,
      teamB: teamB,
      durationMinutes: settings.matchMinutes,
      status: MatchStatus.emAndamento,
      startTime: DateTime.now(),
    );
    _startTimer();
    _persistAll();
    notifyListeners();
  }
}

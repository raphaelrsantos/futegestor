import 'package:flutter_test/flutter_test.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/models/match_models.dart';
import 'package:futegestor/models/settings.dart';

void main() {
  group('Player', () {
    test('toMap and fromMap work correctly', () {
      final player = Player(
        id: 'test-id',
        name: 'Test Player',
        position: Position.goleiro,
        level: SkillLevel.avancado,
        active: true,
      );

      final map = player.toMap();
      final restored = Player.fromMap(map);

      expect(restored.id, player.id);
      expect(restored.name, player.name);
      expect(restored.position, player.position);
      expect(restored.level, player.level);
      expect(restored.active, player.active);
    });

    test('handles null position and level', () {
      final player = Player(id: 'test-id', name: 'Test Player');

      final map = player.toMap();
      final restored = Player.fromMap(map);

      expect(restored.position, isNull);
      expect(restored.level, isNull);
      expect(restored.active, isTrue);
    });
  });

  group('MatchModel', () {
    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final match = MatchModel(
        id: 'match-id',
        createdAt: now,
        teamA: ['player1', 'player2'],
        teamB: ['player3', 'player4'],
        scoreA: 2,
        scoreB: 1,
        durationMinutes: 15,
        status: MatchStatus.emAndamento,
        startTime: now,
        elapsedSeconds: 300,
      );

      final map = match.toMap();
      final restored = MatchModel.fromMap(map);

      expect(restored.id, match.id);
      expect(restored.teamA, match.teamA);
      expect(restored.teamB, match.teamB);
      expect(restored.scoreA, match.scoreA);
      expect(restored.scoreB, match.scoreB);
      expect(restored.status, match.status);
      expect(restored.elapsedSeconds, match.elapsedSeconds);
    });

    test('defaults are set correctly', () {
      final match = MatchModel(
        id: 'test-id',
        createdAt: DateTime.now(),
        teamA: [],
        teamB: [],
      );

      expect(match.scoreA, 0);
      expect(match.scoreB, 0);
      expect(match.durationMinutes, 15);
      expect(match.status, MatchStatus.aguardando);
      expect(match.elapsedSeconds, 0);
      expect(match.events, isEmpty);
    });
  });

  group('AppSettings', () {
    test('toMap and fromMap work correctly', () {
      final settings = AppSettings(
        matchMinutes: 20,
        tiebreaker: 'penalties',
        playersPerTeam: 7,
        minPlayersToStart: 14,
        drawModeActive: true,
        drawCriterion: 'nivel',
      );

      final map = settings.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.matchMinutes, settings.matchMinutes);
      expect(restored.tiebreaker, settings.tiebreaker);
      expect(restored.playersPerTeam, settings.playersPerTeam);
      expect(restored.minPlayersToStart, settings.minPlayersToStart);
      expect(restored.drawModeActive, settings.drawModeActive);
      expect(restored.drawCriterion, settings.drawCriterion);
    });

    test('defaults are set correctly', () {
      final settings = AppSettings();

      expect(settings.matchMinutes, 15);
      expect(settings.tiebreaker, 'mais_gols');
      expect(settings.playersPerTeam, 5);
      expect(settings.minPlayersToStart, 10);
      expect(settings.drawModeActive, false);
      expect(settings.drawCriterion, 'posicao');
    });

    test('handles null map correctly', () {
      final settings = AppSettings.fromMap(null);

      expect(settings.matchMinutes, 15);
      expect(settings.playersPerTeam, 5);
    });
  });

  group('MatchEvent', () {
    test('toMap and fromMap work correctly', () {
      final event = MatchEvent(
        id: 'event-id',
        type: EventType.gol,
        team: 'A',
        minute: 10,
        primaryPlayerId: 'player1',
        secondaryPlayerId: 'player2',
      );

      final map = event.toMap();
      final restored = MatchEvent.fromMap(map);

      expect(restored.id, event.id);
      expect(restored.type, event.type);
      expect(restored.team, event.team);
      expect(restored.minute, event.minute);
      expect(restored.primaryPlayerId, event.primaryPlayerId);
      expect(restored.secondaryPlayerId, event.secondaryPlayerId);
    });

    test('handles null player IDs', () {
      final event = MatchEvent(
        id: 'event-id',
        type: EventType.amarelo,
        team: 'B',
        minute: 5,
      );

      final map = event.toMap();
      final restored = MatchEvent.fromMap(map);

      expect(restored.primaryPlayerId, isNull);
      expect(restored.secondaryPlayerId, isNull);
    });
  });
}

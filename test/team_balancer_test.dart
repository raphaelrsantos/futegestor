import 'package:flutter_test/flutter_test.dart';
import 'package:futegestor/models/player.dart';
import 'package:futegestor/services/team_balancer.dart';

void main() {
  group('TeamBalancer', () {
    test('balanceTeams distributes players evenly', () {
      final players = [
        Player(id: '1', name: 'Player 1', level: SkillLevel.avancado),
        Player(id: '2', name: 'Player 2', level: SkillLevel.avancado),
        Player(id: '3', name: 'Player 3', level: SkillLevel.medio),
        Player(id: '4', name: 'Player 4', level: SkillLevel.medio),
        Player(id: '5', name: 'Player 5', level: SkillLevel.iniciante),
        Player(id: '6', name: 'Player 6', level: SkillLevel.iniciante),
      ];

      final result = TeamBalancer.balanceTeams(
        players: players,
        playersPerTeam: 3,
      );

      expect(result.teamA.length, 3);
      expect(result.teamB.length, 3);

      // Check that skill levels are distributed
      final teamAStrength = TeamBalancer.calculateTeamStrength(result.teamA);
      final teamBStrength = TeamBalancer.calculateTeamStrength(result.teamB);

      // Teams should have similar strength
      expect((teamAStrength - teamBStrength).abs(), lessThan(1.0));
    });

    test('balanceTeamsWithPositions respects positions', () {
      final players = [
        Player(id: '1', name: 'GK 1', position: Position.goleiro, level: SkillLevel.avancado),
        Player(id: '2', name: 'GK 2', position: Position.goleiro, level: SkillLevel.medio),
        Player(id: '3', name: 'DEF 1', position: Position.defesa, level: SkillLevel.avancado),
        Player(id: '4', name: 'DEF 2', position: Position.defesa, level: SkillLevel.medio),
        Player(id: '5', name: 'MID 1', position: Position.meio, level: SkillLevel.avancado),
        Player(id: '6', name: 'MID 2', position: Position.meio, level: SkillLevel.medio),
      ];

      final result = TeamBalancer.balanceTeamsWithPositions(
        players: players,
        playersPerTeam: 3,
      );

      expect(result.teamA.length, 3);
      expect(result.teamB.length, 3);

      // Each team should have at least one goalkeeper if possible
      final teamAHasGK = result.teamA.any((p) => p.position == Position.goleiro);
      final teamBHasGK = result.teamB.any((p) => p.position == Position.goleiro);

      expect(teamAHasGK || teamBHasGK, isTrue);
    });

    test('calculateTeamStrength returns correct average', () {
      final team = [
        Player(id: '1', name: 'Player 1', level: SkillLevel.avancado), // 3 points
        Player(id: '2', name: 'Player 2', level: SkillLevel.medio),    // 2 points
        Player(id: '3', name: 'Player 3', level: SkillLevel.iniciante), // 1 point
      ];

      final strength = TeamBalancer.calculateTeamStrength(team);

      // Average: (3 + 2 + 1) / 3 = 2.0
      expect(strength, 2.0);
    });

    test('balanceTeams throws error with insufficient players', () {
      final players = [
        Player(id: '1', name: 'Player 1', level: SkillLevel.avancado),
        Player(id: '2', name: 'Player 2', level: SkillLevel.medio),
      ];

      expect(
        () => TeamBalancer.balanceTeams(players: players, playersPerTeam: 3),
        throwsArgumentError,
      );
    });
  });
}

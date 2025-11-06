import 'dart:math';
import 'package:futegestor/models/player.dart';

/// Service to balance teams based on player positions and skill levels
class TeamBalancer {
  /// Balance teams based on player skill levels and positions
  /// Returns (teamA, teamB) with balanced teams
  /// Throws [ArgumentError] if there are not enough players
  static ({List<Player> teamA, List<Player> teamB}) balanceTeams({
    required List<Player> players,
    required int playersPerTeam,
  }) {
    if (playersPerTeam <= 0) {
      throw ArgumentError('playersPerTeam must be greater than 0');
    }
    if (players.length < playersPerTeam * 2) {
      throw ArgumentError(
        'Not enough players to form two teams. Need ${playersPerTeam * 2}, got ${players.length}',
      );
    }

    // Assign skill points
    final playersWithScores = players.map((p) {
      int skillPoints = _getSkillPoints(p.level);
      return (player: p, score: skillPoints);
    }).toList();

    // Sort by skill level descending
    playersWithScores.sort((a, b) => b.score.compareTo(a.score));

    // Distribute players alternately (snake draft)
    final teamA = <Player>[];
    final teamB = <Player>[];

    for (int i = 0; i < playersPerTeam * 2; i++) {
      if (i < playersWithScores.length) {
        if (i % 2 == 0) {
          teamA.add(playersWithScores[i].player);
        } else {
          teamB.add(playersWithScores[i].player);
        }
      }
    }

    // Try to balance positions
    teamA.take(playersPerTeam).toList();
    teamB.take(playersPerTeam).toList();

    return (teamA: teamA, teamB: teamB);
  }

  /// Balance teams with position awareness
  static ({List<Player> teamA, List<Player> teamB}) balanceTeamsWithPositions({
    required List<Player> players,
    required int playersPerTeam,
  }) {
    if (players.length < playersPerTeam * 2) {
      throw ArgumentError('Not enough players to form two teams');
    }

    // Group by position
    final goalkeepers = players.where((p) => p.position == Position.goleiro).toList();
    final defenders = players.where((p) => p.position == Position.defesa).toList();
    final midfielders = players.where((p) => p.position == Position.meio).toList();
    final forwards = players.where((p) => p.position == Position.ataque).toList();
    final noPosition = players.where((p) => p.position == null).toList();

    // Sort each group by skill level
    goalkeepers.sort((a, b) => _getSkillPoints(b.level).compareTo(_getSkillPoints(a.level)));
    defenders.sort((a, b) => _getSkillPoints(b.level).compareTo(_getSkillPoints(a.level)));
    midfielders.sort((a, b) => _getSkillPoints(b.level).compareTo(_getSkillPoints(a.level)));
    forwards.sort((a, b) => _getSkillPoints(b.level).compareTo(_getSkillPoints(a.level)));

    final teamA = <Player>[];
    final teamB = <Player>[];

    // Distribute goalkeepers
    _distributePositionGroup(goalkeepers, teamA, teamB, playersPerTeam);

    // Distribute defenders
    _distributePositionGroup(defenders, teamA, teamB, playersPerTeam);

    // Distribute midfielders
    _distributePositionGroup(midfielders, teamA, teamB, playersPerTeam);

    // Distribute forwards
    _distributePositionGroup(forwards, teamA, teamB, playersPerTeam);

    // Fill remaining spots with no-position players
    _distributePositionGroup(noPosition, teamA, teamB, playersPerTeam);

    return (teamA: teamA.take(playersPerTeam).toList(), teamB: teamB.take(playersPerTeam).toList());
  }

  static void _distributePositionGroup(
    List<Player> group,
    List<Player> teamA,
    List<Player> teamB,
    int maxPerTeam,
  ) {
    for (int i = 0; i < group.length; i++) {
      if (teamA.length >= maxPerTeam && teamB.length >= maxPerTeam) break;

      if (teamA.length < maxPerTeam && (i % 2 == 0 || teamB.length >= maxPerTeam)) {
        teamA.add(group[i]);
      } else if (teamB.length < maxPerTeam) {
        teamB.add(group[i]);
      }
    }
  }

  static int _getSkillPoints(SkillLevel? level) {
    return switch (level) {
      SkillLevel.avancado => 3,
      SkillLevel.medio => 2,
      SkillLevel.iniciante => 1,
      null => 1,
    };
  }

  /// Calculate team strength based on average skill level
  static double calculateTeamStrength(List<Player> team) {
    if (team.isEmpty) return 0.0;
    final totalPoints = team.fold<int>(0, (sum, p) => sum + _getSkillPoints(p.level));
    return totalPoints / team.length;
  }
}

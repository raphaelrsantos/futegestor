class AppSettings {
  int matchMinutes;
  String tiebreaker; // ex: 'mais_gols'
  int playersPerTeam;
  bool drawModeActive; // sorteio por posição/nível
  String drawCriterion; // 'posicao' | 'nivel'

  AppSettings({
    this.matchMinutes = 15,
    this.tiebreaker = 'mais_gols',
    this.playersPerTeam = 3,
    this.drawModeActive = false,
    this.drawCriterion = 'posicao',
  });

  // Minimum players to start is always double the players per team
  int get minPlayersToStart => playersPerTeam * 2;

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AppSettings();
    return AppSettings(
      matchMinutes: map['matchMinutes'] as int? ?? 15,
      tiebreaker: map['tiebreaker'] as String? ?? 'mais_gols',
      playersPerTeam: map['playersPerTeam'] as int? ?? 3,
      drawModeActive: map['drawModeActive'] as bool? ?? false,
      drawCriterion: map['drawCriterion'] as String? ?? 'posicao',
    );
  }

  Map<String, dynamic> toMap() => {
        'matchMinutes': matchMinutes,
        'tiebreaker': tiebreaker,
        'playersPerTeam': playersPerTeam,
        'drawModeActive': drawModeActive,
        'drawCriterion': drawCriterion,
      };
}

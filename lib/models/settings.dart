class AppSettings {
  int matchMinutes;
  String tiebreaker; // ex: 'mais_gols'
  int playersPerTeam;
  int minPlayersToStart;
  bool drawModeActive; // sorteio por posição/nível
  String drawCriterion; // 'posicao' | 'nivel'

  AppSettings({
    this.matchMinutes = 15,
    this.tiebreaker = 'mais_gols',
    this.playersPerTeam = 5,
    this.minPlayersToStart = 10,
    this.drawModeActive = false,
    this.drawCriterion = 'posicao',
  });

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AppSettings();
    return AppSettings(
      matchMinutes: map['matchMinutes'] as int? ?? 15,
      tiebreaker: map['tiebreaker'] as String? ?? 'mais_gols',
      playersPerTeam: map['playersPerTeam'] as int? ?? 5,
      minPlayersToStart: map['minPlayersToStart'] as int? ?? 10,
      drawModeActive: map['drawModeActive'] as bool? ?? false,
      drawCriterion: map['drawCriterion'] as String? ?? 'posicao',
    );
  }

  Map<String, dynamic> toMap() => {
        'matchMinutes': matchMinutes,
        'tiebreaker': tiebreaker,
        'playersPerTeam': playersPerTeam,
        'minPlayersToStart': minPlayersToStart,
        'drawModeActive': drawModeActive,
        'drawCriterion': drawCriterion,
      };
}

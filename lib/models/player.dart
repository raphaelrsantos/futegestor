import 'dart:convert';

class Player {
  final String id;
  String name;
  Position? position;
  SkillLevel? level;
  bool active;

  Player({
    required this.id,
    required this.name,
    this.position,
    this.level,
    this.active = true,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      position: map['position'] != null
          ? Position.values.byName(map['position'])
          : null,
      level:
          map['level'] != null ? SkillLevel.values.byName(map['level']) : null,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'position': position?.name,
        'level': level?.name,
        'active': active,
      };

  @override
  String toString() => jsonEncode(toMap());
}

enum Position { goleiro, defesa, meio, ataque }

enum SkillLevel { iniciante, medio, avancado }

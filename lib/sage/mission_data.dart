import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class MissionInfo {
  final String id;
  final int level;
  final List<String> enemies;
  final int xpReward;
  final int goldReward;

  MissionInfo({
    required this.id,
    required this.level,
    required this.enemies,
    required this.xpReward,
    required this.goldReward,
  });
}

class EnemyInfo {
  final String id;
  final int hp;
  final int agility;

  EnemyInfo({
    required this.id,
    required this.hp,
    required this.agility,
  });
}

class MissionData {
  static List<MissionInfo>? _missions;
  static Map<String, EnemyInfo>? _enemies;

  static Future<void> _ensureLoaded() async {
    if (_missions != null && _enemies != null) {
      return;
    }

    final missionJson =
        await rootBundle.loadString('sage_data/mission.json');
    final enemyJson =
        await rootBundle.loadString('sage_data/enemy.json');

    final missionList = (jsonDecode(missionJson) as List)
        .whereType<Map<String, dynamic>>()
        .map((m) {
      final enemies = (m['enemies'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      final id = m['id']?.toString() ?? '';
      final level = (m['level'] as num?)?.toInt() ?? 1;
      final rewards = (m['rewards'] as Map?) ?? {};
      final xpReward = (rewards['xp'] as num?)?.toInt() ?? 0;
      final goldReward = (rewards['gold'] as num?)?.toInt() ?? 0;
      return MissionInfo(
        id: id,
        level: level,
        enemies: enemies,
        xpReward: xpReward,
        goldReward: goldReward,
      );
    }).toList();

    final enemyList = (jsonDecode(enemyJson) as List)
        .whereType<Map<String, dynamic>>()
        .map((e) {
      final id = e['id']?.toString() ?? '';
      final hp = (e['hp'] as num?)?.toInt() ?? 0;
      final agility = (e['agility'] as num?)?.toInt() ?? 0;
      return EnemyInfo(
        id: id,
        hp: hp,
        agility: agility,
      );
    }).toList();

    _missions = missionList;
    _enemies = {
      for (final e in enemyList) e.id: e,
    };
  }

  /// Pilih misi terbaik untuk levelling:
  /// - Pilih misi dengan level tertinggi yang masih <= level karakter.
  /// - Jika tidak ada yang <= level, ambil misi dengan level terendah.
  static Future<MissionInfo?> pickMissionForLevel(int characterLevel) async {
    await _ensureLoaded();
    final missions = _missions;
    if (missions == null || missions.isEmpty) return null;

    missions.sort((a, b) => a.level.compareTo(b.level));

    MissionInfo? candidate;
    for (final m in missions) {
      if (m.level <= characterLevel) {
        candidate = m;
      } else {
        break;
      }
    }

    return candidate ?? missions.first;
  }

  static Future<EnemyInfo?> getEnemy(String id) async {
    await _ensureLoaded();
    return _enemies?[id];
  }
}

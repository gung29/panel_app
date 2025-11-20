import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:panel_app/models/user_data.dart';
import 'package:panel_app/sage/mission_data.dart';
import 'package:panel_app/sage/xp_table.dart';
import 'package:panel_app/services/ninja_sage_workflow.dart';
import 'package:panel_app/widgets/app_background.dart';

class LevellingScreen extends StatefulWidget {
  final UserData userData;
  final ValueChanged<UserData>? onUserDataUpdated;

  const LevellingScreen({
    super.key,
    required this.userData,
    this.onUserDataUpdated,
  });

  @override
  State<LevellingScreen> createState() => _LevellingScreenState();
}

class _LevellingScreenState extends State<LevellingScreen> {
  final Random _random = Random();

  int _minDelay = 5;
  int _maxDelay = 7;
  bool _isLevelling = false;
  int _currentCountdown = 0;
  Timer? _timer;
  bool _isProcessingCycle = false;
  final List<_LogEntry> _logs = [];
  String? _currentMissionId;
  MissionInfo? _currentMission;
  int _currentLevel = 0;
  int _currentXp = 0;
  int _currentGold = 0;
  int _currentTokens = 0;
  int? _currentMaxEnemyHp;

  int _attrWind = 0;
  int _attrFire = 0;
  int _attrLightning = 0;
  int _attrWater = 0;
  int _attrEarth = 0;

  String _weaponId = 'wpn_01';
  String _setId = 'set_01_0';
  String _backItemId = 'back_01';
  String _accessoryId = 'accessory_01';

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _currentLevel = d.selectedCharacterLevel ?? 0;
    _currentXp = d.selectedCharacterXp ?? 0;
    _currentGold = d.gold;
    _currentTokens = d.tokens;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDelayRange(int min, int max) {
    setState(() {
      _minDelay = min;
      _maxDelay = max;
      if (_isLevelling && _currentCountdown == 0) {
        _currentCountdown = _pickNextDelay();
      }
    });
  }

  int _pickNextDelay() {
    final min = _minDelay.clamp(1, 3600);
    final max = _maxDelay.clamp(min, 3600);
    if (min == max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  void _startLevelling() {
    if (_isLevelling) return;
    if (_minDelay <= 0 || _maxDelay <= 0) return;

    setState(() {
      _isLevelling = true;
      _currentCountdown = _pickNextDelay();
    });

    _runAmfLevellingSequence();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLevelling || !mounted) {
        timer.cancel();
        return;
      }
      if (_currentCountdown > 0) {
        setState(() {
          _currentCountdown -= 1;
        });
      } else {
        _onCountdownZero();
      }
    });
  }

  void _stopLevelling() {
    if (!_isLevelling) return;
    setState(() {
      _isLevelling = false;
      _currentCountdown = 0;
    });
    _timer?.cancel();
  }

  void _applyUpdatedUser(UserData updated) {
    setState(() {
      _currentLevel =
          updated.selectedCharacterLevel ?? _currentLevel;
      _currentXp =
          updated.selectedCharacterXp ?? _currentXp;
      _currentGold = updated.gold;
      _currentTokens = updated.tokens;
    });
    if (widget.onUserDataUpdated != null) {
      widget.onUserDataUpdated!(updated);
    }
  }

  void _onCountdownZero() {
    if (_isProcessingCycle || !_isLevelling) return;
    _processCycle();
  }

  Future<void> _processCycle() async {
    if (_isProcessingCycle || !_isLevelling) return;
    _isProcessingCycle = true;
    try {
      await _runFinishMissionCycle();
      if (!_isLevelling || !mounted) return;

      // Jeda acak 1–2 detik sebelum mulai lagi dari awal.
      final pauseSeconds = 1 + _random.nextInt(2);
      await Future.delayed(Duration(seconds: pauseSeconds));
      if (!_isLevelling || !mounted) return;

      await _runAmfLevellingSequence();
      if (!_isLevelling || !mounted) return;

      setState(() {
        _currentCountdown = _pickNextDelay();
      });
    } finally {
      _isProcessingCycle = false;
    }
  }

  void _addLog(String title, Object data) {
    const encoder = JsonEncoder.withIndent('  ');
    String body;
    try {
      body = encoder.convert(data);
    } catch (_) {
      body = data.toString();
    }
    setState(() {
      _logs.insert(
        0,
        _LogEntry(
          timestamp: DateTime.now(),
          title: title,
          body: body,
        ),
      );
      if (_logs.length > 200) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _runAmfLevellingSequence() async {
    final charId = widget.userData.selectedCharacterId;
    final session = NinjaSageWorkflow.currentSessionKey;
    if (charId == null || session == null || session.isEmpty) {
      return;
    }

    try {
      // 1. CharacterService.getMissionRoomData
      final roomBody = [
        [charId, session],
      ];
      _addLog(
        'CharacterService.getMissionRoomData • Request',
        roomBody,
      );
      final roomResp = await NinjaSageWorkflow.invokeAmf(
        'CharacterService.getMissionRoomData',
        body: roomBody,
      );
      _addLog(
        'CharacterService.getMissionRoomData • Response',
        roomResp,
      );

      // 2. Tentukan misi & musuh dari sage_data.
      final level = _currentLevel <= 0 ? 1 : _currentLevel;
      final mission = await MissionData.pickMissionForLevel(level);
      if (mission == null || mission.enemies.isEmpty) return;

      _currentMissionId = mission.id;
      _currentMission = mission;

      final enemyIds = mission.enemies;
      final enemyIdList = enemyIds.join(',');

      final enemyStatsParts = <String>[];
      int? maxHp;
      for (final id in enemyIds) {
        final enemy = await MissionData.getEnemy(id);
        if (enemy == null) continue;
        enemyStatsParts.add(
          'id:${enemy.id}|hp:${enemy.hp}|agility:${enemy.agility}',
        );
        if (maxHp == null || enemy.hp > maxHp!) {
          maxHp = enemy.hp;
        }
      }
      if (enemyStatsParts.isEmpty) return;

      final enemyStatsString = enemyStatsParts.join('#');
      _currentMaxEnemyHp = maxHp;

      // Agility placeholder: gunakan level sebagai seed sederhana.
      final agilityString = (widget.userData.selectedCharacterLevel ?? 1)
          .toString();

      final hashInput =
          '$enemyIdList$enemyStatsString$agilityString';
      final battleHash = _cucsgHash(hashInput);

      // 2. BattleSystem.startMission
      final startBody = [
        [
          charId,
          mission.id,
          enemyIdList,
          enemyStatsString,
          agilityString,
          battleHash,
          session,
        ],
      ];
      _addLog('BattleSystem.startMission • Request', startBody);
      final startMissionResp = await NinjaSageWorkflow.invokeAmf(
        'BattleSystem.startMission',
        body: startBody,
      );
      _addLog('BattleSystem.startMission • Response', startMissionResp);

      // Simpan battle key jika ada (dipakai nanti untuk finish).
      final battleKey = startMissionResp['status']?.toString();
      NinjaSageWorkflow.lastBattleKey = battleKey;

      // 3. CharacterService.getInfo untuk refresh data karakter.
      final infoBody = [
        [charId, session, charId, 'MISSION'],
      ];
      _addLog('CharacterService.getInfo • Request', infoBody);
      final infoResp = await NinjaSageWorkflow.invokeAmf(
        'CharacterService.getInfo',
        body: infoBody,
      );
      _addLog('CharacterService.getInfo • Response', infoResp);

      final charData = infoResp['character_data'];
      if (charData is Map) {
        final levelAny = charData['character_level'];
        final xpAny = charData['character_xp'];
        final goldAny = charData['character_gold'];
        final tokensAny = charData['character_tp'];
        final windAny = charData['atrrib_wind'];
        final fireAny = charData['atrrib_fire'];
        final lightningAny = charData['atrrib_lightning'];
        final waterAny = charData['atrrib_water'];
        final earthAny = charData['atrrib_earth'];

        _attrWind = (windAny as num?)?.toInt() ?? _attrWind;
        _attrFire = (fireAny as num?)?.toInt() ?? _attrFire;
        _attrLightning =
            (lightningAny as num?)?.toInt() ?? _attrLightning;
        _attrWater = (waterAny as num?)?.toInt() ?? _attrWater;
        _attrEarth = (earthAny as num?)?.toInt() ?? _attrEarth;

        final setsAny = charData['character_sets'];
        if (setsAny is Map) {
          final w = setsAny['weapon'];
          final s = setsAny['clothing'] ?? setsAny['set'];
          final b = setsAny['back_item'];
          final a = setsAny['accessory'];
          _weaponId = w?.toString() ?? _weaponId;
          _setId = s?.toString() ?? _setId;
          _backItemId = b?.toString() ?? _backItemId;
          _accessoryId = a?.toString() ?? _accessoryId;
        }

        final serverLevel =
            (levelAny as num?)?.toInt() ?? _currentLevel;
        final serverXp =
            (xpAny as num?)?.toInt() ?? _currentXp;
        final serverGold =
            (goldAny as num?)?.toInt() ?? _currentGold;
        final serverTokens =
            (tokensAny as num?)?.toInt() ?? _currentTokens;

        var newLevel = _currentLevel;
        var newXp = _currentXp;
        var newGold = _currentGold;
        var newTokens = _currentTokens;

        // Jangan mundur secara total XP; kalau server
        // masih kirim nilai sebelum finish, pertahankan
        // state lokal kita.
        final currentCombined = _combinedProgress(
          _currentLevel,
          _currentXp,
        );
        final serverCombined = _combinedProgress(
          serverLevel,
          serverXp,
        );

        if (serverCombined >= currentCombined) {
          newLevel = serverLevel;
          newXp = serverXp;
        }

        // Gold/tokens hanya naik, tidak turun.
        if (serverGold > _currentGold) {
          newGold = serverGold;
        }
        if (serverTokens > _currentTokens) {
          newTokens = serverTokens;
        }

        final updated = widget.userData.copyWith(
          selectedCharacterLevel: newLevel,
          selectedCharacterXp: newXp,
          gold: newGold,
          tokens: newTokens,
        );

        if (mounted) {
          _applyUpdatedUser(updated);
        }
      }
    } catch (_) {
      // Untuk sekarang, diamkan error AMF agar UI tetap jalan.
    }
  }

  Future<void> _runFinishMissionCycle() async {
    final charId = widget.userData.selectedCharacterId;
    final session = NinjaSageWorkflow.currentSessionKey;
    final missionId = _currentMissionId;
    final battleCode = NinjaSageWorkflow.lastBattleKey;

    if (charId == null ||
        session == null ||
        session.isEmpty ||
        missionId == null ||
        battleCode == null ||
        battleCode.isEmpty) {
      return;
    }

    final baseHp = _currentMaxEnemyHp ?? 0;
    final bonus = 100 + _random.nextInt(901); // 100–1000
    final totalDamage = baseHp + bonus;
    final finishHash =
        _cucsgHash('$missionId$charId$battleCode$totalDamage');

    final payloadBase64 = _buildFinishPayloadBase64();

    final finishBody = [
      [
        charId,
        missionId,
        battleCode,
        finishHash,
        totalDamage,
        session,
        payloadBase64,
        0,
      ],
    ];

    _addLog('BattleSystem.finishMission • Request', finishBody);
    final finishResp = await NinjaSageWorkflow.invokeAmf(
      'BattleSystem.finishMission',
      body: finishBody,
    );
    _addLog('BattleSystem.finishMission • Response', finishResp);

    final result = finishResp['result'];
    if (result is! List || result.length < 3) {
      return;
    }

    final goldAny = result[0];
    final inner = result[2];

    int? serverLevel;
    int? serverXp;
    int? serverTokens;

    if (inner is Map) {
      final levelAny = inner['level'];
      final xpAny = inner['xp'];
      final tokensAny = inner['account_tokens'];
      if (levelAny is num) serverLevel = levelAny.toInt();
      if (xpAny is num) serverXp = xpAny.toInt();
      if (tokensAny is num) serverTokens = tokensAny.toInt();
    }

    var newLevel = _currentLevel;
    var newXp = _currentXp;
    var newGold = _currentGold;
    var newTokens = _currentTokens;

    // Tambahkan XP reward per misi setiap loop.
    final rewardXp = _currentMission?.xpReward ?? 0;
    if (rewardXp > 0) {
      newXp += rewardXp;
      // Naik level lokal berdasarkan xp_table.
      while (true) {
        final maxXpForLevel = requiredXpForLevel(newLevel);
        if (maxXpForLevel <= 0) break;
        if (newXp >= maxXpForLevel) {
          newXp -= maxXpForLevel;
          newLevel += 1;
        } else {
          break;
        }
      }
    }

    // Sinkronkan dengan server jika data server lebih maju.
    if (serverLevel != null && serverXp != null) {
      final localCombined = _combinedProgress(newLevel, newXp);
      final serverCombined = _combinedProgress(serverLevel, serverXp);
      if (serverCombined > localCombined) {
        newLevel = serverLevel;
        newXp = serverXp;
      }
    }

    // Tambahkan reward gold.
    if (goldAny is num) {
      newGold = _currentGold + goldAny.toInt();
    }
    if (serverTokens != null) {
      newTokens = serverTokens;
    }

    final updated = widget.userData.copyWith(
      selectedCharacterLevel: newLevel,
      selectedCharacterXp: newXp,
      gold: newGold,
      tokens: newTokens,
    );

    if (mounted) {
      _applyUpdatedUser(updated);
    }
  }

  String _cucsgHash(String value) {
    final bytes = Uint8List(value.length);
    for (var i = 0; i < value.length; i++) {
      bytes[i] = value.codeUnitAt(i) & 0xFF;
    }
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _buildFinishPayloadBase64() {
    final payload = <String, Object?>{
      'status': {
        'wind': _attrWind,
        'fire': _attrFire,
        'lightning': _attrLightning,
        'water': _attrWater,
        'earth': _attrEarth,
      },
      'items': {
        'weapon': _weaponId,
        'set': _setId,
        'back_item': _backItemId,
        'accessory': _accessoryId,
      },
      // Sementara gunakan 1 skill default; di masa depan
      // bisa diganti dengan daftar skill yang sebenarnya.
      '____': [
        {
          '_': 'skill_10',
          '__': 29029,
        },
      ],
      'bytes': {
        // Nilai-nilai berikut diambil dari contoh payload asli.
        '_': 8216461,
        '__': 8216461,
        '___':
            '176361912940367c3cc999a9f9e951a1d33211545b84b2d5a63933b0020433000c3bb410fb1763619129176361912917636191291763619129',
        '____': 1763619129,
        '_____': 8216461,
        '______': 8216461,
      },
    };

    final jsonText = jsonEncode(payload);
    final bytes = utf8.encode(jsonText);
    return base64Encode(bytes);
  }

  int _combinedProgress(int level, int xp) {
    // Kombinasi level+xp menjadi satu angka besar
    // untuk perbandingan monoton tanpa harus
    // menghitung total XP kumulatif.
    return level * 100000000 + xp;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _currentLevel;
    final xp = _currentXp;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusRow(theme),
                          const SizedBox(height: 16),
                          _CharacterStatusCard(
                            gold: _currentGold,
                            level: level,
                            xp: xp,
                          ),
                          const SizedBox(height: 16),
                          _SessionPanel(
                            isRunning: _isLevelling,
                            secondsRemaining: _currentCountdown,
                            onStart: _startLevelling,
                            onStop: _stopLevelling,
                          ),
                          const SizedBox(height: 16),
                          _LevellingSettingsCard(
                            onDelayRangeChanged: _updateDelayRange,
                          ),
                          const SizedBox(height: 16),
                          _AmfLogPanel(entries: _logs),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        Text(
          'Levelling System',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    final isRunning = _isLevelling;
    final Color dotColor = isRunning ? const Color(0xFF22C55E) : Colors.redAccent;
    final String label = isRunning ? 'Running' : 'Stopped';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterStatusCard extends StatelessWidget {
  final int gold;
  final int level;
  final int xp;

  const _CharacterStatusCard({
    required this.gold,
    required this.level,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasXp = level > 0 && xp > 0;
    final progress = hasXp ? calculateXpProgress(level, xp) : 0.0;
    final current = hasXp ? currentXpInLevel(level, xp) : 0;
    final required = hasXp ? requiredXpForLevel(level) : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Character Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC6B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFACC6B).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 18,
                      color: Color(0xFFFACC6B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gold',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gold.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFACC6B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'XP Progress',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasXp ? 'Level $level' : 'XP belum tersedia',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              if (hasXp)
                Text(
                  'XP $current / $required',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF22C55E).withOpacity(0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevellingSettingsCard extends StatefulWidget {
  final void Function(int min, int max)? onDelayRangeChanged;

  const _LevellingSettingsCard({this.onDelayRangeChanged});

  @override
  State<_LevellingSettingsCard> createState() => _LevellingSettingsCardState();
}

class _LevellingSettingsCardState extends State<_LevellingSettingsCard> {
  final TextEditingController _minDelayController =
      TextEditingController(text: '5');
  final TextEditingController _maxDelayController =
      TextEditingController(text: '7');
  final TextEditingController _targetLevelController =
      TextEditingController();

  int? _minDelay = 5;
  int? _maxDelay = 7;
  bool _noLimit = true;

  @override
  void dispose() {
    _minDelayController.dispose();
    _maxDelayController.dispose();
    _targetLevelController.dispose();
    super.dispose();
  }

  void _onDelayChanged() {
    final minVal = int.tryParse(_minDelayController.text);
    final maxVal = int.tryParse(_maxDelayController.text);

    int? newMin = minVal;
    int? newMax = maxVal;

    if (newMin != null && newMax != null && newMin > newMax) {
      // Pastikan nilai min tidak lebih besar dari max.
      if (_minDelay != null && _minDelay == newMin) {
        newMin = newMax;
        _minDelayController.text = newMin.toString();
      } else {
        newMax = newMin;
        _maxDelayController.text = newMax.toString();
      }
    }

    setState(() {
      _minDelay = newMin;
      _maxDelay = newMax;
    });

    if (newMin != null && newMax != null) {
      widget.onDelayRangeChanged?.call(newMin, newMax);
    }
  }

  void _toggleNoLimit(bool? value) {
    setState(() {
      _noLimit = value ?? false;
      if (_noLimit) {
        _targetLevelController.clear();
      }
    });
  }

  void _onTargetLevelChanged(String value) {
    if (value.trim().isNotEmpty && _noLimit) {
      setState(() {
        _noLimit = false;
      });
    }
  }

  String _infoText() {
    final minVal = int.tryParse(_minDelayController.text);
    final maxVal = int.tryParse(_maxDelayController.text);
    if (minVal != null && maxVal != null) {
      return 'Info: The system will automatically farm XP with random delays between $minVal–$maxVal seconds.';
    }
    return 'Info: The system will automatically farm XP with a random delay between actions.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Delay Between Actions (seconds)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SettingsField(
                  controller: _minDelayController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onDelayChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'to',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SettingsField(
                  controller: _maxDelayController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onDelayChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Target Level',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsField(
            controller: _targetLevelController,
            hintText: 'Leave blank for no limit',
            enabled: !_noLimit,
            keyboardType: TextInputType.number,
            onChanged: _onTargetLevelChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _noLimit,
                onChanged: _toggleNoLimit,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'No limit (continuous levelling)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.blue.shade300,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _infoText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPanel extends StatelessWidget {
  final bool isRunning;
  final int secondsRemaining;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _SessionPanel({
    required this.isRunning,
    required this.secondsRemaining,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatSeconds(secondsRemaining),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRunning ? null : onStart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Levelling'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRunning ? onStop : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop'),
          ),
        ),
      ],
    );
  }

  String _formatSeconds(int seconds) {
    final clamped = seconds.clamp(0, 99 * 60 + 59);
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

class _AmfLogPanel extends StatelessWidget {
  final List<_LogEntry> entries;

  const _AmfLogPanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMF Logs',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada log.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.body,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      Colors.white.withOpacity(0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _SettingsField({
    this.hintText = '',
    this.controller,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
      ),
    );
  }
}

class _LogEntry {
  final DateTime timestamp;
  final String title;
  final String body;

  _LogEntry({
    required this.timestamp,
    required this.title,
    required this.body,
  });
}

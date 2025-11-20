import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:panel_app/models/user_data.dart';
import 'package:panel_app/sage/xp_table.dart';
import 'package:panel_app/widgets/app_background.dart';

class LevellingScreen extends StatefulWidget {
  final UserData userData;

  const LevellingScreen({
    super.key,
    required this.userData,
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

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLevelling) {
        timer.cancel();
        return;
      }
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentCountdown > 0) {
          _currentCountdown -= 1;
        } else {
          _currentCountdown = _pickNextDelay();
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = widget.userData.selectedCharacterLevel ?? 0;
    final xp = widget.userData.selectedCharacterXp ?? 0;

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
                            gold: widget.userData.gold,
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
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Stopped',
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
    final clamped = seconds.clamp(0, 24 * 60 * 60);
    final h = clamped ~/ 3600;
    final m = (clamped % 3600) ~/ 60;
    final s = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
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

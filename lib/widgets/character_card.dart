import 'package:flutter/material.dart';
import 'package:panel_app/models/character.dart';
import 'package:panel_app/sage/xp_table.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.4 : 0.12),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Icon(
                    character.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  character.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.5)),
                    ),
                    Text(
                      '${character.level}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Character ID',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.5)),
                    ),
                    Text(
                      character.power.toString(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: calculateXpProgress(character.level, character.xp),
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'XP ${currentXpInLevel(character.level, character.xp)} / '
                  '${requiredXpForLevel(character.level)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

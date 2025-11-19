import 'package:flutter/material.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final int progress;
  final int total;
  final int reward;

  const QuestCard({
    super.key,
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = total == 0 ? 0.0 : progress / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value.clamp(0.0, 1.0).toDouble(),
                          minHeight: 4,
                          backgroundColor:
                              Colors.white.withOpacity(0.12),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progress/$total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '+$reward',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

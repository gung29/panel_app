import 'package:flutter/material.dart';
import 'package:panel_app/models/character.dart';
import 'package:panel_app/models/user_data.dart';
import 'package:panel_app/sage/xp_table.dart';
import 'package:panel_app/widgets/app_background.dart';
import 'package:panel_app/widgets/menu_item_card.dart';
import 'package:panel_app/widgets/quest_card.dart';
import 'package:panel_app/screens/levelling_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMenuScreen extends StatefulWidget {
  final UserData userData;
  final VoidCallback onLogout;
  final ValueChanged<UserData> onUserDataUpdated;

  const MainMenuScreen({
    super.key,
    required this.userData,
    required this.onLogout,
    required this.onUserDataUpdated,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String? _activeMenuId;

  Future<void> _openBugReport() async {
    const url = 'https://www.facebook.com/agung.nich29/';
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka halaman laporan bug.'),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final theme = Theme.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah anda yakin mau logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = findCharacterById(widget.userData.selectedCharacterId);
    final level =
        widget.userData.selectedCharacterLevel ?? character?.level ?? 0;
    final xp = widget.userData.selectedCharacterXp ?? 0;

    return GradientBackground(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header + selected character summary
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Icon(
                        character?.icon ?? Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userData.username.isNotEmpty
                                ? widget.userData.username
                                : 'Guest',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character != null
                                ? '${character.name} • ID ${character.id}'
                                : 'Character ID: ${widget.userData.selectedCharacterId ?? '-'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ResourceChip(
                          icon: Icons.monetization_on_outlined,
                          label: 'Gold',
                          value: widget.userData.gold.toString(),
                          accentColor: const Color(0xFFFACC6B),
                        ),
                        const SizedBox(height: 6),
                        _ResourceChip(
                          icon: Icons.diamond_outlined,
                          label: 'Tokens',
                          value: widget.userData.tokens.toString(),
                          accentColor: const Color(0xFF38BDF8),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout_rounded),
                          color: Colors.white.withOpacity(0.8),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (level > 0 && xp > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: calculateXpProgress(level, xp),
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'XP ${currentXpInLevel(level, xp)} / '
                      '${requiredXpForLevel(level)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF22C55E).withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                children: [
                  // App status + bug report
                  const _AppStatusRow(),
                  const SizedBox(height: 12),
                  _BugReportButton(onTap: _openBugReport),
                  const SizedBox(height: 32),

                  // Game modes
                  Text(
                    'Game Modes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildMenuItem(
                        id: 'levelling',
                        icon: Icons.trending_up_rounded,
                        title: 'Levelling',
                        description: 'Level up your character instantly',
                      ),
                      _buildMenuItem(
                        id: 'event',
                        icon: Icons.event_rounded,
                        title: 'Event',
                        description: 'Soon',
                      ),
                      _buildMenuItem(
                        id: 'hunting-house',
                        icon: Icons.home_max_rounded,
                        title: 'Hunting House',
                        description: 'Soon',
                      ),
                      _buildMenuItem(
                        id: 'daemon',
                        icon: Icons.dangerous_outlined,
                        title: 'Daemon',
                        description: 'Soon',
                      ),
                      _buildMenuItem(
                        id: 'clan',
                        icon: Icons.groups_rounded,
                        title: 'Clan',
                        description: 'Soon',
                      ),
                      _buildMenuItem(
                        id: 'crew',
                        icon: Icons.directions_boat_filled_outlined,
                        title: 'Crew',
                        description: 'Soon',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Daily Quests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const QuestCard(
                    title: 'Complete 5 Battles',
                    progress: 3,
                    total: 5,
                    reward: 500,
                  ),
                  const SizedBox(height: 12),
                  const QuestCard(
                    title: 'Defeat Daemon Boss',
                    progress: 1,
                    total: 1,
                    reward: 1000,
                  ),
                  const SizedBox(height: 12),
                  const QuestCard(
                    title: 'Participate in Event',
                    progress: 0,
                    total: 1,
                    reward: 750,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String id,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MenuItemCard(
        icon: icon,
        title: title,
        description: description,
        isActive: _activeMenuId == id,
        onTap: () {
          setState(() {
            _activeMenuId = id;
          });
          if (id == 'levelling') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LevellingScreen(
                  userData: widget.userData,
                  onUserDataUpdated: widget.onUserDataUpdated,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppStatusRow extends StatelessWidget {
  const _AppStatusRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status Aplikasi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Lisensi Aktif • Tidak ada tanggal kedaluwarsa',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BugReportButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BugReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF4B4B),
                Color(0xFFB31217),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Laporkan Bug',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Kirim laporan ke Facebook',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

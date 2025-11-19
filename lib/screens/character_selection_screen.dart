import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panel_app/models/character.dart';
import 'package:panel_app/services/ninja_characters_repository.dart';
import 'package:panel_app/widgets/app_background.dart';
import 'package:panel_app/widgets/app_buttons.dart';
import 'package:panel_app/widgets/character_card.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final String username;
  final Future<void> Function(int) onCharacterSelected;
  final NinjaCharactersRepository charactersRepository;

  const CharacterSelectionScreen({
    super.key,
    required this.username,
    required this.onCharacterSelected,
    required this.charactersRepository,
  });

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  int? _selectedId;
  late Future<List<Character>> _charactersFuture;

  @override
  void initState() {
    super.initState();
    _charactersFuture = _loadCharacters();
  }

  Future<List<Character>> _loadCharacters() async {
    final response = await widget.charactersRepository.getAllCharacters();
    final summaries = response.characters;

    IconData iconForIndex(int index) {
      switch (index % 6) {
        case 0:
          return Icons.shield_moon_outlined;
        case 1:
          return Icons.auto_awesome;
        case 2:
          return Icons.travel_explore_outlined;
        case 3:
          return Icons.local_fire_department_outlined;
        case 4:
          return Icons.shield_outlined;
        default:
          return Icons.emoji_events_outlined;
      }
    }

    return List<Character>.generate(summaries.length, (index) {
      final summary = summaries[index];
      return Character(
        id: summary.charId,
        name: summary.name,
        role: "Level ${summary.level}",
        level: summary.level,
        power: summary.charId,
        xp: summary.xp,
        icon: iconForIndex(index),
      );
    });
  }

  Future<void> _handleContinue() async {
    final id = _selectedId;
    if (id != null) {
      await widget.onCharacterSelected(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientBackground(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FutureBuilder<List<Character>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            final isWeb = kIsWeb;
            return Center(
              child: Text(
                isWeb
                    ? 'Pemilihan karakter hanya tersedia di Android/Desktop.'
                    : 'Failed to load characters',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            );
          }

          final characters = snapshot.data ?? const <Character>[];

          return ListView(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome back',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your character',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ...characters.map(
                (character) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CharacterCard(
                    character: character,
                    isSelected: _selectedId == character.id,
                    onTap: () {
                      setState(() {
                        _selectedId = character.id;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: _handleContinue,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

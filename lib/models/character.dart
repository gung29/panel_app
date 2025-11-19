import 'package:flutter/material.dart';

class Character {
  final int id;
  final String name;
  final String role;
  final int level;
  final int power;
  final int xp;
  final IconData icon;

  const Character({
    required this.id,
    required this.name,
    required this.role,
    required this.level,
    required this.power,
    required this.xp,
    required this.icon,
  });
}

const List<Character> kCharacters = [
  Character(
    id: 1,
    name: 'Shadow Knight',
    role: 'Warrior',
    level: 85,
    power: 12500,
    xp: 0,
    icon: Icons.shield_moon_outlined,
  ),
  Character(
    id: 2,
    name: 'Mystic Sage',
    role: 'Mage',
    level: 78,
    power: 11200,
    xp: 0,
    icon: Icons.auto_awesome,
  ),
  Character(
    id: 3,
    name: 'Void Archer',
    role: 'Ranger',
    level: 82,
    power: 11800,
    xp: 0,
    icon: Icons.travel_explore_outlined,
  ),
  Character(
    id: 4,
    name: 'Flame Warlock',
    role: 'Warlock',
    level: 80,
    power: 11500,
    xp: 0,
    icon: Icons.local_fire_department_outlined,
  ),
  Character(
    id: 5,
    name: 'Divine Guardian',
    role: 'Paladin',
    level: 88,
    power: 13200,
    xp: 0,
    icon: Icons.shield_outlined,
  ),
  Character(
    id: 6,
    name: 'Legendary Hero',
    role: 'Champion',
    level: 95,
    power: 15000,
    xp: 0,
    icon: Icons.emoji_events_outlined,
  ),
];

Character? findCharacterById(int? id) {
  if (id == null) return null;
  for (final c in kCharacters) {
    if (c.id == id) return c;
  }
  return null;
}

class UserData {
  final String username;
  final int? selectedCharacterId;
  final int? selectedCharacterLevel;
  final int? selectedCharacterXp;
  final int gold;
  final int tokens;

  const UserData({
    required this.username,
    required this.selectedCharacterId,
    required this.selectedCharacterLevel,
    required this.selectedCharacterXp,
    required this.gold,
    required this.tokens,
  });

  const UserData.empty()
      : username = '',
        selectedCharacterId = null,
        selectedCharacterLevel = null,
        selectedCharacterXp = null,
        gold = 0,
        tokens = 0;

  UserData copyWith({
    String? username,
    int? selectedCharacterId,
    int? selectedCharacterLevel,
    int? selectedCharacterXp,
    int? gold,
    int? tokens,
  }) {
    return UserData(
      username: username ?? this.username,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      selectedCharacterLevel:
          selectedCharacterLevel ?? this.selectedCharacterLevel,
      selectedCharacterXp: selectedCharacterXp ?? this.selectedCharacterXp,
      gold: gold ?? this.gold,
      tokens: tokens ?? this.tokens,
    );
  }
}

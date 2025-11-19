class CharacterSummary {
  final int charId;
  final int accId;
  final String name;
  final int level;
  final int xp;
  final int gender;
  final int rank;
  final int prestige;
  final int? element1;
  final int? element2;
  final int? element3;
  final int? talent1;
  final int? talent2;
  final int? talent3;
  final int gold;
  final int tp;

  CharacterSummary({
    required this.charId,
    required this.accId,
    required this.name,
    required this.level,
    required this.xp,
    required this.gender,
    required this.rank,
    required this.prestige,
    required this.element1,
    required this.element2,
    required this.element3,
    required this.talent1,
    required this.talent2,
    required this.talent3,
    required this.gold,
    required this.tp,
  });

  factory CharacterSummary.fromMap(Map<String, dynamic> map) {
    int readInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    String readString(dynamic value, [String fallback = ""]) {
      if (value is String) return value;
      if (value == null) return fallback;
      return value.toString();
    }

    return CharacterSummary(
      charId: readInt(map["char_id"] ?? map["character_id"] ?? map["cid"]),
      accId: readInt(map["acc_id"] ?? map["account_id"] ?? 0),
      name: readString(map["character_name"] ?? map["name"]),
      level: readInt(map["character_level"] ?? map["level"] ?? 0),
      xp: readInt(map["character_xp"] ?? map["xp"] ?? 0),
      gender: readInt(map["character_gender"] ?? map["gender"] ?? 0),
      rank: readInt(map["character_rank"] ?? map["rank"] ?? 0),
      prestige: readInt(map["character_prestige"] ?? map["prestige"] ?? 0),
      element1: map["character_element_1"] as int?,
      element2: map["character_element_2"] as int?,
      element3: map["character_element_3"] as int?,
      talent1: map["character_talent_1"] as int?,
      talent2: map["character_talent_2"] as int?,
      talent3: map["character_talent_3"] as int?,
      gold: readInt(map["character_gold"] ?? 0),
      tp: readInt(map["character_tp"] ?? 0),
    );
  }
}

class GetAllCharactersResponse {
  final int status;
  final int error;
  final int accountType;
  final int emblemDuration;
  final int tokens;
  final int totalCharacters;
  final List<CharacterSummary> characters;

  GetAllCharactersResponse({
    required this.status,
    required this.error,
    required this.accountType,
    required this.emblemDuration,
    required this.tokens,
    required this.totalCharacters,
    required this.characters,
  });

  factory GetAllCharactersResponse.fromMap(Map<String, dynamic> map) {
    final accountData = map["account_data"];
    final list = accountData is List ? accountData : const [];
    final characters = list
        .whereType<Map>()
        .map((entry) => CharacterSummary.fromMap(
              entry.cast<String, dynamic>(),
            ))
        .toList();

    int readInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    return GetAllCharactersResponse(
      status: readInt(map["status"] ?? 0),
      error: readInt(map["error"] ?? 0),
      accountType: readInt(map["account_type"] ?? 0),
      emblemDuration: readInt(map["emblem_duration"] ?? 0),
      tokens: readInt(map["tokens"] ?? 0),
      totalCharacters:
          readInt(map["total_characters"] ?? characters.length),
      characters: characters,
    );
  }
}


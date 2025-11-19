import 'dart:async';

import 'package:panel_app/services/ninja_sage_client.dart';

class MockNinjaSageClient implements NinjaSageClient {
  const MockNinjaSageClient();

  @override
  Future<Map<String, dynamic>> invoke(
    String target, {
    List<dynamic>? body,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (target == "SystemLogin.getAllCharacters") {
      return {
        "status": 1,
        "error": 0,
        "account_type": 0,
        "emblem_duration": 0,
        "tokens": 230,
        "total_characters": 6,
        "account_data": [
          {
            "char_id": 1,
            "character_name": "Shadow Knight",
            "character_level": 85,
            "character_xp": 12500,
            "character_gender": 0,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
          {
            "char_id": 2,
            "character_name": "Mystic Sage",
            "character_level": 78,
            "character_xp": 11200,
            "character_gender": 1,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
          {
            "char_id": 3,
            "character_name": "Void Archer",
            "character_level": 82,
            "character_xp": 11800,
            "character_gender": 1,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
          {
            "char_id": 4,
            "character_name": "Flame Warlock",
            "character_level": 80,
            "character_xp": 11500,
            "character_gender": 0,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
          {
            "char_id": 5,
            "character_name": "Divine Guardian",
            "character_level": 88,
            "character_xp": 13200,
            "character_gender": 0,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
          {
            "char_id": 6,
            "character_name": "Legendary Hero",
            "character_level": 95,
            "character_xp": 15000,
            "character_gender": 0,
            "character_rank": 0,
            "character_prestige": 0,
            "character_gold": 15750,
            "character_tp": 230,
          },
        ],
      };
    }

    throw UnsupportedError("Unsupported target $target");
  }
}


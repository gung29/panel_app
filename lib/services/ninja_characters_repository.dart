import 'package:flutter/foundation.dart';
import 'package:panel_app/models/ninja_characters.dart';
import 'package:panel_app/services/ninja_sage_client.dart';
import 'package:panel_app/services/ninja_sage_workflow.dart';

class NinjaCharactersRepository {
  final NinjaSageClient client;

  const NinjaCharactersRepository(this.client);

  /// Mengambil daftar karakter dari backend.
  ///
  /// Di web, AMF langsung ke server Ninja Sage tidak didukung
  /// karena CORS, sehingga method ini akan melempar error
  /// untuk ditangani di layer UI.
  Future<GetAllCharactersResponse> getAllCharacters() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Pemanggilan karakter via AMF hanya didukung di Android/Desktop.',
      );
    }

    List<dynamic>? body;
    if (NinjaSageWorkflow.hasDesktopSession) {
      final uid = NinjaSageWorkflow.desktopUid;
      final session = NinjaSageWorkflow.desktopSessionKey;
      if (uid != null && session != null && session.isNotEmpty) {
        body = [
          [uid, session],
        ];
      }
    }

    final payload =
        await client.invoke('SystemLogin.getAllCharacters', body: body);
    return GetAllCharactersResponse.fromMap(payload);
  }
}


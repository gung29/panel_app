import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:panel_app/models/user_data.dart';
import 'package:panel_app/screens/character_selection_screen.dart';
import 'package:panel_app/screens/login_screen.dart';
import 'package:panel_app/screens/main_menu_screen.dart';
import 'package:panel_app/services/android_amf_ninja_sage_client.dart';
import 'package:panel_app/services/ninja_characters_repository.dart';
import 'package:panel_app/services/ninja_sage_workflow.dart';
import 'package:panel_app/services/web_amf_ninja_sage_client.dart';
import 'package:panel_app/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _RootNavigator(),
    );
  }
}

enum AppScreen {
  login,
  characterSelection,
  mainMenu,
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  AppScreen _currentScreen = AppScreen.login;
  UserData _userData = const UserData.empty();
  late final NinjaCharactersRepository _charactersRepository;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final client = kIsWeb
        ? WebAmfNinjaSageClient()
        : _isAndroid
            ? const AndroidAmfNinjaSageClient()
            : WebAmfNinjaSageClient();
    _charactersRepository = NinjaCharactersRepository(client);
    if (_isAndroid || _isDesktop) {
      // Jalankan urutan awal:
      // - SystemLogin.checkVersion
      // - Analytics.libraries
      // - EventsService.get
      NinjaSageWorkflow.bootstrap();
    }
  }

  Future<bool> _handleLogin(String username, String password) async {
    final result = await NinjaSageWorkflow.loginUser(username, password);
    final login = result?['login'];
    final status = (login is Map ? login['status'] : null);

    final ok = status is num ? status.toInt() == 1 : true;
    if (!ok) {
      return false;
    }

    setState(() {
      _userData = _userData.copyWith(
        username: username,
        gold: 15750,
        tokens: 230,
        selectedCharacterId: null,
        selectedCharacterLevel: null,
        selectedCharacterXp: null,
      );
      _currentScreen = AppScreen.characterSelection;
    });

    return true;
  }

  Future<void> _handleCharacterSelected(int characterId) async {
    int gold = _userData.gold;
    int tokens = _userData.tokens;
    int? level = _userData.selectedCharacterLevel;
    int? xp = _userData.selectedCharacterXp;

    if (_isAndroid || _isDesktop) {
      final data =
          await NinjaSageWorkflow.getCharacterData(characterId);
      final rawChar = data?['character_data'];
      if (rawChar is Map) {
        final levelAny = rawChar['character_level'];
        final xpAny = rawChar['character_xp'];
        final goldAny = rawChar['character_gold'];
        final tokensAny = rawChar['character_tp'];
        if (levelAny is num) level = levelAny.toInt();
        if (xpAny is num) xp = xpAny.toInt();
        if (goldAny is num) gold = goldAny.toInt();
        if (tokensAny is num) tokens = tokensAny.toInt();
      }
    }

    setState(() {
      _userData = _userData.copyWith(
        selectedCharacterId: characterId,
        selectedCharacterLevel: level,
        selectedCharacterXp: xp,
        gold: gold,
        tokens: tokens,
      );
      _currentScreen = AppScreen.mainMenu;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentScreen = AppScreen.login;
      _userData = const UserData.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.login:
        return LoginScreen(onLogin: _handleLogin);
      case AppScreen.characterSelection:
        return CharacterSelectionScreen(
          username: _userData.username,
          onCharacterSelected: _handleCharacterSelected,
          charactersRepository: _charactersRepository,
        );
      case AppScreen.mainMenu:
        return MainMenuScreen(
          userData: _userData,
          onLogout: _handleLogout,
        );
    }
  }
}

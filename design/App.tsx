import { useState } from 'react';
import { LoginPage } from './components/LoginPage';
import { CharacterSelection } from './components/CharacterSelection';
import { MainMenu } from './components/MainMenu';

type Screen = 'login' | 'character-selection' | 'main-menu';

export interface UserData {
  username: string;
  selectedCharacter: number | null;
  gold: number;
  tokens: number;
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('login');
  const [userData, setUserData] = useState<UserData>({
    username: '',
    selectedCharacter: null,
    gold: 0,
    tokens: 0,
  });

  const handleLogin = (username: string) => {
    setUserData({
      username,
      selectedCharacter: null,
      gold: 15750,
      tokens: 230,
    });
    setCurrentScreen('character-selection');
  };

  const handleCharacterSelect = (characterId: number) => {
    setUserData({ ...userData, selectedCharacter: characterId });
    setCurrentScreen('main-menu');
  };

  const handleLogout = () => {
    setCurrentScreen('login');
    setUserData({
      username: '',
      selectedCharacter: null,
      gold: 0,
      tokens: 0,
    });
  };

  return (
    <div className="min-h-screen bg-black">
      {currentScreen === 'login' && <LoginPage onLogin={handleLogin} />}
      {currentScreen === 'character-selection' && (
        <CharacterSelection onSelect={handleCharacterSelect} username={userData.username} />
      )}
      {currentScreen === 'main-menu' && (
        <MainMenu userData={userData} onLogout={handleLogout} />
      )}
    </div>
  );
}

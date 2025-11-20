import { UserData } from '../App';
import { 
  TrendingUp, 
  Calendar, 
  Home, 
  Skull, 
  Users, 
  Ship,
  Coins,
  Gem,
  LogOut,
  Trophy,
  Swords,
  Star
} from 'lucide-react';
import { useState } from 'react';

interface MainMenuProps {
  userData: UserData;
  onLogout: () => void;
}

interface MenuItemType {
  id: string;
  label: string;
  icon: typeof TrendingUp;
  description: string;
}

const menuItems: MenuItemType[] = [
  {
    id: 'levelling',
    label: 'Levelling',
    icon: TrendingUp,
    description: 'Level up your character instantly',
  },
  {
    id: 'event',
    label: 'Event',
    icon: Calendar,
    description: 'Soon',
  },
  {
    id: 'hunting-house',
    label: 'Hunting House',
    icon: Home,
    description: 'Soon',
  },
  {
    id: 'daemon',
    label: 'Daemon',
    icon: Skull,
    description: 'Soon',
  },
  {
    id: 'clan',
    label: 'Clan',
    icon: Users,
    description: 'Soon',
  },
  {
    id: 'crew',
    label: 'Crew',
    icon: Ship,
    description: 'Soon',
  },
];

export function MainMenu({ userData, onLogout }: MainMenuProps) {
  const [activeMenu, setActiveMenu] = useState<string | null>(null);

  return (
    <div className="min-h-screen bg-gradient-to-br from-zinc-950 via-black to-zinc-950">
      {/* Header */}
      <div className="border-b border-white/10 bg-black/50 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* User Info */}
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center border border-white/10">
                <Star className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-white">{userData.username}</h2>
                <p className="text-zinc-600 text-sm">Level 85 • Warrior</p>
              </div>
            </div>

            {/* Resources */}
            <div className="flex items-center gap-4">
              {/* Gold */}
              <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-xl border border-white/10">
                <div className="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                  <Coins className="w-4 h-4 text-white" />
                </div>
                <div>
                  <p className="text-xs text-zinc-600">Gold</p>
                  <p className="text-white">{userData.gold.toLocaleString()}</p>
                </div>
              </div>

              {/* Tokens */}
              <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-xl border border-white/10">
                <div className="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                  <Gem className="w-4 h-4 text-white" />
                </div>
                <div>
                  <p className="text-xs text-zinc-600">Tokens</p>
                  <p className="text-white">{userData.tokens}</p>
                </div>
              </div>

              {/* Logout */}
              <button
                onClick={onLogout}
                className="p-2 rounded-xl bg-white/5 border border-white/10 hover:bg-white/10 transition-colors text-zinc-500 hover:text-white"
              >
                <LogOut className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center">
                <Trophy className="w-6 h-6 text-white" />
              </div>
              <span className="text-sm text-zinc-600">Today</span>
            </div>
            <h3 className="text-white mb-1">Battles Won</h3>
            <p className="text-zinc-500">24 Victories</p>
          </div>

          <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center">
                <Swords className="w-6 h-6 text-white" />
              </div>
              <span className="text-sm text-zinc-600">Active</span>
            </div>
            <h3 className="text-white mb-1">Combat Power</h3>
            <p className="text-zinc-500">12,500</p>
          </div>

          <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center">
                <Star className="w-6 h-6 text-white" />
              </div>
              <span className="text-sm text-zinc-600">Rank</span>
            </div>
            <h3 className="text-white mb-1">Global Ranking</h3>
            <p className="text-zinc-500">#1,247</p>
          </div>
        </div>

        {/* Navigation Menu */}
        <div className="mb-8">
          <h2 className="text-white mb-6">Game Modes</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeMenu === item.id;

              return (
                <button
                  key={item.id}
                  onClick={() => setActiveMenu(item.id)}
                  className="text-left"
                >
                  <div
                    className={`bg-white/5 backdrop-blur-xl rounded-2xl p-6 border transition-all ${
                      isActive
                        ? 'border-white/40 bg-white/10'
                        : 'border-white/10 hover:border-white/20'
                    }`}
                  >
                    <div className="w-14 h-14 rounded-xl bg-white/10 flex items-center justify-center mb-4 border border-white/10">
                      <Icon className="w-7 h-7 text-white" />
                    </div>

                    <h3 className="text-white mb-2">{item.label}</h3>
                    <p className="text-zinc-600 text-sm">{item.description}</p>

                    {/* Progress Bar */}
                    <div className="mt-4 pt-4 border-t border-white/10">
                      <div className="flex justify-between text-xs text-zinc-600 mb-2">
                        <span>Progress</span>
                        <span>75%</span>
                      </div>
                      <div className="w-full bg-white/10 rounded-full h-1.5">
                        <div
                          className="h-full rounded-full bg-white"
                          style={{ width: '75%' }}
                        />
                      </div>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Daily Quests */}
        <div>
          <h2 className="text-white mb-6">Daily Quests</h2>
          <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10">
            <div className="space-y-4">
              {[
                { name: 'Complete 5 Battles', progress: 3, total: 5, reward: 500 },
                { name: 'Defeat Daemon Boss', progress: 1, total: 1, reward: 1000 },
                { name: 'Participate in Event', progress: 0, total: 1, reward: 750 },
              ].map((quest, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/10"
                >
                  <div className="flex-1">
                    <h4 className="text-white mb-2">{quest.name}</h4>
                    <div className="flex items-center gap-3">
                      <div className="flex-1 bg-white/10 rounded-full h-2">
                        <div
                          className="h-full rounded-full bg-white"
                          style={{ width: `${(quest.progress / quest.total) * 100}%` }}
                        />
                      </div>
                      <span className="text-xs text-zinc-600">
                        {quest.progress}/{quest.total}
                      </span>
                    </div>
                  </div>
                  <div className="ml-6 flex items-center gap-2 text-white">
                    <Coins className="w-4 h-4" />
                    <span>+{quest.reward}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

import { useState } from 'react';
import { Crown, Shield, Sword, Wand2, Target, Flame, Check } from 'lucide-react';

interface CharacterSelectionProps {
  onSelect: (characterId: number) => void;
  username: string;
}

interface Character {
  id: number;
  name: string;
  class: string;
  level: number;
  power: number;
  icon: typeof Crown;
}

const characters: Character[] = [
  {
    id: 1,
    name: 'Shadow Knight',
    class: 'Warrior',
    level: 85,
    power: 12500,
    icon: Sword,
  },
  {
    id: 2,
    name: 'Mystic Sage',
    class: 'Mage',
    level: 78,
    power: 11200,
    icon: Wand2,
  },
  {
    id: 3,
    name: 'Void Archer',
    class: 'Ranger',
    level: 82,
    power: 11800,
    icon: Target,
  },
  {
    id: 4,
    name: 'Flame Warlock',
    class: 'Warlock',
    level: 80,
    power: 11500,
    icon: Flame,
  },
  {
    id: 5,
    name: 'Divine Guardian',
    class: 'Paladin',
    level: 88,
    power: 13200,
    icon: Shield,
  },
  {
    id: 6,
    name: 'Legendary Hero',
    class: 'Champion',
    level: 95,
    power: 15000,
    icon: Crown,
  },
];

export function CharacterSelection({ onSelect, username }: CharacterSelectionProps) {
  const [selectedId, setSelectedId] = useState<number | null>(null);

  const handleSelect = (id: number) => {
    setSelectedId(id);
  };

  const handleContinue = () => {
    if (selectedId !== null) {
      onSelect(selectedId);
    }
  };

  return (
    <div className="min-h-screen p-6 bg-gradient-to-br from-zinc-950 via-black to-zinc-950">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <p className="text-zinc-600 mb-2">Welcome back</p>
          <h1 className="text-white mb-3">{username}</h1>
          <p className="text-zinc-500">Select your character</p>
        </div>

        {/* Character Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 mb-8">
          {characters.map((character) => {
            const Icon = character.icon;
            const isSelected = selectedId === character.id;

            return (
              <button
                key={character.id}
                onClick={() => handleSelect(character.id)}
                className="group relative text-left"
              >
                <div
                  className={`bg-white/5 backdrop-blur-xl rounded-2xl p-6 border transition-all ${
                    isSelected
                      ? 'border-white/40 bg-white/10'
                      : 'border-white/10 hover:border-white/20'
                  }`}
                >
                  {/* Selected Indicator */}
                  {isSelected && (
                    <div className="absolute top-4 right-4 w-6 h-6 rounded-full bg-white flex items-center justify-center">
                      <Check className="w-4 h-4 text-black" />
                    </div>
                  )}

                  {/* Character Icon */}
                  <div className="w-16 h-16 rounded-xl bg-white/10 flex items-center justify-center mb-6 border border-white/10">
                    <Icon className="w-8 h-8 text-white" />
                  </div>

                  {/* Character Info */}
                  <div className="space-y-4">
                    <div>
                      <h3 className="text-white mb-1">{character.name}</h3>
                      <p className="text-zinc-500 text-sm">{character.class}</p>
                    </div>

                    {/* Stats */}
                    <div className="pt-4 border-t border-white/10 space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-zinc-600">Level</span>
                        <span className="text-zinc-400">{character.level}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-zinc-600">Power</span>
                        <span className="text-white">{character.power.toLocaleString()}</span>
                      </div>
                    </div>

                    {/* Power Bar */}
                    <div className="w-full bg-white/10 rounded-full h-1.5">
                      <div
                        className="h-full rounded-full bg-white"
                        style={{ width: `${(character.power / 15000) * 100}%` }}
                      />
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>

        {/* Continue Button */}
        {selectedId !== null && (
          <div className="flex justify-center">
            <button
              onClick={handleContinue}
              className="px-8 py-3 bg-white hover:bg-zinc-100 text-black rounded-xl transition-colors"
            >
              Continue
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

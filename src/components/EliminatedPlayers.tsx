'use client';

import { useEffect, useState } from 'react';
import { format } from 'date-fns';

interface EliminatedPlayer {
  address: string;
  twitterUsername: string;
  eliminationDate: Date;
}

const EliminatedPlayers = () => {
  const [eliminated, setEliminated] = useState<EliminatedPlayer[]>([]);

  return (
    <div className="bg-[#1A1A1A] rounded-xl p-6">
      <div className="flex items-center gap-3 mb-5">
        <div className="w-2 h-8 bg-[#8B5CF6] rounded-full"></div>
        <h2 className="text-xl font-semibold text-white">Today's Eliminations</h2>
      </div>
      
      <div className="space-y-4">
        {eliminated.map((player, index) => (
          <div 
            key={player.address}
            className="flex items-center justify-between p-3 bg-[#222222] rounded-lg"
          >
            <div className="flex items-center gap-3">
              <span className="text-gray-500">{index + 1}</span>
              <div>
                <p className="text-gray-400">@{player.twitterUsername}</p>
                <p className="text-xs text-gray-500">{player.address.slice(0, 6)}...{player.address.slice(-4)}</p>
              </div>
            </div>
            <span className="text-xs text-gray-500">
              {format(player.eliminationDate, 'HH:mm')}
            </span>
          </div>
        ))}
        
        {eliminated.length === 0 && (
          <p className="text-center text-gray-500 py-4">No eliminations today yet</p>
        )}
      </div>
    </div>
  );
};

export default EliminatedPlayers;
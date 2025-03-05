'use client';

import { useEffect, useState } from 'react';

const EliminationTimer = () => {
  const [timeLeft, setTimeLeft] = useState<number>(0);
  
  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours}h ${minutes}m ${secs}s`;
  };

  return (
    <div className="bg-[#1A1A1A] rounded-xl p-6">
      <div className="space-y-3">
        <h3 className="text-sm font-medium text-[#8B5CF6]">NEXT ELIMINATION</h3>
        <div className="relative pt-1">
          <div className="flex mb-2 items-center justify-between">
            <div>
              <span className="text-xs font-semibold inline-block text-white">
                {formatTime(timeLeft)}
              </span>
            </div>
          </div>
          <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-[#2A2A2A]">
            <div
              style={{ width: `${(timeLeft / (8 * 3600)) * 100}%` }}
              className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-[#8B5CF6]"
            ></div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EliminationTimer;
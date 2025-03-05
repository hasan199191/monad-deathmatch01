'use client';

import { Navbar } from '@/components/Navbar';

export default function RulesPage() {
  return (
    <div className="min-h-screen bg-[#0D0D0D]">
      <Navbar />
      <main className="container mx-auto p-4 pt-16 lg:pt-20">
        <div className="max-w-6xl mx-auto">
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {/* Arena Rules Card */}
            <div className="bg-[#1A1A1A] rounded-xl p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-2 h-8 bg-[#8B5CF6] rounded-full"></div>
                <h2 className="text-xl font-semibold text-white">Arena Rules</h2>
              </div>
              
              <div className="space-y-5">
                <div className="space-y-3">
                  <h3 className="text-sm font-medium text-[#8B5CF6]">ENTRY & PARTICIPATION</h3>
                  <ul className="space-y-2 text-sm text-gray-400">
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      1 MON entry fee per participant
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Max 100 participants per pool
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      3 daily eliminations at fixed intervals
                    </li>
                  </ul>
                </div>

                <div className="space-y-3">
                  <h3 className="text-sm font-medium text-[#8B5CF6]">PHASE TRANSITIONS</h3>
                  <ul className="space-y-2 text-sm text-gray-400">
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Phase 1: 60 players remain
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Phase 2: 30 players remain
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Final Phase: Last survivor
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            {/* Betting Rules Card */}
            <div className="bg-[#1A1A1A] rounded-xl p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-2 h-8 bg-[#8B5CF6] rounded-full"></div>
                <h2 className="text-xl font-semibold text-white">Betting Rules</h2>
              </div>

              <div className="space-y-5">
                <div className="space-y-3">
                  <h3 className="text-sm font-medium text-[#8B5CF6]">BETTING PARAMETERS</h3>
                  <ul className="space-y-2 text-sm text-gray-400">
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Min bet: 0.1 MON / Max bet: 10 MON
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Separate prize pool for bets
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Multiple bets allowed
                    </li>
                  </ul>
                </div>

                <div className="space-y-3">
                  <h3 className="text-sm font-medium text-[#8B5CF6]">REWARD STRUCTURE</h3>
                  <ul className="space-y-2 text-sm text-gray-400">
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Top 10 Predictions: 25% pool
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Final Winner: 50% pool
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-[#8B5CF6]">•</span>
                      Proportional reward distribution
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          {/* Additional Compact Section */}
          <div className="mt-6 bg-[#1A1A1A] rounded-xl p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-8 bg-[#8B5CF6] rounded-full"></div>
                  <h3 className="text-lg font-semibold text-white">Elimination Process</h3>
                </div>
                <ul className="space-y-3 text-sm text-gray-400">
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    Daily automated eliminations
                  </li>
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    Random selection with weight system
                  </li>
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    Eliminated players can't receive bets
                  </li>
                </ul>
              </div>

              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-8 bg-[#8B5CF6] rounded-full"></div>
                  <h3 className="text-lg font-semibold text-white">General Guidelines</h3>
                </div>
                <ul className="space-y-3 text-sm text-gray-400">
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    No refunds after elimination
                  </li>
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    2% platform fee on winnings
                  </li>
                  <li className="flex gap-2">
                    <span className="text-[#8B5CF6]">▹</span>
                    Smart contract governs all rules
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
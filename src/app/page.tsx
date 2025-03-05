'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useSession, signIn } from 'next-auth/react';
import { useAccount } from 'wagmi';
import { useRouter } from 'next/navigation';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Image from 'next/image';

export default function HomePage() {
  const { data: session, status } = useSession();
  const { isConnected } = useAccount();
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const hasRedirected = useRef(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const handleTwitterSignIn = async () => {
    try {
      await signIn('twitter', {
        callbackUrl: 'https://monad-deathmatch01.vercel.app',
        redirect: true
      });
    } catch (err) {
      console.error('Twitter connection error:', err);
      setError('X connection failed');
    }
  };

  useEffect(() => {
    if (!mounted || status === 'loading' || hasRedirected.current) return;
    
    if (session && isConnected) {
      hasRedirected.current = true;
      router.replace('/home');
    }
  }, [mounted, session, isConnected, status, router]);

  const isTwitterConnected = !!session;
  const isWalletConnected = isConnected;

  if (!mounted || status === 'loading') {
    return (
      <div className="min-h-screen bg-[#0D0D0D] flex items-center justify-center">
        <div className="text-2xl text-white">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen relative bg-[#0D0D0D]">
      {/* Banner Background */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/banner.png"
          alt="Monad Deathmatch Banner"
          fill
          priority
          quality={100}
          className="object-cover opacity-30"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-[#0D0D0D]/70 to-[#0D0D0D]" />
      </div>

      {/* Content */}
      <div className="relative z-10 container mx-auto px-4 pt-32 md:pt-40">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <h1 className="text-5xl md:text-6xl font-bold text-white">
            Monad Deathmatch
          </h1>
          <p className="text-xl md:text-2xl text-gray-300">
            Ultimate survival competition on blockchain
          </p>

          {/* Auth Buttons */}
          <div className="flex flex-col gap-4 max-w-md mx-auto">
            {/* Wallet Connect Button */}
            <ConnectButton.Custom>
              {({ account, chain, openConnectModal }) => (
                <button
                  onClick={openConnectModal}
                  className="w-full px-6 py-3 bg-[#8B5CF6] hover:bg-[#7C3AED] text-white rounded-lg font-medium transition-colors"
                >
                  {account ? '✓ Wallet Connected' : 'Connect Wallet'}
                </button>
              )}
            </ConnectButton.Custom>

            {/* X Connect Button */}
            <button
              onClick={handleTwitterSignIn}
              disabled={!!session}
              className={`w-full px-6 py-3 rounded-lg font-medium transition-colors ${
                session 
                  ? 'bg-green-600 text-white cursor-not-allowed' 
                  : 'bg-[#8B5CF6] hover:bg-[#7C3AED] text-white'
              }`}
            >
              {session ? '✓ X Account Connected' : 'Connect X Account'}
            </button>
          </div>
        </div>
      </div>

      {/* Features Grid */}
      <div className="relative z-10 container mx-auto px-4 py-16">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {/* Feature Cards */}
          <FeatureCard
            icon="money"
            title="Massive Prize Pool"
            description="Win up to 50% of the total prize pool as the final survivor"
          />
          <FeatureCard
            icon="bet"
            title="Place Your Bets"
            description="Bet on players and earn additional rewards"
          />
          <FeatureCard
            icon="speed"
            title="Fast & Fair"
            description="All transactions are processed on Monad blockchain"
          />
        </div>
      </div>
    </div>
  );
}

// Feature Card Component
function FeatureCard({ icon, title, description }: {
  icon: 'money' | 'bet' | 'speed';
  title: string;
  description: string;
}) {
  return (
    <div className="bg-[#1A1A1A] p-6 rounded-xl border border-[#262626] hover:border-[#8B5CF6] transition-colors">
      <div className="h-12 w-12 bg-[#8B5CF6]/20 rounded-lg flex items-center justify-center mb-4">
        {/* Icon SVG based on prop */}
        {getFeatureIcon(icon)}
      </div>
      <h3 className="text-xl font-semibold text-white mb-2">{title}</h3>
      <p className="text-gray-400">{description}</p>
    </div>
  );
}
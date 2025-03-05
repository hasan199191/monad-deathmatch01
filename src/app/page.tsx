// app/page.tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import { useSession, signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import Image from 'next/image';

export default function LandingPage() {
  const { data: session, status } = useSession();
  const router = useRouter();
  const { address: wagmiAddress, isConnected } = useAccount();
  const hasRedirected = useRef(false);
  const [error, setError] = useState<string>('');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Cüzdan adresini kaydet
  useEffect(() => {
    if (isConnected && wagmiAddress) {
      localStorage.setItem('walletAddress', wagmiAddress);
      document.cookie = `walletAddress=${wagmiAddress}; path=/; max-age=86400; SameSite=Lax`;
    }
  }, [isConnected, wagmiAddress]);

  // Twitter bağlantısı
  const handleTwitterSignIn = async () => {
    try {
      await signIn('twitter', { 
        callbackUrl: '/', 
        redirect: true 
      });
    } catch (err) {
      console.error('Twitter connection error:', err);
      setError('X connection failed');
    }
  };

  // Yönlendirme kontrolü
  useEffect(() => {
    if (!mounted || status === 'loading' || hasRedirected.current) return;
    
    if (session && isConnected) {
      hasRedirected.current = true;
      router.replace('/home');
    }
  }, [mounted, session, isConnected, status, router]);

  // Durumlar
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
          {/* Title and Description */}
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
          {/* Feature 1 */}
          <div className="bg-[#1A1A1A] p-6 rounded-xl border border-[#262626] hover:border-[#8B5CF6] transition-colors">
            <div className="h-12 w-12 bg-[#8B5CF6]/20 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-[#8B5CF6]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-white mb-2">Massive Prize Pool</h3>
            <p className="text-gray-400">Win up to 50% of the total prize pool as the final survivor</p>
          </div>

          {/* Feature 2 */}
          <div className="bg-[#1A1A1A] p-6 rounded-xl border border-[#262626] hover:border-[#8B5CF6] transition-colors">
            <div className="h-12 w-12 bg-[#8B5CF6]/20 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-[#8B5CF6]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-white mb-2">Place Your Bets</h3>
            <p className="text-gray-400">Bet on players and earn additional rewards</p>
          </div>

          {/* Feature 3 */}
          <div className="bg-[#1A1A1A] p-6 rounded-xl border border-[#262626] hover:border-[#8B5CF6] transition-colors">
            <div className="h-12 w-12 bg-[#8B5CF6]/20 rounded-lg flex items-center justify-center mb-4">
              <svg className="w-6 h-6 text-[#8B5CF6]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-white mb-2">Fast & Fair</h3>
            <p className="text-gray-400">All transactions are processed on Monad blockchain</p>
          </div>
        </div>
      </div>
    </div>
  );
}
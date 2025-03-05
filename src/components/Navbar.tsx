// components/Navbar.tsx
'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useState, useEffect } from 'react';
import { useAccount, useDisconnect } from 'wagmi';
import { signOut } from 'next-auth/react';

export const Navbar = () => {
  const pathname = usePathname();
  const router = useRouter();
  const { address: wagmiAddress, isConnected } = useAccount();
  const { disconnect } = useDisconnect();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Bağlantıyı kesme fonksiyonu
  const handleDisconnect = async () => {
    try {
      // Wagmi bağlantısını kes
      disconnect();
      
      // NextAuth oturumunu sonlandır
      await signOut({ redirect: false });
      
      // Local storage ve cookie'leri temizle
      localStorage.removeItem('walletAddress');
      document.cookie = 'walletAddress=; path=/; expires=Thu, 01 Jan 1970 00:00:01 GMT';
      
      // Ana sayfaya yönlendir
      router.replace('/');
    } catch (error) {
      console.error('Disconnect error:', error);
    }
  };

  if (!mounted) return null;

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-[#0D0D0D]/80 backdrop-blur-sm border-b border-[#262626]">
      <div className="container mx-auto px-4 h-16">
        <div className="flex items-center justify-between h-full">
          {/* Logo ve Menü */}
          <div className="flex items-center gap-8">
            <Link href="/home" className="text-[#8B5CF6] font-bold text-xl">
              Monad Deathmatch
            </Link>
            <div className="flex items-center gap-6">
              <Link 
                href="/home" 
                className={`navbar-link ${pathname === '/home' ? 'navbar-link-active' : ''}`}
              >
                Home
              </Link>
              <Link 
                href="/rules" 
                className={`navbar-link ${pathname === '/rules' ? 'navbar-link-active' : ''}`}
              >
                Rules
              </Link>
            </div>
          </div>
          
          {/* Cüzdan Durumu ve Disconnect Butonu */}
          <div className="flex items-center gap-4">
            {isConnected ? (
              <div className="flex items-center gap-2">
                <div className="px-4 py-2 bg-[#8B5CF6]/20 border border-[#8B5CF6] rounded-lg text-white">
                  {wagmiAddress?.slice(0, 6)}...{wagmiAddress?.slice(-4)}
                </div>
                <button
                  onClick={handleDisconnect}
                  className="px-3 py-2 bg-red-500/20 hover:bg-red-500/30 border border-red-500 rounded-lg text-red-400 hover:text-red-300 transition-colors"
                >
                  Disconnect
                </button>
              </div>
            ) : (
              <ConnectButton />
            )}
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
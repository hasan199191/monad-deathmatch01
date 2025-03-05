// providers/RainbowKitProvider.tsx
'use client';

import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { WagmiConfig } from 'wagmi';
import { useEffect, useState, ReactNode } from 'react';
import config, { chains } from '@/app/wagmi';

interface RainbowKitProviderWrapperProps {
  children: ReactNode;
}

export default function RainbowKitProviderWrapper({ children }: RainbowKitProviderWrapperProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  return (
    <WagmiConfig config={config}>
      <RainbowKitProvider
        chains={chains}
        theme={darkTheme({
          accentColor: '#8B5CF6',
          accentColorForeground: 'white',
          borderRadius: 'large',
          overlayBlur: 'small'
        })}
        coolMode
      >
        {children}
      </RainbowKitProvider>
    </WagmiConfig>
  );
}
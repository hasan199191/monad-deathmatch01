'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiConfig, createConfig, configureChains } from 'wagmi';
import { publicProvider } from 'wagmi/providers/public';
import { getDefaultWallets, RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import React, { ReactNode } from 'react';
import { monadChain } from '@/app/wagmi';

const queryClient = new QueryClient();

const { chains, publicClient } = configureChains(
  [monadChain],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: 'Monad Deathmatch',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains,
});

const config = createConfig({
  autoConnect: true,
  publicClient,
  connectors,
});

interface ContextProviderProps {
  children: ReactNode;
  cookies?: string | null;
}

function ContextProvider({ children, cookies }: ContextProviderProps) {
  return (
    <WagmiConfig config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider 
          chains={chains} 
          theme={darkTheme()} 
          coolMode
        >
          {typeof children === 'bigint' ? children.toString() : children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}

export default ContextProvider;
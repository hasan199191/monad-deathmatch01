import { createConfig, configureChains, Chain } from 'wagmi';
import { publicProvider } from 'wagmi/providers/public';
import { getDefaultWallets } from '@rainbow-me/rainbowkit';

export const monadChain: Chain = {
  id: 10143,
  name: 'Monad Testnet',
  network: 'monad-testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'MONAD',
    symbol: 'MON',
  },
  rpcUrls: {
    default: {
      http: ['https://testnet-rpc.monad.xyz/'],
    },
    public: {
      http: ['https://testnet-rpc.monad.xyz/'],
    },
  },
  blockExplorers: {
    default: { url: 'https://testnet.monadexplorer.com', name: 'Monad Explorer' },
  },
contracts: {
    multicall3: {
      address: '0xcA11bde05977b3631167028862bE2a173976CA11',
      blockCreated: 1,
    },
  },
  testnet: true,
};

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

export { chains };
export default config;
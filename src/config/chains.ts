import { Chain } from 'viem'

export const monad = {
  id: 10143,
  name: 'Monad Testnet',
  network: 'monad-testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'MON',
    symbol: 'MON',
  },
  rpcUrls: {
    default: {
      http: ['https://rpc.testnet.monad.xyz/'],
    },
    public: {
      http: ['https://rpc.testnet.monad.xyz/'],
    },
  },
} as const satisfies Chain
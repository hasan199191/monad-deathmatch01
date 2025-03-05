import { MetaMaskInpageProvider } from "@metamask/providers";
import type { ExternalProvider } from '@ethersproject/providers';

declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider & ExternalProvider;
  }
}
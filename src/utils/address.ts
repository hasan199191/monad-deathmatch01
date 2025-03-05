/**
 * Shortens an Ethereum address by showing only the first 6 and last 4 characters
 * @param address The full Ethereum address
 * @returns The shortened address (e.g., "0x1234...5678")
 */
export function shortenAddress(address: string): string {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }
  
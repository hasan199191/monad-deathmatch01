import dotenv from 'dotenv';
import path from 'path';

// .env dosyasının konumunu belirt
const envPath = path.resolve(process.cwd(), '.env');

// .env dosyasını yükle
dotenv.config({ path: envPath });

interface Env {
  MONAD_RPC_URL: string;
  MONAD_TESTNET_ID: number;
}

// Environment değişkenlerini export et
export const ENV: Env = {
  MONAD_RPC_URL: 'https://testnet-rpc.monad.xyz',
  MONAD_TESTNET_ID: 10143
};
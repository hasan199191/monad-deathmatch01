import * as dotenv from 'dotenv';
import { resolve } from 'path';

// .env dosyasını yükle
dotenv.config({
  path: resolve(process.cwd(), '.env')
});

// Tip güvenliği için env interface
interface EnvConfig {
  NEXT_PUBLIC_SUPABASE_URL: string;
  NEXT_PUBLIC_SUPABASE_ANON_KEY: string;
  NEXT_PUBLIC_WALLET_CONNECT_ID: string;
  TWITTER_CLIENT_ID: string;
  TWITTER_CLIENT_SECRET: string;
}

// Çevresel değişkenleri kontrol et ve döndür
export const env: EnvConfig = {
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL!,
  NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  NEXT_PUBLIC_WALLET_CONNECT_ID: process.env.NEXT_PUBLIC_WALLET_CONNECT_ID!,
  TWITTER_CLIENT_ID: process.env.TWITTER_CLIENT_ID!,
  TWITTER_CLIENT_SECRET: process.env.TWITTER_CLIENT_SECRET!
};

// Eksik değişkenleri kontrol et
Object.entries(env).forEach(([key, value]) => {
  if (!value) {
    throw new Error(`${key} çevresel değişkeni tanımlanmamış`);
  }
});
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Veritabanı tip tanımları
export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          wallet_address: string;
          twitter_id: string | null;
          twitter_username: string | null;
          username: string | null;
          profile_image_url: string | null;
          created_at: string;
          updated_at: string | null;
        };
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['users']['Insert']>;
      };
      participants: {
        Row: {
          id: string;
          wallet_address: string;
          pool_id: number;
          is_eliminated: boolean;
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['participants']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['participants']['Insert']>;
      };
      bets: {
        Row: {
          id: string;
          bettor_address: string;
          target_address: string;
          pool_id: number;
          amount: string;
          bet_type: '0' | '1';
          created_at: string;
        };
        Insert: Omit<Database['public']['Tables']['bets']['Row'], 'id' | 'created_at'>;
        Update: Partial<Database['public']['Tables']['bets']['Insert']>;
      };
    };
  };
}

// Supabase istemcisi oluştur
export const supabase = createClient<Database>(supabaseUrl, supabaseKey);

// Yardımcı fonksiyonlar
export async function getUserByWallet(walletAddress: string) {
  const { data, error } = await supabase
    .from('users')
    .select()
    .eq('wallet_address', walletAddress)
    .single();

  if (error) throw error;
  return data;
}

export async function getParticipants() {
  const { data, error } = await supabase
    .from('participants')
    .select(`
      id,
      wallet_address,
      pool_id,
      is_eliminated,
      created_at,
      users (
        twitter_username,
        profile_image_url
      )
    `)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

export async function createOrUpdateUser(userData: Database['public']['Tables']['users']['Insert']) {
  const { data, error } = await supabase
    .from('users')
    .upsert(userData)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export const saveUserBet = async (bet: Database['public']['Tables']['bets']['Insert']) => {
  const { data, error } = await supabase
    .from('bets')
    .insert([bet])
    .select()
    .single();

  if (error) throw error;
  return data;
};
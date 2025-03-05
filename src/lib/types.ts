export interface Participant {
    id: string;
    wallet_address: string;
    twitter_username: string;
    twitter_profile_image: string;
    twitter_id: string;
    joined_pool: boolean;  // Havuza katılım durumu
    created_at: string;
    updated_at: string;
  }
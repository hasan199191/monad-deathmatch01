import { supabase } from '@/lib/supabase';

export async function getParticipants() {
  try {
    const { data: participants, error } = await supabase
      .from('participants')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching participants:', error);
      return { participants: [] };
    }

    return {
      participants: participants.map(p => ({
        address: p.wallet_address.toLowerCase(),
        twitterUsername: p.twitter_username,
        profileImage: p.twitter_profile_image,
        isActive: p.joined_pool,
        joinedAt: p.created_at
      }))
    };

  } catch (error) {
    console.error('Error in getParticipants:', error);
    return { participants: [] };
  }
}
import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
  try {
    // Kullanıcı bilgileri ile birlikte katılımcıları getir
    const { data: participants, error } = await supabase
      .from('participants')
      .select(`
        *,
        users:wallet_address (
          twitter_username,
          profile_image_url
        )
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ 
      success: true, 
      participants: participants.map(p => ({
        ...p,
        twitterUsername: p.users?.twitter_username,
        profileImage: p.users?.profile_image_url
      }))
    });

  } catch (error) {
    console.error('Error fetching participant stats:', error);
    return NextResponse.json({ 
      success: false, 
      error: 'Internal Server Error' 
    }, { status: 500 });
  }
}

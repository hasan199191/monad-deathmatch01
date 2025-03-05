import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function POST(req: Request) {
  try {
    const { walletAddress, twitterId, twitterUsername, profileImageUrl } = await req.json();

    // Önce kullanıcının var olup olmadığını kontrol et
    const { data: existingUser } = await supabase
      .from('users')
      .select('*')
      .eq('wallet_address', walletAddress)
      .single();

    if (existingUser) {
      // Kullanıcı varsa güncelle
      const { data, error } = await supabase
        .from('users')
        .update({
          twitter_id: twitterId,
          twitter_username: twitterUsername,
          profile_image_url: profileImageUrl,
          updated_at: new Date().toISOString()
        })
        .eq('wallet_address', walletAddress);

      if (error) throw error;
      return NextResponse.json({ success: true, data });
    } else {
      // Kullanıcı yoksa yeni kayıt oluştur
      const { data, error } = await supabase
        .from('users')
        .insert({
          wallet_address: walletAddress,
          twitter_id: twitterId,
          twitter_username: twitterUsername,
          profile_image_url: profileImageUrl,
          created_at: new Date().toISOString()
        });

      if (error) throw error;
      return NextResponse.json({ success: true, data });
    }
  } catch (error) {
    console.error('Error connecting Twitter:', error);
    return NextResponse.json({ success: false, error: 'Internal Server Error' }, { status: 500 });
  }
}
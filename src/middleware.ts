import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

export async function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname;
  
  // Public rotaları kontrol et
  if (
    path.startsWith('/_next') || 
    path.includes('/api/auth') || 
    path.includes('.') ||
    path === '/' // Ana sayfa her zaman erişilebilir
  ) {
    return NextResponse.next();
  }

  // Korumalı rotalar
  const protectedRoutes = ['/home'];
  
  if (protectedRoutes.includes(path)) {
    try {
      const token = await getToken({ 
        req: request, 
        secret: process.env.NEXTAUTH_SECRET 
      });
      
      const walletAddress = request.cookies.get('walletAddress')?.value;

      // Debug için detaylı loglama
      console.log('Auth Check:', {
        path,
        hasToken: !!token,
        hasWallet: !!walletAddress,
        timestamp: new Date().toISOString()
      });

      // Her iki auth da gerekli
      if (!token || !walletAddress) {
        console.log('Authentication failed:', {
          hasToken: !!token,
          hasWallet: !!walletAddress
        });
        return NextResponse.redirect(new URL('/', request.url));
      }

    } catch (error) {
      console.error('Middleware Error:', error);
      return NextResponse.redirect(new URL('/', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
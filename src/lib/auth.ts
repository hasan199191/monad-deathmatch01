import { NextAuthOptions } from 'next-auth';
import TwitterProvider from 'next-auth/providers/twitter';
import { Session } from 'next-auth';

// Session tipini genişlet
interface CustomSession extends Session {
  user: {
    id: string;
    name?: string | null;
    email?: string | null;
    image?: string | null;
    username?: string | null;
  }
}

export const authOptions: NextAuthOptions = {
  providers: [
    TwitterProvider({
      clientId: process.env.TWITTER_CLIENT_ID!,
      clientSecret: process.env.TWITTER_CLIENT_SECRET!,
      version: "2.0",
    }),
  ],
  callbacks: {
    async session({ session, token }) {
      const customSession = session as CustomSession;
      if (customSession.user) {
        if (token.sub) {
          customSession.user.id = token.sub;
        }
        customSession.user.username = (token.profile as any)?.username || null;
      }
      return customSession;
    },
    async jwt({ token, profile, account }) {
      if (profile) {
        token.profile = profile;
      }
      return token;
    }
  },
  debug: true // Geliştirme aşamasında hataları görmek için
};
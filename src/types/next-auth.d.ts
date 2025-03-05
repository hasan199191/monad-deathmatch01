import NextAuth from "next-auth";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
      username?: string | null; // Twitter username için
    };
  }

  interface JWT {
    profile?: {
      username?: string;
    };
  }
}

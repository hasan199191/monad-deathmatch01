/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: false, // SWC minify'ı devre dışı bırak
  output: 'standalone',
  images: {
    domains: ['pbs.twimg.com', 'api.dicebear.com'],
  },
  env: {
    NEXT_PUBLIC_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_CONTRACT_ADDRESS,
    NEXT_PUBLIC_MONAD_RPC_URL: process.env.NEXT_PUBLIC_MONAD_RPC_URL,
    NEXT_PUBLIC_MONAD_CHAIN_ID: process.env.NEXT_PUBLIC_MONAD_CHAIN_ID,
  },
  // Harici hostname'lere izin ver
  experimental: {
    externalDir: true,
    esmExternals: "loose",
    swcPlugins: [],
    forceSwcTransforms: true
  },
  // Ngrok için güvenli bir şekilde izin ver
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: 'https://monad-deathmatch.vercel.app' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type' },
          {
            key: 'Content-Security-Policy',
            value: "frame-ancestors 'self' https://monad-deathmatch01.vercel.app"
          }
        ],
      },
    ];
  },
  webpack: (config) => {
    config.externals = [...config.externals, 'websocket'];
    config.resolve.fallback = {
      ...config.resolve.fallback,
      fs: false,
      net: false,
      tls: false,
    };
    config.module.rules.push({
      test: /\.m?js$/,
      type: "javascript/auto",
      resolve: {
        fullySpecified: false,
      },
    });
    return config;
  },
  transpilePackages: [
    '@rainbow-me/rainbowkit',
    'wagmi',
    'viem',
  ],
  compiler: {
    styledComponents: true
  },
  pageExtensions: ['ts', 'tsx', 'js', 'jsx']
};

module.exports = nextConfig;
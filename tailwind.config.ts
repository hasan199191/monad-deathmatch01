import type { Config } from "tailwindcss";

export default {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#00B300', // Ana yeşil renk
          dark: '#009900',
          light: '#00CC00',
        },
        secondary: {
          DEFAULT: '#00ba7c', // İkincil yeşil renk
        },
        background: {
          DEFAULT: '#0D0D0D', // Ana arka plan
          card: '#1A1A1A',    // Kart arka planı 
          element: '#222222', // Element arka planı
        },
        text: {
          primary: '#FFFFFF',
          secondary: '#9CA3AF',
          success: '#00ba7c',
          warning: '#FFA500',
          danger: '#FF4444',
        }
      }
    }
  },
  plugins: [],
} satisfies Config;
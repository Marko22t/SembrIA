/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2e7d32', // Verde principal
          dark: '#1b3a1f',    // Verde oscuro premium
          light: '#e8f5e9',  // Fondo verde muy suave
        },

        secondary: {
          DEFAULT: '#43a047', // Verde brillante
          light: '#66bb6a',   // Verde suave
          soft: '#a5d6a7',    // Verde pastel
        },

        earth: {
          DEFAULT: '#6d4c41', // Marrón agrícola
          dark: '#3e2723',    // Tierra oscura
          light: '#bcaaa4',   // Tierra clara
        },

        accent: {
          amber: '#f59e0b',
          red: '#ef4444',
        },

        bg: '#f5f0e8',       // Fondo crema elegante
        whiteSoft: '#ffffff',
      },

      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        title: ['Outfit', 'sans-serif'],
      },

      boxShadow: {
        soft: '0 8px 30px rgba(27, 58, 31, 0.08)',
        card: '0 10px 40px rgba(27, 58, 31, 0.12)',
      },

      borderRadius: {
        xl2: '1.5rem',
      },
    },
  },
  plugins: [],
}
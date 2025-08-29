/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}", "./**/*.{html,js}"],
  theme: {
    extend: {
      colors: {
        earth: {
          50: '#f7f6f3',
          100: '#edeae3',
          200: '#ddd7c7',
          300: '#c8bea2',
          400: '#b4a47e',
          500: '#a08d63',
          600: '#8d7a57',
          700: '#75644a',
          800: '#615340',
          900: '#524639',
        },
        natural: {
          50: '#f8f9f7',
          100: '#eef1eb',
          200: '#dde4d4',
          300: '#c4d1b5',
          400: '#a7b88e',
          500: '#8ea071',
          600: '#708158',
          700: '#586747',
          800: '#48553b',
          900: '#3d4732',
        },
        gold: {
          50: '#fefbeb',
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#fbbf24',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
        }
      },
      fontFamily: {
        'playfair': ['Playfair Display', 'serif'],
        'poppins': ['Poppins', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.6s ease-in-out',
        'slide-up': 'slideUp 0.6s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(30px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        }
      }
    },
  },
  plugins: [],
}

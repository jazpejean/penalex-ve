/** PostCSS: procesa Tailwind v4 en el build webpack.
 *  El proyecto usa @tailwindcss/turbopack para el motor Turbopack; esta
 *  config permite que el build con webpack también genere el CSS completo. */
export default {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

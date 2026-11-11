import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },
  // El repo tiene varios lockfiles; fijar la raíz de turbopack en penalex-web
  // para que Next no asuma /home/jeanjazpe/Penalex_VE como workspace.
  turbopack: {
    root: __dirname,
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
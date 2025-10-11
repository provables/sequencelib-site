// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  cacheDir: ".astro",

  vite: {
    cacheDir: ".vite",
    plugins: [tailwindcss()],
    resolve: {
      preserveSymlinks: false,
    },
  },

  integrations: [
    starlight({
      title: "Sequencelib",
      customCss: [
        // Path to your Tailwind base styles:
        "./src/styles/global.css",
        "@fontsource-variable/roboto",
      ],
      components: {
        Search: "./src/components/Search.astro",
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/provables/sequencelib",
        },
      ],
    }),
  ],
});

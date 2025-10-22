// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";
import { generateSequencesConfig } from './gen_sidebar.mjs';

const sequencesConfig = await generateSequencesConfig('./src/content/docs/sequences');

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
      favicon: "/favicon.png",
      lastUpdated: true,
      customCss: [
        // Path to your Tailwind base styles:
        "./src/styles/global.css",
        "@fontsource-variable/roboto",
        "./src/styles/all.min.css",
      ],
      components: {
        Search: "./src/components/Search.astro",
        Pagination: "./src/components/Pagination.astro",
      },
      sidebar: [
        {
          label: "Home",
          link: "/",
        },
        {
          label: "Getting Started",
          // Autogenerate a group of links for the 'constellations' directory.
          items: ["getting_started/about", "getting_started/contributing"],
        },
        sequencesConfig,
      ],
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

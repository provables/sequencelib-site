// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";
import { readFile } from "fs/promises";

const BASE = process.env.DOCS_BASE_URL || "/";
console.log(`Using ${BASE}`);
const info = process.env.SIDEBAR_OUTPUT || "/tmp/info_by_block.json";
const by_blocks = JSON.parse(await readFile(info, "utf8"));
const sequencesConfig = Object.entries(by_blocks)
  .sort()
  .map(([block, seqs]) => ({
    label: `${block}...`,
    link: `/${block}`,
  }));

// https://astro.build/config
export default defineConfig({
  base: BASE,
  cacheDir: ".astro",

  vite: {
    cacheDir: ".vite",
    plugins: [tailwindcss()],
    resolve: {
      preserveSymlinks: true,
    },
  },

  integrations: [
    starlight({
      title: "Sequencelib",
      pagefind: true,
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
          items: [
            "getting_started/about",
            "getting_started/contributing",
            "acknowledgments",
          ],
        },
        { label: "Sequences", collapsed: false, items: sequencesConfig },
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

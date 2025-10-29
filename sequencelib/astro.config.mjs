// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";
import { readFile } from "fs/promises";

const BASE = "/public_html/";
const info = process.env.SIDEBAR_OUTPUT || "/tmp/info_by_block.json";
const by_blocks = JSON.parse(await readFile(info, "utf8"));
const sequencesConfig = Object.entries(by_blocks)
  .sort()
  .map(([block, seqs]) => ({
    label: block,
    collapsed: true,
    items: [{ label: `Summary of block ${block}`, link: `/${block}` }].concat(
      // @ts-ignore
      seqs.sort().map((seq) => ({
        label: seq,
        link: `/${block}/${seq}`,
      }))
    ),
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

      head: [
        {
          tag: "base",
          attrs: {
            href: BASE,
          },
        },
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
          items: ["getting_started/about", "getting_started/contributing"],
        },
        { label: "Sequences", collapsed: true, items: sequencesConfig },
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

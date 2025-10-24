// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";
import { readFile } from "fs/promises";
// import { generateSequencesConfig } from './gen_sidebar.mjs';

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

// const sequencesConfig = await generateSequencesConfig(
//   "./src/content/docs/sequences"
// );

// https://astro.build/config
export default defineConfig({
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
        // {
        //   label: "Sequences",
        //   items: [
        //     {
        //       label: "A001",
        //       items: [
        //         { label: "Summary of block A001", link: "/" },
        //         { label: "A001001", link: "/A001/A001001" },
        //         { label: "A001002", link: "/A001/A001002" },
        //       ],
        //     },
        //   ],
        // },
        // TODO: collect sidebar from JSON obj instead of directory layout
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

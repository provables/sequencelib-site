// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

// https://astro.build/config
export default defineConfig({
  cacheDir: ".astro",

  vite: {
    cacheDir: ".vite",
  },

  integrations: [
    starlight({
      title: "Sequencelib",
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

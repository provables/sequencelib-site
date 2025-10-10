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
        Header: './src/components/Header.astro',
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

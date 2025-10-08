// @ts-check
import { defineConfig } from "astro/config";

// https://astro.build/config
export default defineConfig({
  cacheDir: ".astro",
  vite: {
    cacheDir: ".vite",
  },
});

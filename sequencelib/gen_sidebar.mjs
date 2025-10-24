import { readdir } from "fs/promises";
import { readFile } from "fs/promises";
import { join } from "path";

export async function generateSequencesConfig(baseDir) {
  try {
    // Read all directories in the base directory
    const entries = await readdir(baseDir, { withFileTypes: true });

    // Filter to get only directories that match the pattern A000, A001, etc.
    const sequenceDirs = entries
      .filter((entry) => entry.isDirectory() && /^A\d{3}$/.test(entry.name))
      .map((entry) => entry.name)
      .sort();

    // Build the sequences configuration
    const sequencesConfig = [];

    for (const dir of sequenceDirs) {
      const dirPath = join(baseDir, dir);

      // Read all .mdx files in this directory
      const files = await readdir(dirPath);
      const mdxFiles = files
        .filter((file) => file.endsWith(".mdx"))
        .map((file) => file.replace(".mdx", ""))
        .sort();

      // Create the configuration object for this directory
      const dirConfig = {
        label: dir,
        collapsed: true,
        items: [
          { slug: dir }, // Main index file (e.g., A000)
          ...mdxFiles
            .filter((file) => file !== dir && file !== "summary")
            .map((file) => ({ slug: `${dir}/${file}` })),
        ],
      };

      sequencesConfig.push(dirConfig);
    }

    // Return the complete Sequences section configuration
    return {
      label: "Sequences",
      items: sequencesConfig,
    };
  } catch (error) {
    console.error("Error generating sequences config:", error);
    throw error;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const info = process.env.SEQUENCELIB_BY_BLOCKS || "/tmp/info_by_block.json";
  const by_blocks = JSON.parse(await readFile(info, "utf8"));
  const sequencesConfig = Object.entries(by_blocks)
    .sort()
    .map(([block, seqs]) => ({
      label: block,
      items: [{ label: `Summary of xx block ${block}`, link: `/${block}` }].concat(
        seqs.sort().map((seq) => ({
          label: seq,
          link: `/${block}/${seq}`,
        }))
      ),
    }));
  console.log(JSON.stringify(sequencesConfig, null, 2));
}

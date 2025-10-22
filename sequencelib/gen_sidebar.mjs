import { readdir } from 'fs/promises';
import { join } from 'path';

export async function generateSequencesConfig(baseDir) {
  try {
    // Read all directories in the base directory
    const entries = await readdir(baseDir, { withFileTypes: true });
    
    // Filter to get only directories that match the pattern A000, A001, etc.
    const sequenceDirs = entries
      .filter(entry => entry.isDirectory() && /^A\d{3}$/.test(entry.name))
      .map(entry => entry.name)
      .sort();
    
    // Build the sequences configuration
    const sequencesConfig = [];
    
    for (const dir of sequenceDirs) {
      const dirPath = join(baseDir, dir);
      
      // Read all .mdx files in this directory
      const files = await readdir(dirPath);
      const mdxFiles = files
        .filter(file => file.endsWith('.mdx'))
        .map(file => file.replace('.mdx', ''))
        .sort();
      
      // Create the configuration object for this directory
      const dirConfig = {
        label: dir,
        collapsed: true,
        items: [
          { slug: dir }, // Main index file (e.g., A000)
          ...mdxFiles
            .filter(file => file !== dir && file !== "summary")
            .map(file => ({ slug: `${dir}/${file}` }))
        ]
      };
      
      sequencesConfig.push(dirConfig);
    }
    
    // Return the complete Sequences section configuration
    return {
      label: "Sequences",
      items: sequencesConfig
    };
    
  } catch (error) {
    console.error('Error generating sequences config:', error);
    throw error;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const config = await generateSequencesConfig('./src/content/docs/sequences');
  console.log(JSON.stringify(config, null, 2));
}
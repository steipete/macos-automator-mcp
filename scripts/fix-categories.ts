/**
 * Script to fix category frontmatter in knowledge base markdown files
 * 
 * This script updates the 'category' field in frontmatter to match 
 * the directory structure for all markdown files in the knowledge base.
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';

const KB_ROOT = path.join(process.cwd(), 'knowledge_base');

interface FileData {
  filePath: string;
  directoryCategory: string;
  frontmatterCategory?: string;
}

/**
 * Extract the directory category from a file path
 */
function getDirectoryCategoryFromPath(filePath: string): string {
  // Get the relative path from KB_ROOT
  const relativePath = path.relative(KB_ROOT, filePath);
  
  // Extract the top-level directory (e.g., "01_intro", "02_as_core")
  const parts = relativePath.split(path.sep);
  const topDir = parts[0];
  
  // For subcategories, include both the top directory and subdirectory
  // e.g., "08_editors/sublime_text"
  if (parts.length > 2 && !parts[1].startsWith('_') && parts[1].endsWith('.md') === false) {
    return `${topDir}/${parts[1]}`;
  }
  
  return topDir;
}

/**
 * Process a markdown file to update its category frontmatter
 */
async function processFile(file: FileData): Promise<void> {
  try {
    // Read the file
    const content = await fs.readFile(file.filePath, 'utf-8');
    
    // Parse frontmatter
    const { data, content: markdownContent } = matter(content);
    
    // Skip files with no frontmatter
    if (!data || Object.keys(data).length === 0) {
      console.log(`Skipping ${file.filePath} - No frontmatter found`);
      return;
    }
    
    // Update the category in the frontmatter
    data.category = file.directoryCategory;
    
    // Stringify the frontmatter and content back together
    const updatedContent = matter.stringify(markdownContent, data);
    
    // Write the updated content back to the file
    await fs.writeFile(file.filePath, updatedContent);
    console.log(`Updated ${file.filePath}`);
  } catch (error) {
    console.error(`Error processing ${file.filePath}:`, error);
  }
}

/**
 * Recursively find all markdown files in a directory
 */
async function findMarkdownFiles(dir: string): Promise<string[]> {
  const result: string[] = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    
    if (entry.isDirectory()) {
      const subdirFiles = await findMarkdownFiles(fullPath);
      result.push(...subdirFiles);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      result.push(fullPath);
    }
  }
  
  return result;
}

/**
 * Main function to find all markdown files and update categories
 */
async function main() {
  try {
    console.log('Finding markdown files in knowledge base...');
    const mdFiles = await findMarkdownFiles(KB_ROOT);
    
    console.log(`Found ${mdFiles.length} markdown files.`);
    
    // Collect file data
    const filesToProcess: FileData[] = [];
    
    for (const filePath of mdFiles) {
      try {
        const directoryCategory = getDirectoryCategoryFromPath(filePath);
        const content = await fs.readFile(filePath, 'utf-8');
        const { data } = matter(content);
        
        const frontmatterCategory = data.category;
        
        // If the category in frontmatter doesn't match the directory structure
        if (frontmatterCategory !== directoryCategory) {
          filesToProcess.push({
            filePath,
            directoryCategory,
            frontmatterCategory
          });
          console.log(`Category mismatch in ${filePath}:`);
          console.log(`  - Directory category: ${directoryCategory}`);
          console.log(`  - Frontmatter category: ${frontmatterCategory}`);
        }
      } catch (error) {
        console.error(`Error analyzing ${filePath}:`, error);
      }
    }
    
    console.log(`\nNeed to update ${filesToProcess.length} files.`);
    
    // Process all files
    for (const file of filesToProcess) {
      await processFile(file);
    }
    
    console.log('\nCategory update complete!');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main().catch(console.error);
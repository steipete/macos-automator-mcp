/**
 * Script to fix subdirectory categories in knowledge base markdown files
 * 
 * This script updates the 'category' field in frontmatter to only use the top-level
 * directory, removing any subdirectory components in the category value.
 */

import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';

const KB_ROOT = path.join(process.cwd(), 'knowledge_base');

interface FileData {
  filePath: string;
  currentCategory?: string;
  topLevelCategory: string;
}

/**
 * Extract the top-level directory category from a file path
 */
function getTopLevelCategoryFromPath(filePath: string): string {
  // Get the relative path from KB_ROOT
  const relativePath = path.relative(KB_ROOT, filePath);
  
  // Extract the top-level directory (e.g., "01_intro", "02_as_core")
  const parts = relativePath.split(path.sep);
  return parts[0];
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
    
    // Update the category in the frontmatter to use only the top-level directory
    data.category = file.topLevelCategory;
    
    // Stringify the frontmatter and content back together
    const updatedContent = matter.stringify(markdownContent, data);
    
    // Write the updated content back to the file
    await fs.writeFile(file.filePath, updatedContent);
    console.log(`Updated ${file.filePath}: ${file.currentCategory} → ${file.topLevelCategory}`);
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
        const topLevelCategory = getTopLevelCategoryFromPath(filePath);
        const content = await fs.readFile(filePath, 'utf-8');
        const { data } = matter(content);
        
        const currentCategory = data.category;
        
        // If the category in frontmatter includes a subdirectory (contains a /)
        if (currentCategory && typeof currentCategory === 'string' && currentCategory.includes('/')) {
          filesToProcess.push({
            filePath,
            currentCategory,
            topLevelCategory
          });
          console.log(`Subdirectory category found in ${filePath}:`);
          console.log(`  - Current category: ${currentCategory}`);
          console.log(`  - Top-level category: ${topLevelCategory}`);
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
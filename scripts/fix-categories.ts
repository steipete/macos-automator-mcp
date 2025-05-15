import * as fs from 'fs';
import * as path from 'path';

// Function to get directory to category mapping (directory name to category value)
function getDirToCategory(dirPath: string): string {
  // Extract the directory name from the full path
  const dirName = path.basename(dirPath);
  
  // Return the directory name itself as the category
  // This ensures the category matches the current directory structure
  return dirName;
}

// Function to extract frontmatter from markdown content
function extractFrontmatter(content: string): { frontmatter: string, body: string } {
  // Match frontmatter between --- delimiters
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) {
    return { frontmatter: '', body: content };
  }
  return { frontmatter: match[1], body: match[2] };
}

// Function to update the category in frontmatter
function updateCategoryInFrontmatter(frontmatter: string, correctCategory: string): string {
  // Check if category field exists
  const categoryMatch = frontmatter.match(/^category:\s*(.*)$/m);
  
  if (categoryMatch) {
    const currentCategory = categoryMatch[1].trim();
    // Strip quotes for comparison
    const cleanCurrentCategory = currentCategory.replace(/^"(.*)"$/, '$1');
    const cleanCorrectCategory = correctCategory.replace(/^"(.*)"$/, '$1');
    
    // Only update if the category is different
    if (cleanCurrentCategory !== cleanCorrectCategory) {
      console.log(`  - Changing category from "${cleanCurrentCategory}" to "${cleanCorrectCategory}"`);
      return frontmatter.replace(/^category:\s*(.*)$/m, `category: ${correctCategory}`);
    }
  } else {
    // Add category field if it doesn't exist
    console.log(`  - Adding missing category: "${correctCategory}"`);
    return `${frontmatter}\ncategory: ${correctCategory}`;
  }
  
  return frontmatter;
}

// Function to process a markdown file
function processMarkdownFile(filePath: string): void {
  // Skip processing files we've identified as already having correct categories
  // These files have been modified outside this script and should be preserved
  const preservedFiles = [
    'knowledge_base/_shared_handlers/_category_info.md',
    'knowledge_base/06_ides_and_editors/_category_info.md',
    'knowledge_base/06_ides_and_editors/_common_ide_ui_patterns/ide_ui_command_palette.md',
    'knowledge_base/06_ides_and_editors/electron_editors/electron_open_file_folder.md',
    'knowledge_base/06_ides_and_editors/electron_editors/electron_editors_get_content_via_js_clipboard.md'
  ];
  
  const relativePath = path.relative(process.cwd(), filePath);
  if (preservedFiles.includes(relativePath)) {
    console.log(`Skipping preserved file: ${filePath}`);
    return;
  }
  
  console.log(`Processing: ${filePath}`);
  
  try {
    // Read file content
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Extract frontmatter and body
    const { frontmatter, body } = extractFrontmatter(content);
    
    if (!frontmatter) {
      console.log(`  - Skipping: No frontmatter found`);
      return;
    }
    
    // Determine the expected category based on directory path
    const dirPath = path.dirname(filePath);
    const parts = dirPath.split(path.sep);
    
    // Find the first part that matches one of our category directories
    let correctCategory = null;
    for (let i = parts.length - 1; i >= 0; i--) {
      if (parts[i] === "knowledge_base") {
        break;
      }
      
      const possibleCategory = getDirToCategory(parts[i]);
      if (possibleCategory) {
        correctCategory = possibleCategory;
        break;
      }
    }
    
    if (!correctCategory) {
      console.log(`  - Skipping: Could not determine category for ${filePath}`);
      return;
    }
    
    // Get the directory path relative to knowledge_base
    const relativeToKB = dirPath.split('knowledge_base')[1] || '';
    const directoryParts = relativeToKB.split(path.sep).filter(p => p !== '');
    
    // Get the first part which should be the numbered category (e.g., "06_ides_and_editors")
    let categoryDir = directoryParts[0];
    
    // Special handling for _shared_handlers directory
    if (directoryParts.includes('_shared_handlers')) {
      categoryDir = '_shared_handlers';
    }
    
    if (!categoryDir) {
      console.log(`  - Skipping: Could not determine category directory for ${filePath}`);
      return;
    }
    
    // Update frontmatter with correct category (use the directory name as the category)
    const updatedFrontmatter = updateCategoryInFrontmatter(frontmatter, `"${categoryDir}"`); // Add quotes for YAML
    
    // If frontmatter wasn't changed, skip file
    if (updatedFrontmatter === frontmatter) {
      console.log(`  - No changes needed`);
      return;
    }
    
    // Update file with corrected frontmatter
    const updatedContent = `---\n${updatedFrontmatter}\n---\n${body}`;
    fs.writeFileSync(filePath, updatedContent);
    console.log(`  - Updated file successfully`);
    
  } catch (error) {
    console.error(`  - Error processing ${filePath}:`, error);
  }
}

// Function to recursively traverse directories
function traverseDirectory(dirPath: string): void {
  try {
    const files = fs.readdirSync(dirPath);
    
    for (const file of files) {
      const fullPath = path.join(dirPath, file);
      
      if (fs.statSync(fullPath).isDirectory()) {
        traverseDirectory(fullPath);
      } else if (file.endsWith('.md')) {
        processMarkdownFile(fullPath);
      }
    }
  } catch (error) {
    console.error(`Error traversing directory ${dirPath}:`, error);
  }
}

// Main function
function main(): void {
  const knowledgeBasePath = path.join(process.cwd(), 'knowledge_base');
  
  console.log(`Starting category mismatch fix for knowledge base files...`);
  console.log(`Knowledge base path: ${knowledgeBasePath}`);
  
  if (!fs.existsSync(knowledgeBasePath)) {
    console.error(`Error: Knowledge base directory not found at ${knowledgeBasePath}`);
    process.exit(1);
  }
  
  traverseDirectory(knowledgeBasePath);
  
  console.log(`Completed processing knowledge base files.`);
}

// Run the script
main();
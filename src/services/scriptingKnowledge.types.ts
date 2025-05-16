// src/services/scriptingKnowledge.types.ts

// Derived from knowledge_base/ subdirectory names
export type KnowledgeCategory = string;

export interface ScriptingTip {
  id: string; // Unique ID: frontmatter.id or generated (e.g., "safari_get_front_tab_url")
  category: KnowledgeCategory;
  title: string;
  description?: string;
  script: string;      // The AppleScript/JXA code block content
  language: 'applescript' | 'javascript'; // Determined from code block or frontmatter
  keywords: string[];
  notes?: string;
  filePath: string;    // Absolute path to the source .md file
  isComplex?: boolean; // Heuristic (e.g., script length) or from frontmatter
  argumentsPrompt?: string; // Human-readable prompt for arguments if run by ID
  isLocal?: boolean; // Indicates if the tip is from the local KB
  // Placeholder for future:
  // inputSchema?: any; // Optional Zod schema string or object for 'inputData' if run by ID
  // usesSharedHandlers?: string[]; // Names of handlers from shared-handlers/
}

export interface SharedHandler {
  name: string; // Filename without extension from shared-handlers/
  content: string;
  filePath: string;
  language: 'applescript' | 'javascript'; // Determined by file extension
  isLocal?: boolean; // Indicates if the handler is from the local KB
}

export interface KnowledgeBaseIndex {
  categories: {
    id: KnowledgeCategory;
    description: string; // From _category_info.md or default
    tipCount: number;
  }[];
  tips: ScriptingTip[];       // Flat list of all parsed tips
  sharedHandlers: SharedHandler[]; // Parsed shared handlers
}

// Type for parsed frontmatter from Markdown files
export interface TipFrontmatter {
  id?: string;
  title: string;
  description?: string;
  keywords?: string[];
  notes?: string;
  language?: 'applescript' | 'javascript';
  isComplex?: boolean;
  argumentsPrompt?: string;
  // usesSharedHandlers?: string[];
}

export interface CategoryInfoFrontmatter {
    description: string;
} 
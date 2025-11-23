export interface PresetJson {
  _id?: string;
  Name: string;
  Author?: string;
  Version?: string;
  Data?: Record<string, unknown>;
  [key: string]: unknown;
}

export interface ModConfig {
  modName: string;
  folderName: string;
  author: string;
  description: string;
  uuid: string;
  originalJson: string; // Keep the string version to save as file
}

export interface ParsedData {
  isValid: boolean;
  data: PresetJson | null;
  error?: string;
}

export interface ModResource {
    DisplayName: string;
    ResourceUUID: string;
    SlotName: string;
}

export interface ModDependency {
    modUUID: string;
    modName: string;
    resources: ModResource[];
}

export interface PresetDependencies {
    [modUUID: string]: {
        ModName: string;
        Resources: ModResource[];
    };
}

export interface PresetJson {
    _id?: string;
    Name: string;
    Author?: string;
    Version?: string;
    Data?: Record<string, unknown>;
    Dependencies?: PresetDependencies[];
    [key: string]: unknown;
}

export interface ModConfig {
    modName: string;
    folderName: string;
    author: string;
    description: string;
    uuid: string;
    originalJson: string; // Keep the string version to save as file
    dependencies: ModDependency[]; // Parsed dependencies from the preset
}

export interface ParsedData {
    isValid: boolean;
    data: PresetJson | null;
    error?: string;
}

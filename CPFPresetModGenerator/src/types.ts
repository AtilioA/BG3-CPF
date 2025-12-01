export interface ModResource {
    DisplayName?: string;
    ResourceUUID: string;
    SlotName: string;
}

export interface ModDependency {
    modUUID: string;
    modName: string;
    resources: ModResource[];
    checked: boolean;
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
    presets: PresetJson[]; // Array of presets to include
    dependencies: ModDependency[]; // Parsed dependencies from the preset
    includeDependencies: boolean; // Whether to include dependencies in meta.lsx
}

export interface ParsedData {
    isValid: boolean;
    data: PresetJson | null;
    error?: string;
}

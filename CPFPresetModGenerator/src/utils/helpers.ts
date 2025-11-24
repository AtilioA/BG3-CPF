import { META_LSX_TEMPLATE } from '../constants';
import { ModConfig, ModDependency, PresetDependencies } from '../types';

/**
 * Generates a random UUID v4 using the browser Crypto API.
 */
export const generateUUID = (): string => {
    if (typeof crypto !== 'undefined' && crypto.randomUUID) {
        return crypto.randomUUID();
    }
    // Fallback for older environments (unlikely needed for modern React 18, but safe)
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
};

/**
 * Sanitizes a string to be safe for folder names (alphanumeric only).
 */
export const sanitizeFolderName = (name: string): string => {
    return name.replace(/[^a-zA-Z0-9]/g, '');
};

/**
 * Generates the final folder name with CPF prefix and UUID suffix.
 * Truncates the user-provided name to 36 characters to avoid path length issues.
 */
export const getGeneratedFolderName = (folderName: string, uuid: string): string => {
    const truncatedName = folderName;
    return `CPF_${truncatedName}_${uuid}`.slice(0, 50);
};

/**
 * Parses dependencies from preset JSON structure into a normalized format.
 */
export const parseDependencies = (dependencies?: PresetDependencies[]): ModDependency[] => {
    if (!dependencies || !Array.isArray(dependencies)) {
        return [];
    }

    const result: ModDependency[] = [];

    for (const depObj of dependencies) {
        for (const [modUUID, modData] of Object.entries(depObj)) {
            result.push({
                modUUID,
                modName: modData.ModName,
                resources: modData.Resources || []
            });
        }
    }

    return result;
};

/**
 * Generates XML nodes for dependencies in meta.lsx format.
 */
export const generateDependenciesXml = (dependencies: ModDependency[]): string => {
    if (dependencies.length === 0) {
        return '';
    }

    return dependencies.map(dep => `
                        <node id="ModuleShortDesc">
                            <attribute id="Folder" type="LSString" value=""/>
                            <attribute id="MD5" type="LSString" value=""/>
                            <attribute id="Name" type="LSString" value="${dep.modName}"/>
                            <attribute id="PublishHandle" type="uint64" value="0"/>
                            <attribute id="UUID" type="guid" value="${dep.modUUID}"/>
                            <attribute id="Version64" type="int64" value="36028797018963968"/>
                        </node>`).join('');
};

/**
 * Replaces placeholders in the XML template with actual values.
 */
export const generateMetaLsx = (config: ModConfig): string => {
    let xml = META_LSX_TEMPLATE;
    xml = xml.replace('{{AUTHOR}}', config.author);
    xml = xml.replace('{{DESCRIPTION}}', config.description);
    xml = xml.replace('{{FOLDER}}', getGeneratedFolderName(config.folderName, config.uuid));
    xml = xml.replace('{{NAME}}', config.modName);
    xml = xml.replace('{{UUID}}', config.uuid);

    // Add additional mod dependencies after CPF dependency
    const additionalDeps = generateDependenciesXml(config.dependencies);
    xml = xml.replace('{{ADDITIONAL_DEPENDENCIES}}', additionalDeps);

    return xml;
};

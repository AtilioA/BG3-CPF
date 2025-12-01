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
    return name.replace(/[^_a-zA-Z0-9]/g, '');
};

/**
 * Escapes special XML characters to prevent XML parsing errors.
 * Converts: & < > " ' to their XML entity equivalents.
 */
export const escapeXml = (text: string): string => {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
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
export const parseDependencies = (presets: { Dependencies?: PresetDependencies[] }[]): ModDependency[] => {
    const dependencyMap = new Map<string, ModDependency>();

    for (const preset of presets) {
        if (!preset.Dependencies || !Array.isArray(preset.Dependencies)) {
            continue;
        }

        for (const depObj of preset.Dependencies) {
            for (const [modUUID, modData] of Object.entries(depObj)) {
                if (!dependencyMap.has(modUUID)) {
                    dependencyMap.set(modUUID, {
                        modUUID,
                        modName: modData.ModName,
                        resources: [],
                        checked: true
                    });
                }

                const existingDep = dependencyMap.get(modUUID)!;

                // Merge resources if needed
                // REVIEW: We'll add resources if they aren't already there.
                if (modData.Resources) {
                    for (const resource of modData.Resources) {
                        const exists = existingDep.resources.some(r => r.ResourceUUID === resource.ResourceUUID);
                        if (!exists) {
                            existingDep.resources.push(resource);
                        }
                    }
                }
            }
        }
    }

    return Array.from(dependencyMap.values());
};

/**
 * Generates XML nodes for dependencies in meta.lsx format.
 * Only includes dependencies that are checked.
 */
export const generateDependenciesXml = (dependencies: ModDependency[]): string => {
    const checkedDependencies = dependencies.filter(dep => dep.checked);

    if (checkedDependencies.length === 0) {
        return '';
    }

    return checkedDependencies.map(dep => `
                        <node id="ModuleShortDesc">
                            <attribute id="Folder" type="LSString" value=""/>
                            <attribute id="MD5" type="LSString" value=""/>
                            <attribute id="Name" type="LSString" value="${escapeXml(dep.modName)}"/>
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
    xml = xml.replace('{{AUTHOR}}', escapeXml(config.author));
    xml = xml.replace('{{DESCRIPTION}}', escapeXml(config.description));
    xml = xml.replace('{{FOLDER}}', escapeXml(getGeneratedFolderName(config.folderName, config.uuid)));
    xml = xml.replace('{{NAME}}', escapeXml(config.modName));
    xml = xml.replace('{{UUID}}', config.uuid);

    // Add additional mod dependencies after CPF dependency only if includeDependencies is true
    const additionalDeps = config.includeDependencies
        ? generateDependenciesXml(config.dependencies)
        : '';
    xml = xml.replace('{{ADDITIONAL_DEPENDENCIES}}', additionalDeps);

    return xml;
};

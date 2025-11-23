import { META_LSX_TEMPLATE } from '../constants';
import { ModConfig } from '../types';

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
 * Truncates the user-provided name to 50 characters to avoid path length issues.
 */
export const getGeneratedFolderName = (folderName: string, uuid: string): string => {
    const truncatedName = folderName.slice(0, 50);
    return `CPF_${truncatedName}_${uuid}`;
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
    return xml;
};

import { z } from 'zod';

export const modConfigSchema = z.object({
    modName: z.string().min(1, 'Mod name is required'),
    author: z.string().min(1, 'Author is required'),
    folderName: z.string(),
    description: z.string(),
    uuid: z.string(),
    presets: z.array(z.any()),
});

export type ModConfigErrors = {
    modName?: string;
    author?: string;
};

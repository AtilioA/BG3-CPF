import { z } from 'zod';

// UUID pattern for BG3 GUIDs
const uuidPattern = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/;

// Element schema for Data.Elements array
const elementSchema = z.object({
    Color: z.string().regex(uuidPattern, 'Invalid UUID format for Color'),
    ColorIntensity: z.number(),
    GlossyTint: z.number(),
    Material: z.string().regex(uuidPattern, 'Invalid UUID format for Material'),
    MetallicTint: z.number(),
});

// Data schema
const dataSchema = z.object({
    AdditionalChoices: z.array(z.number()).min(1, 'AdditionalChoices must have at least one item'),
    Elements: z.array(elementSchema).min(1, 'Elements must have at least one item'),
    EyeColor: z.string().regex(uuidPattern, 'Invalid UUID format for EyeColor'),
    HairColor: z.string().regex(uuidPattern, 'Invalid UUID format for HairColor'),
    SecondEyeColor: z.string().regex(uuidPattern, 'Invalid UUID format for SecondEyeColor'),
    SkinColor: z.string().regex(uuidPattern, 'Invalid UUID format for SkinColor'),
    Visuals: z.array(z.string().regex(uuidPattern, 'Invalid UUID format in Visuals')).min(1, 'Visuals must have at least one item'),
});

// Main preset schema
export const presetJsonSchema = z.object({
    _id: z.string().regex(/^[a-f0-9]{36}$/, 'Invalid _id format (must be 36 hex characters)'),
    Name: z.string().min(1, 'Name is required'),
    Author: z.string().min(1, 'Author is required'),
    Version: z.string().min(1, 'Version is required'),
    Data: dataSchema,
});

export type PresetJson = z.infer<typeof presetJsonSchema>;

import { z } from 'zod';

// UUID pattern for BG3 GUIDs
const uuidPattern = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/;

// Element schema for CCAppearance.Elements array
const elementSchema = z.object({
    Color: z.string().regex(uuidPattern, 'Invalid UUID format for Color'),
    ColorIntensity: z.number(),
    GlossyTint: z.number(),
    Material: z.string().regex(uuidPattern, 'Invalid UUID format for Material'),
    MetallicTint: z.number(),
});

// CCStats schema - Character Creation Stats
const ccStatsSchema = z.object({
    BodyShape: z.number(),
    BodyType: z.number(),
    Race: z.string().regex(uuidPattern, 'Invalid UUID format for Race'),
    SubRace: z.string().regex(uuidPattern, 'Invalid UUID format for SubRace'),
});

// CCAppearance schema - Character Creation Appearance
const ccAppearanceSchema = z.object({
    AdditionalChoices: z.array(z.number()).min(1, 'AdditionalChoices must have at least one item'),
    Elements: z.array(elementSchema).min(1, 'Elements must have at least one item'),
    EyeColor: z.string().regex(uuidPattern, 'Invalid UUID format for EyeColor'),
    HairColor: z.string().regex(uuidPattern, 'Invalid UUID format for HairColor'),
    SecondEyeColor: z.string().regex(uuidPattern, 'Invalid UUID format for SecondEyeColor'),
    SkinColor: z.string().regex(uuidPattern, 'Invalid UUID format for SkinColor'),
    Visuals: z.array(z.string().regex(uuidPattern, 'Invalid UUID format in Visuals')).min(1, 'Visuals must have at least one item'),
});

// ModResource schema
const modResourceSchema = z.object({
    DisplayName: z.string(),
    ResourceUUID: z.string().regex(uuidPattern, 'Invalid UUID format for ResourceUUID'),
    SlotName: z.string(),
});

// ModDependency schema - Record of mod UUID to mod info
const modDependencySchema = z.record(
    z.string().regex(uuidPattern, 'Invalid UUID format for mod dependency'),
    z.object({
        ModName: z.string(),
        Resources: z.array(modResourceSchema),
    })
);

// PresetData schema - Contains both stats and appearance
const presetDataSchema = z.object({
    CCStats: ccStatsSchema,
    CCAppearance: ccAppearanceSchema,
});

// Main preset schema
export const presetJsonSchema = z.object({
    _id: z.string().regex(uuidPattern, 'Invalid _id format (must be 36 hex characters)'),
    SchemaVersion: z.string(),
    Name: z.string().min(1, 'Name is required'),
    Author: z.string().min(1, 'Author is required'),
    Version: z.string().min(1, 'Version is required'),
    Data: presetDataSchema,
    Dependencies: z.array(modDependencySchema),
});

export type PresetJson = z.infer<typeof presetJsonSchema>;

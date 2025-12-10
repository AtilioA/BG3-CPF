'use client';

import React, { useState, useMemo } from 'react';
import JSZip from 'jszip';
import FileSaver from 'file-saver';
import { ModForm } from '@/components/ModForm';
import { LandingView } from '@/components/LandingView';
import { GeneratedModView } from '@/components/GeneratedModView';
import { PresetJson, ModConfig } from '@/types';
import { generateUUID, sanitizeFolderName, generateMetaLsx, getGeneratedFolderName, parseDependencies } from '@/utils/helpers';
import { Github, Info } from 'lucide-react';
import { FaDiscord, FaPatreon } from 'react-icons/fa6';
import { HELP_URL, GITHUB_URL } from '@/constants';
import { SiNexusmods } from 'react-icons/si';

export default function Home() {
    const [modConfig, setModConfig] = useState<ModConfig | null>(null);
    const [isSuccess, setIsSuccess] = useState(false);
    const currentYear = useMemo(() => new Date().getFullYear(), []);

    const handleFileLoaded = (presets: PresetJson[]) => {
        try {
            if (presets.length === 0) return;

            const firstPreset = presets[0];
            const presetName = firstPreset.Name || "Unnamed Preset";
            const author = firstPreset.Author || "Unknown";
            const allPresetNames = presets.map(p => p.Name);
            const readablePresetNames = allPresetNames.join(", ");

            // If multiple presets, append Bundle or similar to mod name
            const modName = presets.length > 1
                ? `CPF Presets Bundle (${readablePresetNames})`
                : `${presetName} - CPF Preset`;

            // Defaults logic based on requirements
            const folderName = sanitizeFolderName(allPresetNames.join("_")) || "MyPreset";
            const description = presets.length > 1
                ? `Includes ${presets.length} Character Preset Framework presets for easy import (${readablePresetNames})`
                : `Includes a Character Preset Framework preset ('${presetName}') for easy import`;

            const uuid = generateUUID();

            // Parse dependencies from all presets
            const dependencies = parseDependencies(presets);

            setModConfig({
                modName,
                folderName,
                author,
                description,
                uuid,
                presets,
                dependencies,
                includeDependencies: true
            });
            setIsSuccess(false);

        } catch (e) {
            console.error("Failed to process presets", e);
            alert("Error processing presets.");
        }
    };

    const handleGenerateRaw = async () => {
        if (!modConfig) return;

        const zip = new JSZip();

        // Structure: <ModName>/Mods/<ModName>/meta.lsx

        // We use folderName for the directory structure to ensure safety
        const generatedFolderName = getGeneratedFolderName(modConfig.folderName, modConfig.uuid);
        const rootFolder = zip.folder(generatedFolderName);

        if (rootFolder) {
            const modsFolder = rootFolder.folder("Mods");
            if (modsFolder) {
                const modSubFolder = modsFolder.folder(generatedFolderName);

                if (modSubFolder) {
                    // Generate content
                    const metaLsxContent = generateMetaLsx(modConfig);

                    // Add files
                    modSubFolder.file("meta.lsx", metaLsxContent);
                    // Always write CPF_presets.json as an array
                    modSubFolder.file(`CPF_presets.json`, JSON.stringify(modConfig.presets, null, 2));
                }
            }
        }

        try {
            const content = await zip.generateAsync({ type: "blob" });
            const saveFile = (FileSaver as any).saveAs || FileSaver;
            // Exclude UUID from the zip filename
            const zipFileName = `CPF_${modConfig.folderName}_Unpacked.zip`;
            saveFile(content, zipFileName);

            // REVIEW: Don't set success here if called from the secondary button, but if it was the main action it would.
        } catch (error) {
            console.error("Error zipping file:", error);
            alert("An error occurred while creating the zip file.");
        }
    };

    const handleGeneratePak = async () => {
        if (!modConfig) return;

        try {
            const { buildAndZipPak } = await import('@/utils/pakBuilder');

            const generatedFolderName = getGeneratedFolderName(modConfig.folderName, modConfig.uuid);
            const metaLsxContent = generateMetaLsx(modConfig);
            const presetsJson = JSON.stringify(modConfig.presets, null, 2);

            // Prepare files for packing
            const files = [
                {
                    path: `Mods/${generatedFolderName}/meta.lsx`,
                    content: metaLsxContent
                },
                {
                    path: `Mods/${generatedFolderName}/CPF_presets.json`,
                    content: presetsJson
                }
            ];

            const zipBlob = await buildAndZipPak(files, generatedFolderName);

            const saveFile = (FileSaver as any).saveAs || FileSaver;
            const zipFileName = `CPF_${modConfig.folderName}_Mod.zip`;
            saveFile(zipBlob, zipFileName);

            setIsSuccess(true);
        } catch (error) {
            console.error("Error creating pak:", error);
            alert("An error occurred while creating the pak file.");
        }
    };

    const resetApp = () => {
        setModConfig(null);
        setIsSuccess(false);
    };

    const renderContent = () => {
        if (!modConfig) {
            return <LandingView onFileLoaded={handleFileLoaded} />;
        }

        if (isSuccess) {
            return (
                <GeneratedModView
                    modConfig={modConfig}
                    onReset={resetApp}
                    onBackToDetails={() => setIsSuccess(false)}
                    onDownloadAgain={handleGeneratePak}
                    onDownloadRaw={handleGenerateRaw}
                />
            );
        }

        return (
            <ModForm
                config={modConfig}
                setConfig={setModConfig}
                onGenerate={handleGeneratePak}
                onReset={resetApp}
            />
        );
    };

    return (
        <div className="min-h-screen bg-background text-slate-100 font-sans selection:bg-primary/30 flex flex-col">

            {/* Header */}
            <header className="border-b border-slate-800 bg-slate-950/50 backdrop-blur-md sticky top-0 z-10">
                <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
                    <button onClick={resetApp} className="flex items-center gap-2 hover:opacity-80 transition-opacity" aria-label="Reset to home">
                        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-500/20">
                            P
                        </div>
                        <h1 className="text-lg font-bold tracking-tight text-white">
                            BG3 <span className="text-slate-400 font-medium">Preset Mod Generator</span>
                        </h1>
                    </button>
                    <nav className="flex items-center gap-4 text-sm text-slate-400" aria-label="External links">
                        <a href={HELP_URL} target="_blank" rel="noreferrer" className="hover:text-white transition-colors flex items-center gap-1" aria-label="View on Nexus Mods">
                            <SiNexusmods /> CPF on Nexus
                        </a>
                        <a href={GITHUB_URL} target="_blank" rel="noreferrer" className="hover:text-white transition-colors" aria-label="View on GitHub">
                            <Github className="w-5 h-5" />
                        </a>
                    </nav>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-6 py-6 md:py-10">
                {renderContent()}
            </main >

            {/* Footer */}
            <footer className="border-t border-slate-800 py-4 mt-auto bg-slate-950">
                <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-col items-center justify-center gap-1 text-slate-500 text-sm">
                    <p>Processing is done locally.</p>
                    <div className="flex flex-row items-center gap-2">
                        <p>Created by <span className='font-semibold'>Volitio</span>:</p>
                        <a
                            href="https://www.patreon.com/volitio/"
                            target="_blank"
                            rel="noreferrer"
                            className="flex flex-row items-center gap-2 text-slate-300 hover:text-white hover:bg-rose-900 transition-colors border border-slate-600 rounded-md px-2 py-1 bg-rose-900/80"
                        >
                            <FaPatreon className="w-4 h-4" />
                            <span>Support on Patreon</span>
                        </a>
                        <a
                            href="https://discord.gg/PUx3vJgapM"
                            target="_blank"
                            rel="noreferrer"
                            className="flex flex-row items-center gap-2 text-slate-300 hover:text-white  hover:bg-indigo-900 transition-colors border border-slate-600 rounded-md px-2 py-1 bg-indigo-900/80"
                        >
                            <FaDiscord className="w-4 h-4" />
                            <span>Join Discord</span>
                        </a>
                    </div>
                </div>
            </footer>
        </div >
    );
}

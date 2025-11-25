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
import { FaPatreon } from 'react-icons/fa6';
import { HELP_URL, GITHUB_URL } from '@/constants';

export default function Home() {
    const [modConfig, setModConfig] = useState<ModConfig | null>(null);
    const [isSuccess, setIsSuccess] = useState(false);
    const currentYear = useMemo(() => new Date().getFullYear(), []);

    const handleFileLoaded = (jsonContent: string) => {
        try {
            const parsed: PresetJson = JSON.parse(jsonContent);

            const modName = parsed.Name || "Unnamed Preset";
            const author = parsed.Author || "Unknown";

            // Defaults logic based on requirements
            const folderName = sanitizeFolderName(modName.replace(/\s+/g, '')) || "MyPreset";
            const description = `CPF Preset '${modName}'`;
            const uuid = generateUUID();

            // Parse dependencies from the preset
            const dependencies = parseDependencies(parsed.Dependencies);

            setModConfig({
                modName,
                folderName,
                author,
                description,
                uuid,
                originalJson: jsonContent,
                dependencies,
                includeDependencies: true
            });
            setIsSuccess(false);

        } catch (e) {
            console.error("Failed to parse JSON", e);
            alert("Invalid JSON content detected.");
        }
    };

    const handleGenerateZip = async () => {
        if (!modConfig) return;

        const zip = new JSZip();

        // Structure: <ModName>/Mods/<ModName>/meta.lsx
        // Also including the preset json for reference as requested

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
                    // Optional: Include original JSON for reference/backup
                    modSubFolder.file(`CPF_preset.json`, modConfig.originalJson);
                }
            }
        }

        try {
            const content = await zip.generateAsync({ type: "blob" });
            // Handle file-saver export structure differences (Default export vs named)
            // In many ESM environments for file-saver, the default export is the function.
            const saveFile = (FileSaver as any).saveAs || FileSaver;
            // Exclude UUID from the zip filename
            const zipFileName = `CPF_${modConfig.folderName}_Mod.zip`;
            saveFile(content, zipFileName);

            setIsSuccess(true);
        } catch (error) {
            console.error("Error zipping file:", error);
            alert("An error occurred while creating the zip file.");
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
                    onDownloadAgain={handleGenerateZip}
                />
            );
        }

        return (
            <ModForm
                config={modConfig}
                setConfig={setModConfig}
                onGenerate={handleGenerateZip}
                onReset={resetApp}
            />
        );
    };

    return (
        <div className="min-h-screen bg-background text-slate-100 font-sans selection:bg-primary/30 flex flex-col">

            {/* Header */}
            <header className="border-b border-slate-800 bg-slate-950/50 backdrop-blur-md sticky top-0 z-10">
                <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
                    <button onClick={resetApp} className="flex items-center gap-2 hover:opacity-80 transition-opacity text-left">
                        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-500/20">
                            P
                        </div>
                        <h1 className="text-lg font-bold tracking-tight text-white">
                            BG3 <span className="text-slate-400 font-medium">Preset Mod Generator</span>
                        </h1>
                    </button>
                    <div className="flex items-center gap-4 text-sm text-slate-400">
                        <a href={HELP_URL} target="_blank" rel="noreferrer" className="hover:text-white transition-colors flex items-center gap-1">
                            <Info className="w-4 h-4" /> Help
                        </a>
                        <a href={GITHUB_URL} target="_blank" rel="noreferrer" className="hover:text-white transition-colors">
                            <Github className="w-5 h-5" />
                        </a>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-6 py-6 md:py-10">
                {renderContent()}
            </main >

            {/* Footer */}
            <footer className="border-t border-slate-800 py-4 mt-auto bg-slate-950">
                <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-col items-center justify-center gap-1 text-slate-500 text-sm">
                    <p>Nothing is uploaded, processing is done locally.</p>
                    <div className="flex flex-row items-center gap-2">
                        <p>&copy; {currentYear} Volitio.</p>
                        <a
                            href="https://www.patreon.com/volitio/"
                            target="_blank"
                            rel="noreferrer"
                            className="flex flex-row items-center gap-2 hover:text-[#FF424D] transition-colors"
                        >
                            <FaPatreon className="w-4 h-4" />
                            <span>Support on Patreon</span>
                        </a>
                    </div>
                </div>
            </footer>
        </div >
    );
}

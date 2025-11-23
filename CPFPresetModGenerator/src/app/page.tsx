'use client';

import React, { useState } from 'react';
import JSZip from 'jszip';
import FileSaver from 'file-saver';
import { DropZone } from '@/components/DropZone';
import { ModForm } from '@/components/ModForm';
import { PresetJson, ModConfig } from '@/types';
import { generateUUID, sanitizeFolderName, generateMetaLsx } from '@/utils/helpers';
import { Github, Info, CheckCircle, ExternalLink, ArrowRight } from 'lucide-react';
import { HELP_URL, GITHUB_URL } from '@/constants';

export default function Home() {
    const [modConfig, setModConfig] = useState<ModConfig | null>(null);
    const [isSuccess, setIsSuccess] = useState(false);

    const handleFileLoaded = (jsonContent: string) => {
        try {
            const parsed: PresetJson = JSON.parse(jsonContent);

            const modName = parsed.Name || "Unnamed Preset";
            const author = parsed.Author || "Unknown";

            // Defaults logic based on requirements
            const folderName = sanitizeFolderName(modName.replace(/\s+/g, '')) || "MyPreset";
            const description = `CPF Preset '${modName}'`;
            const uuid = generateUUID();

            setModConfig({
                modName,
                folderName,
                author,
                description,
                uuid,
                originalJson: jsonContent
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
        const rootFolder = zip.folder(modConfig.folderName);

        if (rootFolder) {
            const modsFolder = rootFolder.folder("Mods");
            if (modsFolder) {
                const modSubFolder = modsFolder.folder(modConfig.folderName);

                if (modSubFolder) {
                    // Generate content
                    const metaLsxContent = generateMetaLsx(modConfig);

                    // Add files
                    modSubFolder.file("meta.lsx", metaLsxContent);
                    // Optional: Include original JSON for reference/backup
                    modSubFolder.file(`${modConfig.folderName}_Preset.json`, modConfig.originalJson);
                }
            }
        }

        try {
            const content = await zip.generateAsync({ type: "blob" });
            // Handle file-saver export structure differences (Default export vs named)
            // In many ESM environments for file-saver, the default export is the function.
            const saveFile = (FileSaver as any).saveAs || FileSaver;
            saveFile(content, `${modConfig.folderName}_Mod.zip`);

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

    return (
        <div className="min-h-screen bg-background text-slate-100 font-sans selection:bg-primary/30">

            {/* Header */}
            <header className="border-b border-slate-800 bg-slate-950/50 backdrop-blur-md sticky top-0 z-10">
                <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-500/20">
                            P
                        </div>
                        <h1 className="text-lg font-bold tracking-tight text-white">
                            BG3 <span className="text-slate-400 font-medium">Character Preset Generator</span>
                        </h1>
                    </div>
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

            <main className="max-w-6xl mx-auto px-6 py-12 md:py-20">
                {!modConfig ? (
                    <div className="space-y-8 animate-fade-in">
                        <div className="text-center space-y-4 mb-12">
                            <h2 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white to-slate-400 pb-2">
                                Turn CPF preset into a mod
                            </h2>
                            <p className="text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
                                This tool will automatically parse your preset to structure folders and generate a <code className="bg-slate-800 px-1.5 py-0.5 rounded text-indigo-300 text-sm">meta.lsx</code> file required for a standalone Baldur's Gate 3 mod.
                            </p>
                        </div>
                        <DropZone onFileLoaded={handleFileLoaded} />
                    </div>
                ) : isSuccess ? (
                    <div className="max-w-3xl mx-auto animate-fade-in-up">
                        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl p-8 md:p-12 text-center">
                            <div className="w-20 h-20 bg-green-500/10 rounded-full flex items-center justify-center mx-auto mb-6 ring-1 ring-green-500/50">
                                <CheckCircle className="w-10 h-10 text-green-500" />
                            </div>

                            <h2 className="text-3xl font-bold text-white mb-4">Mod Generated Successfully!</h2>
                            <p className="text-slate-400 mb-8">
                                Your <code className="text-white bg-slate-800 px-2 py-1 rounded text-sm">{modConfig.folderName}_Mod.zip</code> file has been downloaded.
                            </p>

                            <div className="bg-slate-950/50 rounded-xl p-6 border border-slate-800 text-left mb-8">
                                <h3 className="text-indigo-400 font-semibold mb-4 flex items-center gap-2">
                                    <Info className="w-5 h-5" /> Next Steps
                                </h3>
                                <ul className="space-y-4 text-sm text-slate-300">
                                    <li className="flex gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">1</span>
                                        <div>
                                            <p className="mb-1">You may now create a .pak for this mod using one of the following tools:</p>
                                            <div className="flex flex-wrap gap-4 mt-2">
                                                <a
                                                    href="https://github.com/ShinyHobo/BG3-Modders-Multitool"
                                                    target="_blank"
                                                    rel="noreferrer"
                                                    className="flex items-center gap-1 text-primary hover:text-primaryHover hover:underline"
                                                >
                                                    BG3 Modders Multitool <ExternalLink className="w-3 h-3" />
                                                </a>
                                                <span className="text-slate-600">or</span>
                                                <a
                                                    href="https://github.com/Norbyte/lslib"
                                                    target="_blank"
                                                    rel="noreferrer"
                                                    className="flex items-center gap-1 text-primary hover:text-primaryHover hover:underline"
                                                >
                                                    LSLib (Divine Tool) <ExternalLink className="w-3 h-3" />
                                                </a>
                                            </div>
                                        </div>
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">2</span>
                                        <div>
                                            <p>Once packed, your mod is ready to be shared or published on Nexus Mods.</p>
                                        </div>
                                    </li>
                                </ul>
                            </div>

                            <button
                                onClick={resetApp}
                                className="inline-flex items-center gap-2 bg-slate-800 hover:bg-slate-700 text-white px-6 py-3 rounded-lg font-medium transition-colors group"
                            >
                                Create Another Mod
                                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                            </button>

                            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-6 pt-6 border-t border-slate-800/50">
                                <button
                                    onClick={handleGenerateZip}
                                    className="text-slate-400 hover:text-white text-sm flex items-center gap-2 transition-colors"
                                >
                                    Download Again
                                </button>
                                <span className="hidden sm:block text-slate-700">•</span>
                                <button
                                    onClick={() => setIsSuccess(false)}
                                    className="text-slate-400 hover:text-white text-sm flex items-center gap-2 transition-colors"
                                >
                                    Back to Details
                                </button>
                            </div>
                        </div>
                    </div>
                ) : (
                    <ModForm
                        config={modConfig}
                        setConfig={setModConfig}
                        onGenerate={handleGenerateZip}
                        onReset={resetApp}
                    />
                )
                }
            </main >

            {/* Footer */}
            < footer className="border-t border-slate-800 py-8 mt-auto bg-slate-950" >
                <div className="max-w-6xl mx-auto px-6 text-center text-slate-500 text-sm">
                    <p>&copy; {new Date().getFullYear()} Volitio. Not affiliated with Larian Studios.</p>
                </div>
            </footer >
        </div >
    );
}

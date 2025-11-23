'use client';

import React, { useState } from 'react';
import JSZip from 'jszip';
import FileSaver from 'file-saver';
import { DropZone } from '@/components/DropZone';
import { ModForm } from '@/components/ModForm';
import { PresetJson, ModConfig } from '@/types';
import { generateUUID, sanitizeFolderName, generateMetaLsx, getGeneratedFolderName } from '@/utils/helpers';
import { Github, Info, CheckCircle, ExternalLink, ArrowRight, Download, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/Button';
import { FaPatreon } from 'react-icons/fa6';
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
                            BG3 <span className="text-slate-400 font-medium">Character Preset Generator</span>
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
                {!modConfig ? (
                    <div className="space-y-8 animate-fade-in">
                        <div className="text-center space-y-4 mb-12">
                            <h2 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white to-slate-400 pb-2">
                                Turn CPF preset into a mod
                            </h2>
                            <p className="text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
                                This tool can parse your Character Preset Framework preset JSON and automatically generate the structure for a standalone Baldur's Gate 3 mod.
                            </p>
                        </div>
                        <DropZone onFileLoaded={handleFileLoaded} />
                    </div>
                ) : isSuccess ? (
                    <div className="max-w-4xl mx-auto animate-fade-in-up">
                        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl p-8 md:p-12 text-center">
                            <div className="w-20 h-20 bg-green-500/10 rounded-full flex items-center justify-center mx-auto mb-6 ring-1 ring-green-500/50">
                                <CheckCircle className="w-10 h-10 text-green-500" />
                            </div>

                            <h2 className="text-3xl font-bold text-white mb-4">Mod generated successfully!</h2>
                            <p className="text-slate-400 mb-8">
                                Your <code className="text-white bg-slate-800 px-2 py-1 rounded text-sm">{`CPF_${modConfig.folderName}_Mod.zip`}</code> file has been downloaded.
                            </p>

                            <div className="bg-slate-950/50 rounded-xl p-6 border border-slate-800 text-left mb-8">
                                <h3 className="text-indigo-400 font-semibold mb-4 flex items-center gap-2">
                                    <Info className="w-5 h-5" /> Next steps
                                </h3>
                                <ul className="space-y-4 text-sm text-slate-300">
                                    <li className="flex gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">1</span>
                                        <p>Extract the downloaded zip file.</p>
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">2</span>
                                        <div>
                                            <p className="mb-1">You may now create a .pak for this mod using one of the following tools:</p>
                                            <div className="flex flex-wrap gap-4 mt-2">
                                                <a
                                                    href="https://github.com/ShinyHobo/BG3-Modders-Multitool/releases/latest"
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
                                                    LSLib (ConverterApp) <ExternalLink className="w-3 h-3" />
                                                </a>
                                            </div>
                                        </div>
                                    </li>
                                    <li className="flex gap-3">
                                        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">3</span>
                                        <div>
                                            <p>Once packed, your mod is ready to be shared or published on Nexus Mods.</p>
                                        </div>
                                    </li>
                                </ul>
                            </div>

                            <Button
                                onClick={resetApp}
                                variant="secondary"
                                icon={<ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />}
                                className="group"
                            >
                                Create another mod
                            </Button>

                            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-6 pt-6 border-t border-slate-800/50">
                                <Button
                                    onClick={() => setIsSuccess(false)}
                                    variant="ghost"
                                    icon={<ArrowLeft className="w-4 h-4" />}
                                    className="text-sm"
                                >
                                    Back to details
                                </Button>
                                <span className="hidden sm:block text-slate-700">•</span>
                                <Button
                                    onClick={handleGenerateZip}
                                    variant="ghost"
                                    icon={<Download className="w-4 h-4" />}
                                    className="text-sm"
                                >
                                    Download again
                                </Button>
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
            <footer className="border-t border-slate-800 py-4 mt-auto bg-slate-950">
                <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-col items-center justify-center gap-1 text-slate-500 text-sm">
                    <p>Nothing is uploaded, processing is done locally.</p>
                    <div className="flex flex-row items-center gap-2">
                        <p>&copy; {new Date().getFullYear()} Volitio.</p>
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

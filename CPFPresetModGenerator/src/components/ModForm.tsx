'use client';

import React, { useState } from 'react';
import { ModConfig } from '../types';
import { Download, RefreshCw, FileJson, Package, User, Folder } from 'lucide-react';
import { generateUUID, sanitizeFolderName } from '../utils/helpers';

interface ModFormProps {
    config: ModConfig;
    setConfig: React.Dispatch<React.SetStateAction<ModConfig | null>>;
    onGenerate: () => void;
    onReset: () => void;
}

export const ModForm: React.FC<ModFormProps> = ({ config, setConfig, onGenerate, onReset }) => {
    const [isGenerating, setIsGenerating] = useState(false);

    const handleChange = (field: keyof ModConfig, value: string) => {
        setConfig(prev => prev ? ({ ...prev, [field]: value }) : null);
    };

    const handleBlur = (field: keyof ModConfig, value: string) => {
        // Auto-sanitize folder name on blur
        if (field === 'folderName') {
            handleChange('folderName', sanitizeFolderName(value));
        }
    };

    const regenerateUUID = () => {
        handleChange('uuid', generateUUID());
    };

    const handleDownloadClick = async () => {
        setIsGenerating(true);
        // Small delay to show spinner interaction
        setTimeout(() => {
            onGenerate();
            setIsGenerating(false);
        }, 600);
    };

    return (
        <div className="w-full max-w-4xl mx-auto animate-fade-in-up">
            <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl">
                <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-900/50 backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="bg-indigo-500/20 p-2 rounded-lg">
                            <FileJson className="text-primary w-5 h-5" />
                        </div>
                        <h2 className="text-xl font-bold text-white">Configure Mod Details</h2>
                    </div>
                    <button
                        onClick={onReset}
                        className="text-xs font-medium text-slate-400 hover:text-white transition-colors uppercase tracking-wider"
                    >
                        Start Over
                    </button>
                </div>

                <div className="p-8 grid grid-cols-1 md:grid-cols-2 gap-8">
                    {/* Left Column: Core Info */}
                    <div className="space-y-6">
                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <Package className="w-4 h-4 text-primary" /> Mod Name
                            </label>
                            <input
                                type="text"
                                value={config.modName}
                                onChange={(e) => handleChange('modName', e.target.value)}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                            />
                            <p className="text-xs text-slate-500">The display name used in the mod manager.</p>
                        </div>

                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <Folder className="w-4 h-4 text-primary" /> Folder Name
                            </label>
                            <input
                                type="text"
                                value={config.folderName}
                                onBlur={(e) => handleBlur('folderName', e.target.value)}
                                onChange={(e) => handleChange('folderName', e.target.value)}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all font-mono text-sm"
                            />
                            <p className="text-xs text-slate-500">Must be alphanumeric (no spaces). Auto-sanitized.</p>
                        </div>

                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <User className="w-4 h-4 text-primary" /> Author
                            </label>
                            <input
                                type="text"
                                value={config.author}
                                onChange={(e) => handleChange('author', e.target.value)}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                            />
                        </div>
                    </div>

                    {/* Right Column: Technical & Preview */}
                    <div className="space-y-6">
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-300">Description</label>
                            <textarea
                                value={config.description}
                                onChange={(e) => handleChange('description', e.target.value)}
                                rows={3}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all resize-none"
                            />
                        </div>

                        <div className="space-y-2">
                            <div className="flex justify-between items-center">
                                <label className="text-sm font-medium text-slate-300">Generated UUID</label>
                                <button
                                    onClick={regenerateUUID}
                                    className="text-xs flex items-center gap-1 text-primary hover:text-primaryHover transition-colors"
                                >
                                    <RefreshCw className="w-3 h-3" /> Regenerate
                                </button>
                            </div>
                            <div className="w-full bg-slate-950/50 border border-slate-800 border-dashed rounded-lg px-4 py-3 text-slate-400 font-mono text-xs truncate">
                                {config.uuid}
                            </div>
                        </div>

                        <div className="pt-4">
                            <button
                                onClick={handleDownloadClick}
                                disabled={isGenerating}
                                className="w-full bg-primary hover:bg-primaryHover disabled:opacity-70 disabled:cursor-not-allowed text-white font-bold py-4 rounded-xl shadow-lg shadow-indigo-500/20 flex items-center justify-center gap-3 transition-all transform active:scale-95"
                            >
                                {isGenerating ? (
                                    <RefreshCw className="w-5 h-5 animate-spin" />
                                ) : (
                                    <Download className="w-5 h-5" />
                                )}
                                {isGenerating ? 'Packaging Mod...' : 'Generate Mod (.zip)'}
                            </button>
                            <p className="text-center text-xs text-slate-500 mt-3">
                                Generates a .zip with standard BG3 structure.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

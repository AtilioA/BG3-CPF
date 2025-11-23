'use client';

import React, { useState } from 'react';
import { ModConfig } from '../types';
import { Download, RefreshCw, FileJson, Package, User, Folder, Info, Hash, AlertCircle } from 'lucide-react';
import { generateUUID, sanitizeFolderName, getGeneratedFolderName } from '../utils/helpers';
import { modConfigSchema, ModConfigErrors } from '../schemas/modConfigSchema';

interface ModFormProps {
    config: ModConfig;
    setConfig: React.Dispatch<React.SetStateAction<ModConfig | null>>;
    onGenerate: () => void;
    onReset: () => void;
}

export const ModForm: React.FC<ModFormProps> = ({ config, setConfig, onGenerate, onReset }) => {
    const [isGenerating, setIsGenerating] = useState(false);
    const [errors, setErrors] = useState<ModConfigErrors>({});

    const handleChange = (field: keyof ModConfig, value: string) => {
        setConfig(prev => prev ? ({ ...prev, [field]: value }) : null);
        // Clear error for this field when user starts typing
        if (field === 'modName' || field === 'author') {
            setErrors(prev => ({ ...prev, [field]: undefined }));
        }
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
        // Validate before generating
        const result = modConfigSchema.safeParse(config);

        if (!result.success) {
            const fieldErrors: ModConfigErrors = {};
            result.error.issues.forEach((err) => {
                const field = err.path[0] as keyof ModConfigErrors;
                if (field === 'modName' || field === 'author') {
                    fieldErrors[field] = err.message;
                }
            });
            setErrors(fieldErrors);
            return;
        }

        setIsGenerating(true);
        // Small delay to show spinner interaction
        setTimeout(() => {
            onGenerate();
            setIsGenerating(false);
        }, 600);
    };

    return (
        <div className="w-full max-w-5xl mx-auto animate-fade-in-up">
            <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl">
                <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-900/50 backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="bg-indigo-500/20 p-2 rounded-lg">
                            <FileJson className="text-primary w-5 h-5" />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-white">Configure mod details</h2>
                            <p className="text-xs text-slate-400">These details are used to generate the meta.lsx configuration file for your mod.</p>
                        </div>
                    </div>
                    {/* <button
                        onClick={onReset}
                        className="text-xs font-medium text-slate-400 hover:text-white transition-colors uppercase tracking-wider"
                    >
                        Start over
                    </button> */}
                </div>

                <div className="p-8 grid grid-cols-1 md:grid-cols-1 gap-6">
                    {/* Left Column: Core Info */}
                    <div className="space-y-6">
                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <Package className="w-4 h-4 text-primary" /> Mod name
                            </label>
                            <input
                                type="text"
                                value={config.modName}
                                onChange={(e) => handleChange('modName', e.target.value)}
                                className={`w-full bg-slate-950 border rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all ${errors.modName ? 'border-red-500' : 'border-slate-700'
                                    }`}
                            />
                            {errors.modName && (
                                <div className="flex items-center gap-2 text-red-400 text-xs mt-1">
                                    <AlertCircle className="w-3 h-3" />
                                    <span>{errors.modName}</span>
                                </div>
                            )}
                            <p className="text-xs text-slate-500">The mod name shown in mod managers.</p>
                        </div>

                        {/* <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <Folder className="w-4 h-4 text-primary" /> Folder name
                            </label>
                            <input
                                type="text"
                                value={config.folderName}
                                onBlur={(e) => handleBlur('folderName', e.target.value)}
                                onChange={(e) => handleChange('folderName', e.target.value)}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all font-mono text-sm"
                            />
                            <p className="text-xs text-slate-500">Must be alphanumeric (no spaces). Auto-sanitized.</p>
                        </div> */}

                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <User className="w-4 h-4 text-primary" /> Author
                            </label>
                            <input
                                type="text"
                                value={config.author}
                                onChange={(e) => handleChange('author', e.target.value)}
                                className={`w-full bg-slate-950 border rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all ${errors.author ? 'border-red-500' : 'border-slate-700'
                                    }`}
                            />
                            {errors.author && (
                                <div className="flex items-center gap-2 text-red-400 text-xs mt-1">
                                    <AlertCircle className="w-3 h-3" />
                                    <span>{errors.author}</span>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Right Column: Technical & Preview */}
                    <div className="space-y-6">
                        <div className="space-y-2">
                            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                <Info className="w-4 h-4 text-primary" /> Description
                            </label>
                            <textarea
                                value={config.description}
                                onChange={(e) => handleChange('description', e.target.value)}
                                rows={2}
                                className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all resize-none"
                            />
                        </div>

                        <div className="space-y-2">
                            <div className="flex justify-between items-center">
                                <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                                    <Hash className="w-4 h-4 text-primary" /> Generated UUID</label>
                                <button
                                    onClick={regenerateUUID}
                                    className="text-xs flex items-center gap-1 text-primary hover:text-primaryHover transition-colors"
                                >
                                    <RefreshCw className="w-3 h-3" /> Regenerate
                                </button>
                            </div>
                            <div className="w-full bg-slate-950/50 border border-slate-800 border-dashed rounded-lg px-4 py-3 text-slate-400 font-mono text-xs truncate cursor-default">
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
                                {isGenerating ? 'Packaging mod...' : 'Generate mod (.zip)'}
                            </button>
                            <p className="text-center text-xs text-slate-500 mt-3">
                                Generates a .zip with standard BG3 structure ready for packaging.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

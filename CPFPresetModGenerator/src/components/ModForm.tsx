'use client';

import React, { useState, useEffect, useRef } from 'react';
import { ModConfig } from '../types';
import { Download, RefreshCw, FileJson, Package, User, Info, Hash } from 'lucide-react';
import { generateUUID, sanitizeFolderName } from '../utils/helpers';
import { modConfigSchema, ModConfigErrors } from '../schemas/modConfigSchema';
import { FormField } from './FormField';
import { DependencyList } from './DependencyList';

interface ModFormProps {
    config: ModConfig;
    setConfig: React.Dispatch<React.SetStateAction<ModConfig | null>>;
    onGenerate: () => void;
    onReset: () => void;
}

export const ModForm: React.FC<ModFormProps> = ({ config, setConfig, onGenerate, onReset }) => {
    const [isGenerating, setIsGenerating] = useState(false);
    const [errors, setErrors] = useState<ModConfigErrors>({});
    const timeoutRef = useRef<NodeJS.Timeout | null>(null);

    // Cleanup timeout on unmount
    useEffect(() => {
        return () => {
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
                timeoutRef.current = null;
            }
        };
    }, []);

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

    const handleToggleIncludeDependencies = (include: boolean) => {
        setConfig(prev => prev ? ({ ...prev, includeDependencies: include }) : null);
    };

    const handleToggleDependency = (modUUID: string, checked: boolean) => {
        setConfig(prev => {
            if (!prev) return null;
            return {
                ...prev,
                dependencies: prev.dependencies.map(dep =>
                    dep.modUUID === modUUID ? { ...dep, checked } : dep
                )
            };
        });
    };

    const handleDownloadClick = async () => {
        // Validate before generating
        const result = modConfigSchema.safeParse(config);

        if (!result.success) {
            const fieldErrors: ModConfigErrors = {};
            console.log(result.error)
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

        // Clear any existing timeout
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
        }

        // Small delay to show spinner interaction
        timeoutRef.current = setTimeout(() => {
            onGenerate();
            setIsGenerating(false);
            timeoutRef.current = null; // Clear ref after timeout completes
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
                            <p className="text-xs text-slate-400">These details are used to generate the metadata file for your mod.</p>
                            <p className="text-xs text-slate-300">Default values work perfectly.</p>
                        </div>
                    </div>
                </div>

                <div className="p-6 grid grid-cols-1 md:grid-cols-1 gap-6">
                    {/* Left Column: Core Info */}
                    <div className="space-y-3">
                        <FormField
                            label="Mod name"
                            icon={Package}
                            value={config.modName}
                            onChange={(value) => handleChange('modName', value)}
                            error={errors.modName}
                            helperText="The mod name shown in mod managers."
                        />

                        <FormField
                            label="Author"
                            icon={User}
                            value={config.author}
                            onChange={(value) => handleChange('author', value)}
                            error={errors.author}
                        />
                    </div>

                    {/* Right Column: Technical & Preview */}
                    <div className="space-y-3">
                        <FormField
                            label="Description"
                            icon={Info}
                            type="textarea"
                            value={config.description}
                            onChange={(value) => handleChange('description', value)}
                            rows={2}
                        />

                        {/* <div className="space-y-2">
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
                        </div> */}

                        {/* Dependency List */}
                        <DependencyList
                            dependencies={config.dependencies}
                            includeDependencies={config.includeDependencies}
                            onToggleInclude={handleToggleIncludeDependencies}
                            onToggleDependency={handleToggleDependency}
                        />

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
                                {isGenerating ? 'Generating folder structure...' : 'Generate mod (.zip)'}
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

'use client';

import React, { useCallback, useState, useRef, useEffect } from 'react';
import { Upload, AlertCircle, FileJson } from 'lucide-react';
import { presetJsonSchema } from '../schemas/presetJsonSchema';

import * as Sentry from '@sentry/nextjs';

interface DropZoneProps {
    onFileLoaded: (presets: any[]) => void;
}

export const DropZone: React.FC<DropZoneProps> = ({ onFileLoaded }) => {
    const [isDragging, setIsDragging] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const isMountedRef = useRef(true);

    // Cleanup on unmount
    useEffect(() => {
        isMountedRef.current = true;

        return () => {
            isMountedRef.current = false;
        };
    }, []);

    const handleDragEnter = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(true);
    }, []);

    const handleDragLeave = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();

        // Only cancel dragging if we're actually leaving the container
        // relatedTarget is the element we're entering
        if (e.currentTarget.contains(e.relatedTarget as Node)) {
            return;
        }

        setIsDragging(false);
    }, []);

    const handleDragOver = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
    }, []);

    const processFiles = async (files: FileList | File[]) => {
        if (files.length === 0) return;

        // if (files.length > 20) {
        //     setError("You can only upload up to 20 files at once.");
        //     return;
        // }

        const loadedPresets: any[] = [];
        let hasError = false;

        // Process each file
        for (let i = 0; i < files.length; i++) {
            const file = files[i];

            if (file.type !== "application/json" && !file.name.endsWith('.json')) {
                setError(`File '${file.name}' is not a valid JSON file.`);
                hasError = true;
                break;
            }

            try {
                const text = await file.text();
                const parsed = JSON.parse(text);

                // Check if it's a single preset or array of presets
                if (Array.isArray(parsed)) {
                    // Validate each item in array
                    for (const item of parsed) {
                        const validation = presetJsonSchema.safeParse(item);
                        if (!validation.success) {
                            const firstError = validation.error.issues[0];
                            setError(`Invalid preset in '${file.name}': ${firstError.path.join('.')} - ${firstError.message}`);
                            hasError = true;
                            break;
                        }
                        loadedPresets.push(item);
                    }
                } else {
                    // Validate single preset
                    const validation = presetJsonSchema.safeParse(parsed);
                    if (!validation.success) {
                        const firstError = validation.error.issues[0];
                        setError(`Invalid preset in '${file.name}': ${firstError.path.join('.')} - ${firstError.message}`);
                        hasError = true;
                        break;
                    }
                    loadedPresets.push(parsed);
                }

                if (hasError) break;

            } catch (err) {
                setError(`Failed to parse '${file.name}': Invalid JSON format.`);
                Sentry.captureException(err);
                hasError = true;
                break;
            }
        }

        if (!hasError && isMountedRef.current) {
            if (loadedPresets.length === 0) {
                setError("No valid presets found in the uploaded files.");
            } else {
                onFileLoaded(loadedPresets);
                setError(null);
            }
        }
    };

    const handleDrop = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);

        if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
            processFiles(e.dataTransfer.files);
        }
    }, [onFileLoaded]);

    const handlePaste = useCallback((e: React.ClipboardEvent) => {
        const text = e.clipboardData.getData('text');
        if (text) {
            try {
                const parsed = JSON.parse(text);
                if (Array.isArray(parsed)) {
                    // Handle array paste
                    const loadedPresets: any[] = [];
                    for (const item of parsed) {
                        const validation = presetJsonSchema.safeParse(item);
                        if (!validation.success) {
                            const firstError = validation.error.issues[0];
                            setError(`Invalid preset in pasted content: ${firstError.path.join('.')} - ${firstError.message}`);
                            return;
                        }
                        loadedPresets.push(item);
                    }
                    onFileLoaded(loadedPresets);
                } else {
                    const validation = presetJsonSchema.safeParse(parsed);

                    if (!validation.success) {
                        const firstError = validation.error.issues[0];
                        const errorMessage = `Invalid preset: ${firstError.path.join('.')} - ${firstError.message}`;
                        setError(errorMessage);
                        Sentry.captureException(new Error(errorMessage), {
                            extra: {
                                validationError: validation.error,
                            }
                        });
                        return;
                    }

                    onFileLoaded([parsed]);
                }

                setError(null);
            } catch (err) {
                setError("Pasted text is not valid JSON.");
                Sentry.captureException(err);
            }
        }
    }, [onFileLoaded]);

    const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files.length > 0) {
            processFiles(e.target.files);
        }
        // Reset input so same file can be selected again if needed
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const handleZoneClick = () => {
        fileInputRef.current?.click();
    };

    const handleTextAreaClick = (e: React.MouseEvent) => {
        // Prevent the click from bubbling up to the zone click handler
        e.stopPropagation();
    };

    return (
        <div className="w-full max-w-3xl mx-auto">
            <div
                onClick={handleZoneClick}
                onDragEnter={handleDragEnter}
                onDragLeave={handleDragLeave}
                onDragOver={handleDragOver}
                onDrop={handleDrop}
                className={`
          relative border-2 border-dashed rounded-xl p-10 transition-all duration-300 ease-in-out
          flex flex-col items-center justify-center text-center cursor-pointer group
          ${isDragging
                        ? 'border-primary bg-primary/10 shadow-[0_0_30px_rgba(99,102,241,0.2)]'
                        : 'border-slate-700 bg-slate-900 hover:border-slate-500 hover:bg-slate-800/50'
                    }
        `}
            >
                <input
                    type="file"
                    accept=".json"
                    multiple
                    className="hidden"
                    ref={fileInputRef}
                    onChange={handleFileInput}
                />

                <div className="mb-2 p-4 rounded-full bg-slate-800 group-hover:bg-slate-700 transition-colors">
                    <Upload className={`w-10 h-10 ${isDragging ? 'text-primary' : 'text-slate-400'}`} />
                </div>

                <h3 className="text-xl font-semibold text-white mb-2">
                    Drop 1 or more preset JSONs here
                </h3>
                {/* <p className="text-slate-500 mb-6 text-xs">
                    click anywhere to browse
                </p> */}

                <div className="w-full max-w-lg flex flex-col items-center gap-4 mt-6">
                    <div className="flex items-center w-full gap-3">
                        <div className="h-px bg-slate-700 flex-1"></div>
                        <span className="text-slate-400 text-xs uppercase font-medium tracking-wider">Or paste JSON content</span>
                        <div className="h-px bg-slate-700 flex-1"></div>
                    </div>

                    <div className="w-full relative">
                        <textarea
                            rows={5}
                            placeholder="Paste preset JSON contents here..."
                            onPaste={handlePaste}
                            onClick={handleTextAreaClick}
                            className="w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 text-sm text-slate-300 font-mono focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all resize-y placeholder:text-slate-500"
                        />
                        {/* <div className="absolute right-3 top-3 text-slate-600 pointer-events-none">
                            <FileJson className="w-4 h-4" />
                        </div> */}
                    </div>
                </div>

                {error && (
                    <div className="mt-6 flex items-center gap-2 text-red-400 bg-red-950/30 px-4 py-2 rounded-lg text-sm border border-red-900/50 animate-fade-in">
                        <AlertCircle className="w-4 h-4" />
                        <span>{error}</span>
                    </div>
                )}
            </div>
        </div>
    );
};

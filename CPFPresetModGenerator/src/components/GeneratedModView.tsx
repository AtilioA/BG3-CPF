import React from 'react';
import { CheckCircle, ArrowRight, ArrowLeft, Download, FileJson } from 'lucide-react';
import { Button } from './Button';
import { NextSteps } from './NextSteps';
import { ModConfig } from '@/types';

interface GeneratedModViewProps {
    modConfig: ModConfig;
    onReset: () => void;
    onBackToDetails: () => void;
    onDownloadAgain: () => void;
    onDownloadRaw: () => void;
}

export const GeneratedModView: React.FC<GeneratedModViewProps> = ({
    modConfig,
    onReset,
    onBackToDetails,
    onDownloadAgain,
    onDownloadRaw
}) => {
    return (
        <div className="max-w-xl animate-fade-in-up">
            <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-2xl p-8 md:p-12 text-center">
                <div className="w-20 h-20 bg-green-500/10 rounded-full flex items-center justify-center mx-auto mb-6 ring-1 ring-green-500/50">
                    <CheckCircle className="w-10 h-10 text-green-500" />
                </div>

                <h2 className="text-3xl font-bold text-white mb-4">Structure generated successfully!</h2>
                <p className="text-slate-400 mb-8">
                    Your <code className="text-white bg-slate-800 px-2 py-1 rounded text-sm">{`CPF_${modConfig.folderName}_Mod.zip`}</code> file has been downloaded.
                </p>

                <NextSteps />

                <Button
                    onClick={onReset}
                    variant="secondary"
                    icon={<ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />}
                    className="group mt-8"
                >
                    Create another mod
                </Button>

                <div className="flex flex-col sm:flex-row items-center justify-center gap-2 mt-6 pt-6 border-t border-slate-800/50">
                    <Button
                        onClick={onBackToDetails}
                        variant="ghost"
                        icon={<ArrowLeft className="w-4 h-4" />}
                        className="text-sm"
                    >
                        Back to details
                    </Button>
                    <span className="hidden sm:block text-slate-700">•</span>
                    <Button
                        onClick={onDownloadAgain}
                        variant="ghost"
                        icon={<Download className="w-4 h-4" />}
                        className="text-sm opacity-75 hover:opacity-100"
                    >
                        Download mod again
                    </Button>
                    <span className="hidden sm:block text-slate-700">•</span>
                    <Button
                        onClick={onDownloadRaw}
                        variant="ghost"
                        icon={<FileJson className="w-4 h-4" />}
                        className="text-sm opacity-50 hover:opacity-100"
                        title="Download raw files (Legacy)"
                    >
                        Download unpacked mod
                    </Button>
                </div>
            </div>
        </div>
    );
};

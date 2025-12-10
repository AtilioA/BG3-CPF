import React, { useState } from 'react';
import { DropZone } from './DropZone';
import { FolderOpen, Copy, Check } from 'lucide-react';
import { FaWindows } from 'react-icons/fa6';

interface LandingViewProps {
    onFileLoaded: (presets: any[]) => void;
}

export const LandingView: React.FC<LandingViewProps> = ({ onFileLoaded }) => {
    const [copied, setCopied] = useState(false);
    const command = `explorer %LocalAppData%\\Larian Studios\\Baldur's Gate 3\\Script Extender\\CPF`;

    const handleCopy = () => {
        navigator.clipboard.writeText(command);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div className="space-y-8 animate-fade-in">
            <div className="text-center space-y-4 mb-12">
                <h2 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white to-slate-400 pb-2">
                    Turn any CPF preset into a mod
                </h2>
                <p className="text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
                    This website can parse one or more Character Preset Framework preset JSON files and automatically generate the zipped pak file for a standalone Baldur's Gate 3 mod.
                </p>
            </div>
            <DropZone onFileLoaded={onFileLoaded} />

            <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-6 max-w-3xl mx-auto mt-12 text-left shadow-lg">
                <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                    <FolderOpen className="w-5 h-5 text-blue-400" />
                    How to find your presets
                </h3>
                <div className="space-y-4 text-slate-300">
                    <ol className="list-decimal list-inside space-y-3 ml-1 text-sm text-slate-400">
                        <li>
                            Press <kbd className="px-2 py-1 bg-slate-700 rounded text-xs font-mono text-slate-200 border border-slate-600 shadow-sm inline-flex items-center gap-1.5 align-middle">
                                <FaWindows />
                                <span>Win + R</span>
                            </kbd>
                        </li>
                        <li>
                            Paste and run the following command:
                            <div className="bg-slate-950 p-3 rounded-lg font-mono text-xs text-slate-300 border border-slate-800 mt-2 shadow-inner flex items-center justify-between gap-2 group">
                                <span className="break-all select-all">{command}</span>
                                <button
                                    onClick={handleCopy}
                                    className="p-1.5 hover:bg-slate-800 rounded-md transition-colors text-slate-400 hover:text-white flex-shrink-0"
                                    title="Copy to clipboard"
                                >
                                    {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
                                </button>
                            </div>
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    );
};

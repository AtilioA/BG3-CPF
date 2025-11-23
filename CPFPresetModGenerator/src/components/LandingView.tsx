import React from 'react';
import { DropZone } from './DropZone';

interface LandingViewProps {
    onFileLoaded: (jsonContent: string) => void;
}

export const LandingView: React.FC<LandingViewProps> = ({ onFileLoaded }) => {
    return (
        <div className="space-y-8 animate-fade-in">
            <div className="text-center space-y-4 mb-12">
                <h2 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white to-slate-400 pb-2">
                    Turn CPF preset into a mod
                </h2>
                <p className="text-lg text-slate-400 max-w-2xl mx-auto leading-relaxed">
                    This website can parse your Character Preset Framework preset JSON and automatically generate the structure for a standalone Baldur's Gate 3 mod.
                </p>
            </div>
            <DropZone onFileLoaded={onFileLoaded} />
        </div>
    );
};

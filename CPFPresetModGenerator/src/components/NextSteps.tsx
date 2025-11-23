import React from 'react';
import { ExternalLink } from './ExternalLink';

interface StepProps {
    number: number;
    children: React.ReactNode;
}

const Step: React.FC<StepProps> = ({ number, children }) => (
    <li className="flex gap-3">
        <span className="flex-shrink-0 w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 text-xs font-bold border border-slate-700">
            {number}
        </span>
        <div className="flex-1 text-sm text-slate-300">{children}</div>
    </li>
);

export const NextSteps: React.FC = () => {
    return (
        <div className="bg-slate-950/50 rounded-xl p-6 border border-slate-800 text-left">
            <h3 className="text-indigo-400 font-semibold mb-4 text-base">Next steps</h3>
            <ul className="space-y-4">
                <Step number={1}>
                    Extract the downloaded zip file.
                </Step>

                <Step number={2}>
                    <p className="mb-2">Create a .pak file using one of these tools:</p>
                    <div className="flex flex-wrap gap-3 items-center">
                        <ExternalLink href="https://github.com/ShinyHobo/BG3-Modders-Multitool/releases/latest">
                            BG3 Modders Multitool
                        </ExternalLink>
                        <span className="text-slate-600">or</span>
                        <ExternalLink href="https://github.com/Norbyte/lslib">
                            LSLib (ConverterApp)
                        </ExternalLink>
                    </div>
                </Step>

                <Step number={3}>
                    <div className="flex flex-wrap gap-3 items-center">
                        Your mod is ready to be shared on
                        <ExternalLink href="https://www.nexusmods.com/baldursgate3">Nexus Mods</ExternalLink>
                    </div>
                </Step>
            </ul>
        </div>
    );
};

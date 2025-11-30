import React, { useState } from 'react';
import { ChevronDown, ChevronRight, Package } from 'lucide-react';
import { ModDependency } from '@/types';
import { Checkbox } from './Checkbox';

interface DependencyListProps {
    dependencies: ModDependency[];
    includeDependencies: boolean;
    onToggleInclude: (include: boolean) => void;
}

export const DependencyList: React.FC<DependencyListProps> = ({
    dependencies,
    includeDependencies,
    onToggleInclude
}) => {
    const [isExpanded, setIsExpanded] = useState(false);

    if (dependencies.length === 0) {
        return null;
    }

    return (
        <div className="bg-slate-950/50 rounded-xl p-6 border border-slate-800">
            <Checkbox
                checked={includeDependencies}
                onChange={onToggleInclude}
                label={
                    <div className="flex items-center gap-2">
                        <Package className="w-4 h-4 text-indigo-400" />
                        Include mod dependencies in meta.lsx
                    </div>
                }
                description="This prevents players from missing dependencies."
                className="mb-2"
            />

            {/* Accordion for dependency list */}
            <button
                onClick={() => setIsExpanded(!isExpanded)}
                className="w-full flex items-center justify-between text-sm text-slate-400 hover:text-slate-300 transition-colors py-2 px-3 rounded-lg hover:bg-slate-800/50"
            >
                <span className="flex items-center gap-2">
                    {isExpanded ? (
                        <ChevronDown className="w-4 h-4" />
                    ) : (
                        <ChevronRight className="w-4 h-4" />
                    )}
                    {isExpanded ? 'Hide' : 'Show'} resources from {dependencies.length} mod{dependencies.length !== 1 ? 's' : ''}
                </span>
                {/* <span className="text-xs text-slate-500">
                    {dependencies.length} mod{dependencies.length !== 1 ? 's' : ''}
                </span> */}
            </button>

            {/* Collapsible dependency list */}
            {isExpanded && (
                <div className="mt-3 pt-3 border-t border-slate-700/50 animate-fade-in">
                    <ul className="space-y-3">
                        {dependencies.map((dep) => (
                            <li key={dep.modUUID} className="group relative">
                                <div className="flex items-start gap-3">
                                    <span className="flex-shrink-0 text-slate-500 text-sm">•</span>
                                    <div className="flex-1">
                                        <span
                                            className="text-indigo-300 hover:text-indigo-200 cursor-help transition-colors text-sm font-medium"
                                            title={`Resources: ${dep.resources.map(r => `${r.DisplayName ?? 'Unknown'} (${r.SlotName})`).join(', ')}`}
                                        >
                                            {dep.modName}
                                        </span>
                                        {dep.resources.length > 0 && (
                                            <span className="ml-2 text-xs text-slate-500">
                                                ({dep.resources.length} resource{dep.resources.length !== 1 ? 's' : ''})
                                            </span>
                                        )}

                                        {/* Tooltip on hover */}
                                        <div className="absolute left-8 top-full mt-1 hidden group-hover:block z-10 bg-slate-800 border border-slate-700 rounded-lg p-3 shadow-xl min-w-[250px] max-w-[400px]">
                                            <p className="text-xs font-semibold text-indigo-300 mb-2">Resources from this mod:</p>
                                            <ul className="space-y-1 text-xs text-slate-300">
                                                {dep.resources.filter(r => r.DisplayName).map((resource, idx) => (
                                                    <li key={idx} className="flex items-start gap-2">
                                                        <span className="text-slate-500 flex-shrink-0">→</span>
                                                        <div>
                                                            <div className="font-medium">{resource.DisplayName}</div>
                                                            <div className="text-slate-400">Slot: {resource.SlotName}</div>
                                                        </div>
                                                    </li>
                                                ))}
                                            </ul>
                                        </div>
                                    </div>
                                </div>
                            </li>
                        ))}
                    </ul>
                </div>
            )}
        </div >
    );
};

import React, { useState } from 'react';
import { Package, ChevronDown, ChevronRight } from 'lucide-react';
import { ModDependency } from '@/types';

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
            <div className="flex items-start gap-3 mb-4">
                <input
                    type="checkbox"
                    id="includeDependencies"
                    checked={includeDependencies}
                    onChange={(e) => onToggleInclude(e.target.checked)}
                    className="mt-1 w-4 h-4 rounded border-slate-700 bg-slate-900 text-primary focus:ring-primary focus:ring-offset-0 cursor-pointer"
                />
                <div className="flex-1">
                    <label
                        htmlFor="includeDependencies"
                        className="text-sm font-medium text-slate-300 cursor-pointer flex items-center gap-2"
                    >
                        <Package className="w-4 h-4 text-indigo-400" />
                        Include mod dependencies in meta.lsx
                    </label>
                    <p className="text-xs text-slate-400 mt-1">
                        This preset uses resources from {dependencies.length} mod{dependencies.length !== 1 ? 's' : ''}
                    </p>
                </div>
            </div>

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
                    {isExpanded ? 'Hide' : 'Show'} dependency details
                </span>
                <span className="text-xs text-slate-500">
                    {dependencies.length} mod{dependencies.length !== 1 ? 's' : ''}
                </span>
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
                                            title={`Resources: ${dep.resources.map(r => `${r.DisplayName} (${r.SlotName})`).join(', ')}`}
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
                                                {dep.resources.map((resource, idx) => (
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

            {includeDependencies && (
                <p className="text-xs text-slate-500 mt-4 pt-4 border-t border-slate-700/50">
                    💡 Dependencies will be included in the generated meta.lsx file
                </p>
            )}
        </div>
    );
};

import React from 'react';
import { Check } from 'lucide-react';

interface CheckboxProps {
    checked: boolean;
    onChange: (checked: boolean) => void;
    label?: React.ReactNode;
    description?: string;
    className?: string;
    disabled?: boolean;
}

export const Checkbox: React.FC<CheckboxProps> = ({
    checked,
    onChange,
    label,
    description,
    className = '',
    disabled = false
}) => {
    return (
        <div className={`flex items-start gap-3 ${className}`}>
            <div className="relative flex items-center">
                <input
                    type="checkbox"
                    className="peer sr-only"
                    checked={checked}
                    onChange={(e) => onChange(e.target.checked)}
                    disabled={disabled}
                />
                <div
                    onClick={() => !disabled && onChange(!checked)}
                    className={`
                        w-5 h-5 rounded-md border transition-all duration-200 cursor-pointer flex items-center justify-center
                        ${checked
                            ? 'bg-indigo-500 border-indigo-500 text-white shadow-lg shadow-indigo-500/25'
                            : 'bg-slate-900 border-slate-700 hover:border-slate-600'
                        }
                        ${disabled ? 'opacity-50 cursor-not-allowed' : ''}
                    `}
                >
                    <Check
                        className={`w-3.5 h-3.5 transition-transform duration-200 ${checked ? 'scale-100' : 'scale-0'
                            }`}
                        strokeWidth={3}
                    />
                </div>
            </div>
            {(label || description) && (
                <div
                    className={`flex-1 ${!disabled ? 'cursor-pointer' : ''}`}
                    onClick={() => !disabled && onChange(!checked)}
                >
                    {label && (
                        <div className={`text-sm font-medium select-none ${disabled ? 'text-slate-500' : 'text-slate-300'}`}>
                            {label}
                        </div>
                    )}
                    {description && (
                        <p className="text-xs text-slate-400 mt-0.5 select-none">
                            {description}
                        </p>
                    )}
                </div>
            )}
        </div>
    );
};

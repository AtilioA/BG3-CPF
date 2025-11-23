import React from 'react';
import { AlertCircle, LucideIcon } from 'lucide-react';

interface FormFieldProps {
    label: string;
    icon?: LucideIcon;
    type?: 'text' | 'textarea';
    value: string;
    onChange: (value: string) => void;
    onBlur?: (value: string) => void;
    error?: string;
    helperText?: string;
    rows?: number;
    className?: string;
    inputClassName?: string;
}

export const FormField: React.FC<FormFieldProps> = ({
    label,
    icon: Icon,
    type = 'text',
    value,
    onChange,
    onBlur,
    error,
    helperText,
    rows = 2,
    className = '',
    inputClassName = ''
}) => {
    const baseInputStyles = "w-full bg-slate-950 border rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all";
    const errorStyles = error ? 'border-red-500' : 'border-slate-700';

    return (
        <div className={`space-y-2 ${className}`}>
            <label className="flex items-center gap-2 text-sm font-medium text-slate-300">
                {Icon && <Icon className="w-4 h-4 text-primary" />}
                {label}
            </label>

            {type === 'textarea' ? (
                <textarea
                    value={value}
                    onChange={(e) => onChange(e.target.value)}
                    onBlur={onBlur ? (e) => onBlur(e.target.value) : undefined}
                    rows={rows}
                    className={`${baseInputStyles} ${errorStyles} resize-none ${inputClassName}`}
                />
            ) : (
                <input
                    type="text"
                    value={value}
                    onChange={(e) => onChange(e.target.value)}
                    onBlur={onBlur ? (e) => onBlur(e.target.value) : undefined}
                    className={`${baseInputStyles} ${errorStyles} ${inputClassName}`}
                />
            )}

            {error && (
                <div className="flex items-center gap-2 text-red-400 text-xs mt-1">
                    <AlertCircle className="w-3 h-3" />
                    <span>{error}</span>
                </div>
            )}

            {helperText && !error && (
                <p className="text-xs text-slate-500">{helperText}</p>
            )}
        </div>
    );
};

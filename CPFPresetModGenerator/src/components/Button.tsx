import React from 'react';
import { Loader2 } from 'lucide-react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: 'primary' | 'secondary' | 'ghost' | 'outline';
    isLoading?: boolean;
    icon?: React.ReactNode;
    children: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
    variant = 'primary',
    isLoading = false,
    icon,
    children,
    className = '',
    disabled,
    ...props
}) => {
    const baseStyles = "inline-flex items-center justify-center gap-2 rounded-lg font-medium transition-all active:scale-95 disabled:opacity-70 disabled:cursor-not-allowed disabled:active:scale-100";

    const variants = {
        primary: "bg-primary hover:bg-primaryHover text-white shadow-lg shadow-indigo-500/20",
        secondary: "bg-slate-800 hover:bg-slate-700 text-white",
        ghost: "text-slate-400 hover:text-white hover:bg-slate-800/50",
        outline: "border border-slate-700 text-slate-300 hover:text-white hover:border-slate-500 hover:bg-slate-800/50"
    };

    const sizes = "px-6 py-3";

    return (
        <button
            className={`${baseStyles} ${variants[variant]} ${sizes} ${className}`}
            disabled={isLoading || disabled}
            {...props}
        >
            {isLoading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
            ) : icon ? (
                <span className="flex-shrink-0">{icon}</span>
            ) : null}
            {children}
        </button>
    );
};

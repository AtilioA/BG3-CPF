'use client';

// REFACTOR: use sonner instead

import React from 'react';

interface ToastProps {
    isVisible: boolean;
    mainIcon: React.ReactNode;
    title: string;
    message: string;
    className?: string;
    variant?: 'default' | 'success' | 'warning' | 'error';
}

export function Toast({
    isVisible,
    mainIcon,
    title,
    message,
    className = '',
    variant = 'default',
}: ToastProps) {
    if (!isVisible) {
        return null;
    }

    // Base styles
    const baseStyles = "fixed bottom-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg backdrop-blur-md transition-all duration-300";

    // Variant styles
    let variantStyles = "";
    switch (variant) {
        case 'success':
            variantStyles = "bg-green-900/90 border border-green-700";
            break;
        case 'warning':
            variantStyles = "bg-orange-900/90 border border-orange-700";
            break;
        case 'error':
            variantStyles = "bg-red-900/90 border border-red-700";
            break;
        case 'default':
        default:
            variantStyles = "bg-slate-900/90 border border-slate-700";
            break;
    }

    return (
        <div
            className={`${baseStyles} ${variantStyles} ${className}`}
            role="status"
            aria-live="polite"
        >
            <div className="flex items-center gap-3">
                {mainIcon}
                <div className="flex flex-col">
                    <span className="font-semibold text-sm text-white">
                        {title}
                    </span>
                    <span className="text-xs text-slate-300">
                        {message}
                    </span>
                </div>
            </div>
        </div>
    );
}

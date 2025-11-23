import React from 'react';
import { ExternalLink as ExternalLinkIcon } from 'lucide-react';

interface ExternalLinkProps {
    href: string;
    children: React.ReactNode;
    icon?: React.ReactNode;
    className?: string;
    showExternalIcon?: boolean;
}

export const ExternalLink: React.FC<ExternalLinkProps> = ({
    href,
    children,
    icon,
    className = '',
    showExternalIcon = true
}) => {
    return (
        <a
            href={href}
            target="_blank"
            rel="noreferrer"
            className={`flex items-center gap-1 text-primary hover:text-primaryHover hover:underline transition-colors ${className}`}
        >
            {icon}
            {children}
            {showExternalIcon && <ExternalLinkIcon className="w-3 h-3" />}
        </a>
    );
};

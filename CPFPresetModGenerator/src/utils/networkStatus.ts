import { useState, useEffect } from 'react';

/**
 * Check if the browser is currently online
 */
export function isOnline(): boolean {
    if (typeof window === 'undefined') {
        return true; // Assume online during SSR
    }
    return navigator.onLine;
}

/**
 * React hook to track network status
 * @returns boolean indicating if the browser is online
 */
export function useNetworkStatus(): boolean {
    const [online, setOnline] = useState<boolean>(isOnline);

    useEffect(() => {
        const handleOnline = () => {
            console.log('[Network] Connection restored');
            setOnline(true);
        };

        const handleOffline = () => {
            console.log('[Network] Connection lost');
            setOnline(false);
        };

        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);

        // Check initial status
        setOnline(isOnline());

        return () => {
            window.removeEventListener('online', handleOnline);
            window.removeEventListener('offline', handleOffline);
        };
    }, []);

    return online;
}

/**
 * Add a listener for network status changes
 * @param callback Function to call when network status changes
 * @returns Cleanup function to remove the listener
 */
export function onNetworkChange(callback: (online: boolean) => void): () => void {
    if (typeof window === 'undefined') {
        return () => { }; // No-op during SSR
    }

    const handleOnline = () => callback(true);
    const handleOffline = () => callback(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Call immediately with current status
    callback(isOnline());

    return () => {
        window.removeEventListener('online', handleOnline);
        window.removeEventListener('offline', handleOffline);
    };
}

'use client';

import { useNetworkStatus } from '@/utils/networkStatus';
import { useEffect, useState } from 'react';
import { WifiOff, Wifi } from 'lucide-react';

export function OfflineIndicator() {
    const isOnline = useNetworkStatus();
    const [showIndicator, setShowIndicator] = useState(false);
    const [hasBeenOffline, setHasBeenOffline] = useState(false);

    useEffect(() => {
        if (!isOnline) {
            setHasBeenOffline(true);
            setShowIndicator(true);
        } else if (hasBeenOffline) {
            // Show "back online" message briefly
            setShowIndicator(true);
            const timer = setTimeout(() => {
                setShowIndicator(false);
            }, 3000);
            return () => clearTimeout(timer);
        }
    }, [isOnline, hasBeenOffline]);

    if (!showIndicator) {
        return null;
    }

    return (
        <div
            className={`fixed bottom-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg backdrop-blur-md transition-all duration-300 ${isOnline
                    ? 'bg-green-900/90 border border-green-700'
                    : 'bg-orange-900/90 border border-orange-700'
                }`}
            role="status"
            aria-live="polite"
        >
            <div className="flex items-center gap-3">
                {isOnline ? (
                    <Wifi className="w-5 h-5 text-green-300" />
                ) : (
                    <WifiOff className="w-5 h-5 text-orange-300" />
                )}
                <div className="flex flex-col">
                    <span className="font-semibold text-sm text-white">
                        {isOnline ? 'Back online!' : 'Offline mode'}
                    </span>
                    <span className="text-xs text-slate-300">
                        {isOnline
                            ? 'Connection restored'
                            : 'App works offline - happy modding!'}
                    </span>
                </div>
            </div>
        </div>
    );
}

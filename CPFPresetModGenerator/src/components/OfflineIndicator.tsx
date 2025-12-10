'use client';

import { useNetworkStatus } from '@/utils/networkStatus';
import { useEffect, useState } from 'react';
import { WifiOff, Wifi } from 'lucide-react';
import { Toast } from './Toast';

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

    return (
        <Toast
            isVisible={showIndicator}
            variant={isOnline ? 'success' : 'warning'}
            mainIcon={
                isOnline ? (
                    <Wifi className="w-5 h-5 text-green-300" />
                ) : (
                    <WifiOff className="w-5 h-5 text-orange-300" />
                )
            }
            title={isOnline ? 'Back online!' : 'Offline mode'}
            message={
                isOnline
                    ? 'Connection restored'
                    : 'App works offline - happy modding!'
            }
        />
    );
}

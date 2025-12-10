'use client';

import { useEffect, useState } from 'react';
import { PackageCheck } from 'lucide-react';
import { Toast } from './Toast';

export function PackagingUpdateToast() {
    const [showToast, setShowToast] = useState(false);

    useEffect(() => {
        const hasSeenToast = localStorage.getItem('has_seen_packaging_toast');
        // ~6 weeks from Dec 10, 2025
        const expirationDate = new Date('2026-01-21').getTime();
        const now = new Date().getTime();

        if (!hasSeenToast && now < expirationDate) {
            // Show toast
            setShowToast(true);

            // Mark as seen immediately so it doesn't show again on reload
            localStorage.setItem('has_seen_packaging_toast', 'true');

            // Hide after 8 seconds
            const timer = setTimeout(() => {
                setShowToast(false);
            }, 30000);

            return () => clearTimeout(timer);
        }
    }, []);

    return (
        <Toast
            isVisible={showToast}
            variant="success"
            className="bottom-20"
            mainIcon={<PackageCheck className="w-5 h-5 text-green-300" />}
            title="Update: Automatic packaging!"
            message="No need to manually package mods anymore - the generator will produce ready-to-distribute mods!"
        />
    );
}

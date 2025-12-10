import type { Event, EventHint } from '@sentry/nextjs';
import { isOnline, onNetworkChange } from './networkStatus';

const DB_NAME = 'SentryOfflineQueue';
const STORE_NAME = 'events';
const DB_VERSION = 1;
const MAX_QUEUE_SIZE = 50;
const MAX_EVENT_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

interface QueuedEvent {
    id: string;
    event: Event;
    hint: EventHint;
    timestamp: number;
}

class SentryOfflineQueue {
    private db: IDBDatabase | null = null;
    private initialized = false;
    private processingQueue = false;

    async init(): Promise<void> {
        if (this.initialized || typeof window === 'undefined') {
            return;
        }

        try {
            this.db = await this.openDatabase();
            this.initialized = true;

            // Listen for network changes and process queue when online
            onNetworkChange((online) => {
                if (online) {
                    this.processQueue();
                }
            });

            // Process queue immediately if online
            if (isOnline()) {
                this.processQueue();
            }
        } catch (error) {
            console.error('[Sentry Queue] Failed to initialize:', error);
        }
    }

    private openDatabase(): Promise<IDBDatabase> {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);

            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);

            request.onupgradeneeded = (event) => {
                const db = (event.target as IDBOpenDBRequest).result;

                if (!db.objectStoreNames.contains(STORE_NAME)) {
                    const store = db.createObjectStore(STORE_NAME, { keyPath: 'id' });
                    store.createIndex('timestamp', 'timestamp', { unique: false });
                }
            };
        });
    }

    async queueEvent(event: Event, hint: EventHint): Promise<void> {
        if (!this.initialized || !this.db) {
            await this.init();
        }

        if (!this.db) {
            console.warn('[Sentry Queue] Database not available, dropping event');
            return;
        }

        try {
            // Clean up old events first
            await this.cleanupOldEvents();

            // Check queue size
            const count = await this.getQueueSize();
            if (count >= MAX_QUEUE_SIZE) {
                console.warn('[Sentry Queue] Queue full, dropping oldest event');
                await this.removeOldestEvent();
            }

            const queuedEvent: QueuedEvent = {
                id: crypto.randomUUID(),
                event,
                hint,
                timestamp: Date.now(),
            };

            const transaction = this.db.transaction([STORE_NAME], 'readwrite');
            const store = transaction.objectStore(STORE_NAME);
            await this.promisifyRequest(store.add(queuedEvent));

            console.log('[Sentry Queue] Event queued:', queuedEvent.id);
        } catch (error) {
            console.error('[Sentry Queue] Failed to queue event:', error);
        }
    }

    private async processQueue(): Promise<void> {
        if (this.processingQueue || !this.initialized || !this.db || !isOnline()) {
            return;
        }

        this.processingQueue = true;

        try {
            const events = await this.getAllEvents();
            console.log(`[Sentry Queue] Processing ${events.length} queued events`);

            for (const queuedEvent of events) {
                try {
                    // Send to Sentry using the global Sentry instance
                    if (typeof window !== 'undefined' && (window as any).Sentry) {
                        await (window as any).Sentry.captureEvent(queuedEvent.event);
                        await this.removeEvent(queuedEvent.id);
                        console.log('[Sentry Queue] Event sent:', queuedEvent.id);
                    }
                } catch (error) {
                    console.error('[Sentry Queue] Failed to send event:', error);
                    // Stop processing if we're offline again
                    if (!isOnline()) {
                        break;
                    }
                }
            }
        } catch (error) {
            console.error('[Sentry Queue] Failed to process queue:', error);
        } finally {
            this.processingQueue = false;
        }
    }

    private async getAllEvents(): Promise<QueuedEvent[]> {
        if (!this.db) return [];

        const transaction = this.db.transaction([STORE_NAME], 'readonly');
        const store = transaction.objectStore(STORE_NAME);
        return this.promisifyRequest(store.getAll());
    }

    private async getQueueSize(): Promise<number> {
        if (!this.db) return 0;

        const transaction = this.db.transaction([STORE_NAME], 'readonly');
        const store = transaction.objectStore(STORE_NAME);
        return this.promisifyRequest(store.count());
    }

    private async removeEvent(id: string): Promise<void> {
        if (!this.db) return;

        const transaction = this.db.transaction([STORE_NAME], 'readwrite');
        const store = transaction.objectStore(STORE_NAME);
        await this.promisifyRequest(store.delete(id));
    }

    private async removeOldestEvent(): Promise<void> {
        if (!this.db) return;

        const transaction = this.db.transaction([STORE_NAME], 'readwrite');
        const store = transaction.objectStore(STORE_NAME);
        const index = store.index('timestamp');
        const cursor = await this.promisifyRequest(index.openCursor());

        if (cursor) {
            await this.promisifyRequest(store.delete(cursor.primaryKey));
        }
    }

    private async cleanupOldEvents(): Promise<void> {
        if (!this.db) return;

        const cutoffTime = Date.now() - MAX_EVENT_AGE_MS;
        const transaction = this.db.transaction([STORE_NAME], 'readwrite');
        const store = transaction.objectStore(STORE_NAME);
        const index = store.index('timestamp');
        const range = IDBKeyRange.upperBound(cutoffTime);

        const cursor = await this.promisifyRequest(index.openCursor(range));
        const deletePromises: Promise<void>[] = [];

        if (cursor) {
            deletePromises.push(this.promisifyRequest(store.delete(cursor.primaryKey)));
        }

        await Promise.all(deletePromises);
    }

    private promisifyRequest<T>(request: IDBRequest<T>): Promise<T> {
        return new Promise((resolve, reject) => {
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }
}

// Singleton instance
export const sentryOfflineQueue = new SentryOfflineQueue();

// Initialize on module load
if (typeof window !== 'undefined') {
    sentryOfflineQueue.init();
}

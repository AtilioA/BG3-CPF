// This file configures the initialization of Sentry on the client.
// The added config here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";
import { isOnline } from "@/utils/networkStatus";
import { sentryOfflineQueue } from "@/utils/sentryOfflineQueue";

Sentry.init({
    dsn: "https://51d8b482c6cb9107b355b9f047adfae0@o4510454219014144.ingest.de.sentry.io/4510454272819280",
    // Enable logs to be sent to Sentry
    enableLogs: true,

    // Enable sending user PII (Personally Identifiable Information)
    // https://docs.sentry.io/platforms/javascript/guides/nextjs/configuration/options/#sendDefaultPii
    sendDefaultPii: true,

    // Queue events when offline
    beforeSend(event, hint) {
        if (!isOnline()) {
            console.log('[Sentry] Offline - queuing event');
            sentryOfflineQueue.queueEvent(event, hint);
            return null; // Don't send now
        }
        return event;
    },
});

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;

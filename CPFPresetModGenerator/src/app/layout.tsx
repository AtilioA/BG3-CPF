
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Analytics } from "@vercel/analytics/next"
import { OfflineIndicator } from "@/components/OfflineIndicator";
import { PackagingUpdateToast } from "@/components/PackagingUpdateToast";

const inter = Inter({ subsets: ["latin"] });

const siteUrl = "https://bg3-cpf-preset-mod-generator.vercel.app/";
const siteName = "BG3 Preset Mod Generator";
const siteDescription = "Turn any Character Preset Framework (CPF) preset into a Baldur's Gate 3 mod.";

export const metadata: Metadata = {
    title: {
        default: siteName,
        template: `%s | ${siteName}`,
    },
    description: siteDescription,
    keywords: [
        "Baldur's Gate 3",
        "BG3",
        "CPF",
        "Character Preset Framework",
        "mod generator",
        "preset mod",
        "BG3 mods",
        "character presets",
        "modding tool"
    ],
    authors: [{ name: "Volitio" }],
    creator: "Volitio",
    publisher: "Volitio",
    metadataBase: new URL(siteUrl),
    alternates: {
        canonical: "/",
    },
    openGraph: {
        type: "website",
        locale: "en_US",
        url: siteUrl,
        title: siteName,
        description: siteDescription,
        siteName: siteName,
        images: [
            {
                url: "/og-image.png",
                width: 1024,
                height: 1024,
                alt: "BG3 Preset Mod Generator",
            },
        ],
    },
    robots: {
        index: true,
        follow: true,
        googleBot: {
            index: true,
            follow: true,
            "max-video-preview": -1,
            "max-image-preview": "large",
            "max-snippet": -1,
        },
    },
    icons: {
        icon: [
            { url: "/favicon.ico" },
            { url: "/icon.png", type: "image/png", sizes: "32x32" },
        ],
    },
    manifest: "/site.webmanifest",
    verification: {
    },
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <head>
                <link rel="canonical" href="https://volitio.dev" />
                {/* Structured Data for SEO */}
                <script
                    type="application/ld+json"
                    dangerouslySetInnerHTML={{
                        __html: JSON.stringify({
                            "@context": "https://schema.org",
                            "@type": "WebApplication",
                            "name": siteName,
                            "description": siteDescription,
                            "url": siteUrl,
                            "applicationCategory": "UtilitiesApplication",
                            "operatingSystem": "Any",
                            "author": {
                                "@type": "Person",
                                "name": "Volitio"
                            }
                        })
                    }}
                />
                {/* Service Worker registration */}
                <script
                    dangerouslySetInnerHTML={{
                        __html: `
                            if ('serviceWorker' in navigator) {
                                window.addEventListener('load', function() {
                                    navigator.serviceWorker.register('/service-worker.js')
                                        .then(function(registration) {
                                            console.log('[SW] Registered:', registration.scope);
                                        })
                                        .catch(function(error) {
                                            console.log('[SW] Registration failed:', error);
                                        });
                                });
                            }
                        `
                    }}
                />
            </head>
            <body className={inter.className}>
                {children}
                <OfflineIndicator />
                <PackagingUpdateToast />
                <Analytics />
            </body>
        </html>
    );
}

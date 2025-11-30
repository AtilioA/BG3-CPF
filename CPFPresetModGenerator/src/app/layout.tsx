
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Analytics } from "@vercel/analytics/next"

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
    title: "BG3 Preset Mod Generator",
    description: "Turn any CPF preset into a mod",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <head>
                <title>CPF preset mod generator</title>
            </head>
            <body className={inter.className}>
                {children}
                <Analytics />
            </body>
        </html>
    );
}

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreenHat 🧢",
  description: "The greenest meme coin on EVM",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

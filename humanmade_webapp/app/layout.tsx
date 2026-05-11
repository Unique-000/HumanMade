import type { Metadata } from "next";
import "./globals.css";
import DynamicBackground from "@/components/DynamicBackground"
import Grainient from "@/components/Grainient";
import Link from "next/link";

export const metadata: Metadata = {
  title: "HumanMade",
  description: "Check the reality In front of your Eyes.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="h-dvh w-dvw">
            <div className="w-full h-full absolute -z-50">
            <Grainient
              color1="#00c230"
              color2="#fbff29"
              color3="#22d38f"
              timeSpeed={0.25}
              colorBalance={0}
              warpStrength={1}
              warpFrequency={5}
              warpSpeed={2}
              warpAmplitude={50}
              blendAngle={0}
              blendSoftness={0.05}
              rotationAmount={500}
              noiseScale={2}
              grainAmount={0.1}
              grainScale={2}
              grainAnimated={false}
              contrast={1.5}
              gamma={1}
              saturation={1}
              centerX={0}
              centerY={0}
              zoom={0.9}
              className="blur-3xl opacity-50 "
            />
          </div>

        <main className="h-dvh w-dvw flex absolute z-0 items-center justify-center overflow-scroll">
          {children}
        </main>
      </body>
    </html>
  );
}

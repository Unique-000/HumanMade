"use client"

import { useEffect, useState } from "react"
import { useParams, usePathname } from "next/navigation"
import axios from "axios"
import Image from "next/image"
import Grainient from "@/components/Grainient";
import { apiUrl } from "@/lib/config"

export default function DynamicBackground() {
  const params = useParams<{ tag: string }>()
  const pathname = usePathname()
  const [url, setUrl] = useState<string | null>(null)

  useEffect(() => {
    if (!params?.tag) return

    axios
      .get(apiUrl(`/api/images/${encodeURIComponent(params.tag)}`))
      .then((res) => {
        setUrl(res.data.url)
      })
      .catch(() => {})
  }, [params.tag, pathname])

  if (!url) return (
    <div className="w-dvw h-dvh absolute -z-50">
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
      />
    </div>
  )

  return (
    <div className="w-dvw h-dvh absolute overflow-hidden inset-0 -z-50">
      <Image
        src={url}
        alt=""
        fill
        className="object-cover blur-2xl scale-110"
        priority
      />
      <div className="absolute inset-0 bg-black/40" />
    </div>
  )
}

import type { NextConfig } from "next";
import { IMAGE_HOST } from "./lib/config";

const nextConfig: NextConfig = {
  /* config options here */
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: IMAGE_HOST,
        pathname: "/**",
      },
      
    ],
  }
};

export default nextConfig;

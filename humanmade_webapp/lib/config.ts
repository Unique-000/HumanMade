const DEFAULT_IMAGE_HOST = "sixmvbhdxbrvfbivwojw.supabase.co";

const trimTrailingSlash = (value: string) => value.replace(/\/+$/, "");

const rawApiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL;

if (!rawApiBaseUrl) {
  throw new Error("NEXT_PUBLIC_API_BASE_URL is required");
}

export const API_BASE_URL = trimTrailingSlash(rawApiBaseUrl);

export const IMAGE_HOST =
  process.env.NEXT_PUBLIC_IMAGE_HOST ?? DEFAULT_IMAGE_HOST;

export const apiUrl = (path: string) =>
  `${API_BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;

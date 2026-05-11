// file-input.tsx
"use client";

import React, { useRef, useState } from "react";
import { cn } from "@/lib/utils";
import { AlertCircleIcon, XIcon } from "lucide-react";
import { HugeiconsIcon } from "@hugeicons/react";
import { CloudUploadIcon } from "@hugeicons/core-free-icons";

const IMAGE_TYPES = ["image/png", "image/jpeg", "image/heic"];

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return "0 Bytes";
  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
};

interface FileInputProps {
  id?: string;
  className?: string;
  name?: string;
  maxSize?: number;
  onChange?: (file: File | null) => void;
  onError?: (error: string) => void;
}

export function FileInput({ id, className, name, maxSize, onChange, onError }: FileInputProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [isDragActive, setDragActive] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isImageUploaded = file !== null && IMAGE_TYPES.includes(file.type);

  const handleFile = (incoming: File) => {
    setError(null);

    if (maxSize && incoming.size > maxSize) {
      const msg = `${incoming.name} exceeds ${formatFileSize(maxSize)} maximum size`;
      setError(msg);
      onError?.(msg);
      return;
    }

    setFile(incoming);
    onChange?.(incoming);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragActive(false);
    if (isImageUploaded) return;
    const dropped = e.dataTransfer.files[0];
    if (dropped) handleFile(dropped);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selected = e.target.files?.[0];
    if (selected) handleFile(selected);
    e.target.value = "";
  };

  const removeFile = () => {
    setFile(null);
    setError(null);
    onChange?.(null);
  };

  return (
    <div className={cn("w-[264px]", className)}>
      {/* Drop zone */}
      <div
        onDragOver={(e) => e.preventDefault()}
        onDragEnter={() => !isImageUploaded && setDragActive(true)}
        onDragLeave={() => setDragActive(false)}
        onDrop={handleDrop}
        onClick={() => !isImageUploaded && inputRef.current?.click()}
        className={cn(
          "relative rounded-lg transition-all p-8 bg-foreground h-50 flex items-center justify-center",
          isImageUploaded
            ? "opacity-50 cursor-not-allowed"
            : "cursor-pointer hover:border-primary/50 hover:bg-foreground/60",
          isDragActive && "scale-[1.02] border-primary bg-primary/5",
        )}
      >
        <input
          ref={inputRef}
          id={id}
          name={name}
          type="file"
          accept="image/png,image/jpeg,.heic"
          disabled={isImageUploaded}
          onChange={handleChange}
          className="hidden"
        />
        <div className="flex flex-col items-center gap-2 pointer-events-none">
          <HugeiconsIcon icon={CloudUploadIcon} size={42} color="currentColor" strokeWidth={2} />
          <p className={cn("font-bold font-sans text-sm", isDragActive && "text-primary")}>
            Upload Image
          </p>
          {maxSize && (
            <p className="text-xs text-muted-foreground">Max size: {formatFileSize(maxSize)}</p>
          )}
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="mt-4 flex items-start gap-2 p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
          <AlertCircleIcon className="w-4 h-4 text-destructive mt-0.5" />
          <p className="text-sm text-destructive">{error}</p>
        </div>
      )}

      {/* Uploaded file row */}
      {file && (
        <div className="mt-4 flex items-center justify-between p-3 bg-secondary/50 border border-border rounded-lg">
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium truncate">{file.name}</p>
            <p className="text-xs text-muted-foreground">{formatFileSize(file.size)}</p>
          </div>
          <button
            type="button"
            onClick={removeFile}
            className="ml-2 p-1 hover:bg-destructive/10 rounded transition"
            title="Remove and upload a different file"
          >
            <XIcon className="w-4 h-4 text-destructive" />
          </button>
        </div>
      )}
    </div>
  );
}
FileInput.displayName = "FileInput";
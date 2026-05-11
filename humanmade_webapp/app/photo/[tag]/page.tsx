"use client"
import { useParams } from 'next/navigation'
import { useEffect, useState, useCallback, type ReactNode } from 'react';
import axios from "axios"
import Image from "next/image";
import { apiUrl } from "@/lib/config";
import { GetBackButton } from '@/components/GetBackButton';
import { HugeiconsIcon } from '@hugeicons/react';
import { Cancel01Icon, CopyIcon, LinkSquare02Icon } from '@hugeicons/core-free-icons';

interface PhotoData {
    url: string;
    takenAt: number;
    localization: string;
    sha256: string;
    phash: string;
    txSignature?: string | null;
}

interface OpenLinkIconProps {
    photoData: PhotoData;
}

const OpenLinkIcon = ({photoData}: OpenLinkIconProps)=>{
    return (
        <a href={photoData.txSignature ? `https://explorer.solana.com/tx/${photoData.txSignature}` : photoData.url} target="_blank" rel="noreferrer">
            <HugeiconsIcon icon={LinkSquare02Icon} />
        </a>
    )
}

interface DescriptionTagsProps {
    tagName: string;
    tagIcon: ReactNode;
    photoData: string;
}

const DescriptionTags = ({ tagName, tagIcon, photoData }: DescriptionTagsProps) => {
    const handleCopy = useCallback(async () => {
        if (typeof navigator !== 'undefined' && navigator.clipboard) {
            try {
                await navigator.clipboard.writeText(photoData)
            } catch (err) {
                console.error('Failed to copy:', err)
            }
        }
    }, [photoData])

    return (
        <div className="text-white text-lg bg-neutral-400/50 rounded-md flex items-stretch mb-3 overflow-hidden">
            <span className="text-white text-sm bg-[#6FFF00]/75 flex items-center px-2 shrink-0">
                {tagName}
            </span>

            <span className="ml-2 flex items-center truncate min-w-0">
                {photoData}
            </span>

            <button
                type="button"
                onClick={handleCopy}
                className="ml-auto mr-1 my-1 flex items-center justify-center cursor-pointer"
                aria-label={`Copy ${tagName}`}
            >
                {tagIcon}
            </button>
        </div>
    )
}

interface CloseUpViewProps {
    photoData: PhotoData;
    closeUp: boolean;
    setCloseUp: (value: boolean) => void;
}

const CloseUpView = ({photoData, closeUp, setCloseUp}: CloseUpViewProps)=>{
    return(
        <div className='w-dvw h-dvh flex justify-center flex-col absolute z-10 bg-black/50 backdrop-blur-3xl'>
            <nav className='h-25 w-full px-10 flex items-center justify-end absolute top-0'>
                <HugeiconsIcon icon={Cancel01Icon} onClick={() => setCloseUp(!closeUp)}/>
            </nav>
            <div className="w-full h-full flex items-center justify-center overflow-hidden p-10 rounded-4xl">
            <img
                src={photoData.url}
                alt="Verified image"
                className="rounded-4xl max-w-full max-h-full object-contain w-full h-full"
                draggable={false}
            />
            </div>
        </div>
    )
}


export default function Page(){
    const params = useParams();
    const tag = params.tag as string
    const [photoData, setPhotoData] = useState<PhotoData | undefined>(() => {
        if (typeof window === "undefined" || !tag) {
            return undefined
        }

        const cached = sessionStorage.getItem(`photo:${tag}`)
        if (!cached) {
            return undefined
        }

        try {
            return JSON.parse(cached) as PhotoData
        } catch (error) {
            console.error("Failed to parse cached photo data", error)
            return undefined
        }
    })
    const [closeUp, setCloseUp] = useState(false)

    useEffect(() =>{
        if (localStorage.getItem("similar") == undefined){
            localStorage.setItem("similar", "false")
        }
        if (photoData?.url) {
            return
        }
        axios.get(apiUrl(`/api/images/${encodeURIComponent(tag)}`))
        .then(function (response){
            setPhotoData(response.data)
            sessionStorage.setItem(`photo:${tag}`, JSON.stringify(response.data))
        })
        .catch(function (error) {
            alert(error)
        })
    }, [tag, photoData])

    if (!photoData) {
        return <div>Loading...</div>
    }

    return(
        <div className='h-dvh w-full flex justify-center items-center flex-col'>
            <GetBackButton/>
            <div className="w-dvw h-dvh absolute overflow-hidden inset-0 -z-50">
            <img
                src={photoData.url}
                alt=""
                className="absolute inset-0 w-full h-full object-cover blur-2xl scale-110"
                draggable={false}
            />
              <div className="absolute inset-0 bg-black/40" />
            </div>
            {closeUp ? <CloseUpView closeUp={closeUp} setCloseUp={setCloseUp} photoData={photoData}/> : <></>}
            <div className='max-w-100'>
            <Image
                src={photoData.url}
                alt="Verified image"
                width={300}
                height={300}
                unoptimized
                priority
                className="rounded-4xl cursor-pointer w-full h-max squircle"
                onClick={() => setCloseUp(true)}
            />
                <div className='bg-black/25 backdrop-blur-[1000px] w-full rounded-4xl squircle p-8 mt-10'>
                    <div className='flex items-center mb-2'>
                        {localStorage.getItem("similar") != "true" ? (
                            <>
                            <svg width="10px" height="10px" viewBox="0 0 36 36" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" role="img" preserveAspectRatio="xMidYMid meet">
                                <circle fill="#6FFF00" cx="18" cy="18" r="18"></circle>
                            </svg>
                            <p className='text-white ml-2 pt-[1]'>The same image</p>
                            </>
                        ) : (
                            <>
                            <svg width="10px" height="10px" viewBox="0 0 36 36" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" role="img" preserveAspectRatio="xMidYMid meet">
                                <circle fill="#FFC800" cx="18" cy="18" r="18"></circle>
                            </svg>
                            <p className='text-white ml-2 pt-[1]'>Very similar image</p>
                            </>
                        )}
                    </div>
                    <p className='text-white text-lg'>{photoData.localization}</p>
                    <p className='text-white text-lg mb-2'>{photoData.takenAt != null ? photoData.takenAt : "No time provided"}</p>

                    <DescriptionTags tagName={"SHA256"} tagIcon={<HugeiconsIcon icon={CopyIcon} />} photoData={photoData.sha256}/>
                    <DescriptionTags tagName={"pHash"} tagIcon={<HugeiconsIcon icon={CopyIcon} />} photoData={photoData.phash}/>
                    <DescriptionTags tagName={"Transaction"} tagIcon={<OpenLinkIcon photoData={photoData}/>} photoData={photoData.txSignature ?? "No transaction available"}/>
                </div>
            </div>
        </div>
    )
}

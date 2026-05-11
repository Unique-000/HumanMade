"use client"
import { Login } from '@hugeicons/core-free-icons'
import { useRouter } from 'next/navigation'

export default function Page(){
    const router = useRouter()

    return(
        <div className='flex flex-col'>
            <div className="flex flex-row items-center justify-center h-full w-full max-w-[1500px] gap-10">
                <div className="flex flex-col justify-evenly bg-[#AFFF5D] w-140 h-100 rounded-[30] ">
                    <div className="pl-10 pr-10 mt-8">
                        <p className="text-[#4C5C18] text-4xl font-bold mb-1">Decentralized proof of reality</p>
                    </div>
                    <div className="pl-10 pr-10">
                        <p className='text-[#709200] text-md '>
                            In a world where AI-generated images are becoming nearly indistinguishable from real photography, trust in visual content is disappearing. Our platform was built to restore that trust. Every time a photo is captured through the app, a unique cryptographic fingerprint and verification code are securely registered, creating a permanent proof that the image existed in its original form at a specific moment in time. Anyone can later verify the authenticity of that image either by uploading it or entering its verification code on our website.
                        </p>
                    </div>
                </div>
                <div className="flex flex-col justify-evenly bg-[#AFFF5D] w-140 h-100 rounded-[30] ">
                    <div className="pl-10 pr-10 mt-8">
                        <p className="text-[#4C5C18] text-4xl font-bold mb-1">Authenticity Through Perceptual Hashing</p>
                    </div>
                    <div className="pl-10 pr-10">
                        <p className='text-[#709200] text-md '>
                            The system is designed to work even after images are resized, compressed, or reposted across social media platforms. By combining traditional hashing with perceptual hashing technology, the platform can recognize authentic images despite minor visual modifications introduced by messaging apps or social networks. The goal is simple: make it easier to distinguish genuine photographs from manipulated or AI-generated content, and give creators, journalists, and everyday users a reliable way to prove what is real.                    </p>
                    </div>
                </div>
            </div>
            <div className="flex flex-row items-center justify-center h-full w-full max-w-[1500px] mt-10">
                <div className="pl-10 pr-10">
                    <p onClick={() => router.push('/')} className="text-[#4C5C18] text-xl font-bold mb-1 cursor-pointer underline">Home</p>
                </div>
            </div>
        </div>
    )
}
"use client"
import { GetBackButton } from '@/components/GetBackButton'
import { Login } from '@hugeicons/core-free-icons'
import Image from 'next/image'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

export default function Page(){
    const router = useRouter()

    return(
        <>
        <GetBackButton/>
        <div className="flex flex-col bg-[#AFFF5D] rounded-[30] space-y-7 p-10">
            <p className="text-[#4C5C18] text-4xl font-bold mb-8">Contact</p>
            <p className='text-[#709200] text-2xl'>
                <a href='https://t.me/src_guy'>Telegram: @src_guy</a>
            </p>
            <p className='text-[#709200] text-2xl'>
                <a href='mailto:cameo-said-blubber@duck.com'>E-mail: @2gulo</a>
            </p>
        </div>
        </>
    )
}
"use client"
import { Login } from '@hugeicons/core-free-icons'
import { useRouter } from 'next/navigation'
import { useState, useEffect } from 'react'
import Devices from '@/components/Devices'
import Additional from '@/components/Additional'

export default function Page(){
    const router = useRouter()
    const [menu, setMenu] = useState("devices")

    useEffect(() => {
        const accNum = localStorage.getItem("acc_num");
        if (!accNum) {
            router.replace('/');
        }
    }, [router])

    function Logout() {
        localStorage.setItem("acc_num", "");
        router.replace('/');
    }

    return(
        <div className='flex flex-col'>
            <div className="flex flex-row justify-around h-full w-full max-w-[1500px] gap-10">
                <div className="flex flex-col bg-[#AFFF5D] w-100 h-100 rounded-[30] ">
                    <div className="flex-1 flex pl-10 pr-10 mt-8 items-center">
                        <p className="text-[#4C5C18] text-4xl font-bold mb-1">Dashboard</p>
                    </div>
                    <div className="flex-3 flex flex-col gap-5 pl-8 pr-10">
                        <p onClick={() => setMenu("devices")} className='text-[#709200] text-xl hover:bg-[#4C5C18]/25 hover:text-yellow-200 p-2 rounded-[10px] cursor-pointer'>
                            Devices
                        </p>
                        <p onClick={() => setMenu("additional")} className='text-[#709200] text-xl hover:bg-[#4C5C18]/25 hover:text-yellow-200 p-2 rounded-[10px] cursor-pointer'>
                            Additional functionalities
                        </p>
                    </div>
                </div>
                <div className="flex flex-col justify-evenly bg-[#AFFF5D] w-240 h-100 rounded-[30] ">
                    {menu == "devices" ? <Devices/> : ""}
                    {menu == "additional" ? <Additional/> : ""}
                </div>
            </div>
            <div className="flex flex-row items-center justify-center h-full w-full max-w-[1500px] mt-10">
                <div className="pl-10 pr-10">
                    <p onClick={() => Logout()} className="text-[#4C5C18] text-xl font-bold mb-1 cursor-pointer underline">Home & logout</p>
                </div>
            </div>
        </div>
    )
}

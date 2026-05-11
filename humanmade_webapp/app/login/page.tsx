"use client"

import { useRouter } from 'next/navigation'
import axios from 'axios'
import { apiUrl } from '@/lib/config';
import { InputOTP, InputOTPGroup, InputOTPSlot } from '@/components/ui/input-otp';
import { REGEXP_ONLY_DIGITS } from 'input-otp';
import { useState } from 'react';
import { GetBackButton } from '@/components/GetBackButton';

export default function Page(){
    const [accNumber, setAccNumber] = useState("");
    const [loading, setLoading] = useState(false);
    const router = useRouter()

    async function LoginHandle(){
        if (accNumber.length != 16){
            alert("Enter correct account number")
            return
        }

        try {
            setLoading(true);
            const response = await axios.post(apiUrl("/api/users/login"), {
                login: accNumber
            })

            localStorage.setItem("acc_num", response.data?.login ?? accNumber)
            router.push('/')
        } catch (err) {
            console.error(err)
            alert("Login failed. Please check your account number.")
        } finally {
            setLoading(false);
        }
    }

    return(
        <>
        <GetBackButton/>
        <div className="flex flex-row items-center justify-center h-full w-full max-w-[1500px]">
            <div className="flex flex-col justify-around items-center bg-[#AFFF5D] w-fit h-fit p-4 pt-5 sm:p-10 rounded-[30] space-y-8">
                <div className="w-full justify-start flex">
                    <p className="text-[#4C5C18] text-4xl font-bold">Log in</p>
                </div>
                        <div className="flex flex-col space-y-2 text-[#709200] ">
                            <p className="font-bold">Account number</p>
                            <InputOTP maxLength={16} pattern={REGEXP_ONLY_DIGITS} value={accNumber} onChange={setAccNumber}>
                            <InputOTPGroup>
                                <InputOTPSlot index={0} isLogin={true}/>
                                <InputOTPSlot index={1} isLogin={true}/>
                                <InputOTPSlot index={2} isLogin={true}/>
                                <InputOTPSlot index={3} isLogin={true}/>
                                <InputOTPSlot index={4} isLogin={true}/>
                                <InputOTPSlot index={5} isLogin={true}/>
                                <InputOTPSlot index={6} isLogin={true}/>
                                <InputOTPSlot index={7} isLogin={true}/>
                                <InputOTPSlot index={8} isLogin={true}/>
                                <InputOTPSlot index={9} isLogin={true}/>
                                <InputOTPSlot index={10} isLogin={true}/>
                                <InputOTPSlot index={11} isLogin={true}/>
                                <InputOTPSlot index={12} isLogin={true}/>
                                <InputOTPSlot index={13} isLogin={true}/>
                                <InputOTPSlot index={14} isLogin={true}/>
                                <InputOTPSlot index={15} isLogin={true}/>
                            </InputOTPGroup>
                            </InputOTP>
                        </div>
                <div
                    onClick={loading ? undefined : LoginHandle}
                    className={`flex justify-center bg-[#C6FF0E] h-10 w-90 rounded-[10] ${loading ? "cursor-wait opacity-75" : "cursor-pointer"}`}
                >
                    <p className="text-[#709200] text-xl font-semibold mt-auto mb-auto">{loading ? "Logging in..." : "Log In"}</p>
                </div>
                <div onClick={() => router.push('/register')} className="flex justify-center h-10 w-90 rounded-[10] cursor-pointer">
                    <p className="text-[#709200] text-base font-semibold mt-auto mb-auto">Create new account</p>
                </div>
            </div>
        </div>
        </>
    )
}

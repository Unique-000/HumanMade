"use client"
import { GetBackButton } from "@/components/GetBackButton"
import AccountCreation from "@/components/AccountCreation"
import NumberGenerator from "@/components/NumberGenerator"
import { useState } from "react"

export default function Page(){
    const [generatedLogin, setGeneratedLogin] = useState<string | null>(null)

    return(
        <>
            <GetBackButton/>
                <div className="flex flex-row items-center justify-center h-full w-full max-w-2xl p-5 pt-30">
                    <div className="flex flex-col justify-around items-center bg-[#AFFF5D] w-fit h-fit p-4 pt-5 sm:p-10 rounded-[30] space-y-8">
                    <NumberGenerator onGenerated={setGeneratedLogin}/>
                    <AccountCreation login={generatedLogin}/>
                </div>
            </div>
        </>
    )
}

"use client"

import axios from "axios"
import "../app/globals.css"
import { useRouter } from 'next/navigation'
import { apiUrl } from '@/lib/config';
import { useState } from "react";

interface AccountCreationProps {
    login: string | null;
}

export default function AccountCreation({ login }: AccountCreationProps){
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    async function LoginAttempt(){
        const checkbox = document.getElementById("check") as HTMLInputElement | null;

        if (!checkbox?.checked){
            alert("Check the checkbox before creating the account.")
            return
        }

        if (!login || login.length !== 16) {
            alert("Waiting for the server to generate your account number.")
            return
        }

        try {
            setLoading(true);
            const response = await axios.post(apiUrl("/api/users/register"), { login });
            const createdLogin = response.data?.login ?? login;

            localStorage.setItem("acc_num", createdLogin)
            router.push("/")
        } catch (err) {
            console.error(err)
            alert("Failed to create account. Please try again.")
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className="flex flex-col w-full space-y-10">
            <div className="">
                <p className="text-[#4C5C18] text-3xl font-semibold mb-1">Create your account</p>
                <p className="text-[#4C5C18] text-lg">The number above was generated on the server. Confirm that you saved it, then continue to create the account.</p>
            </div>
            <div className="flex items-center flex-row w-full">
                <input type="checkbox" className="custom-checkbox" id="check"/>
                <p className="text-[#4C5C18] text-lg ml-5 font-semibold mt-auto mb-auto">I confirm that I’ve saved my account number.</p>
            </div>
            <div
                onClick={loading ? undefined : LoginAttempt}
                className={`flex justify-center bg-[#C6FF0E] h-10 w-full rounded-[10] ${loading ? "cursor-wait opacity-75" : "cursor-pointer"}`}
            >
                <p className="text-[#709200] text-xl font-semibold mt-auto mb-auto">{loading ? "Creating..." : "Create account"}</p>
            </div>
        </div>
    )
}

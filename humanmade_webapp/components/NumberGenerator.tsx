"use client"

import axios from "axios"
import { useEffect, useState } from "react"
import { apiUrl } from "@/lib/config"

interface NumberGeneratorProps {
    onGenerated?: (login: string) => void
}

export default function NumberGenerator({ onGenerated }: NumberGeneratorProps){
    const [number, setNumber] = useState<string | null>(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        let active = true

        async function loadGeneratedLogin() {
            try {
                const response = await axios.get(apiUrl("/api/users/register/preview"))
                const login = response.data?.login

                if (!active || !login) {
                    return
                }

                setNumber(login)
                onGenerated?.(login)
            } catch (err) {
                console.error(err)
                if (active) {
                    setNumber(null)
                }
            } finally {
                if (active) {
                    setLoading(false)
                }
            }
        }

        loadGeneratedLogin()

        return () => {
            active = false
        }
    }, [onGenerated])

    return (
        <div className="flex flex-col w-full space-y-10 justify-start">
            <p className="text-[#4C5C18] text-3xl font-semibold mb-10">This is your account number.</p>
            <p className="text-[#709200] text-4xl font-semibold ml-auto mr-auto text-center break-all">
                {loading ? "Generating on the server..." : number ? number.replace(/\d{4}(?=.)/g, "$& ") : "Failed to load account number."}
            </p>

            <div
                onClick={() => number && navigator.clipboard.writeText(number)}
                className={`flex justify-center bg-[#C6FF0E] h-10 w-full rounded-[10] ${number ? "cursor-pointer" : "cursor-not-allowed opacity-60"}`}
            >
                <p className="text-[#709200] text-xl font-semibold mt-auto mb-auto">Copy</p>
            </div>
        </div>
    )
}

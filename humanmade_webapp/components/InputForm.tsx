"use client"
import { useState } from "react"
import { useRouter } from 'next/navigation'
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSlot
} from "@/components/ui/input-otp"

import { REGEXP_ONLY_DIGITS_AND_CHARS } from "input-otp"
import { FileInput } from "@/components/ui/FileInput";
import axios from "axios"
import { apiUrl } from "@/lib/config"

export default function InputForm(){
    const router = useRouter();
    const [code, setCode] = useState("")
    const [loading, setLoading] = useState(false)

    function CheckCode(value: string){
        if (value.length == 6){
            setLoading(true)
            axios.get(apiUrl(`/api/images/${encodeURIComponent(value)}`))
            .then(function (res){
                sessionStorage.setItem(`photo:${value}`, JSON.stringify(res.data))
                localStorage.setItem("similar", "false")
                router.push('/photo/'+value);
                setLoading(false)
            })
            .catch(function (error) {
                alert(error)
            })
        }
    }
    
    const handleFileChange = async (file: File | null) => {
        if (!file) return

        const formData = new FormData()
        formData.append("file", file)

        try {
            setLoading(true)
            await axios.post(apiUrl("/api/images/check"), formData)
            .then((res) => {
                if (res.data.mess != undefined){
                    alert("No matches")
                }
                if(res.data.exactMatch == true){
                    sessionStorage.setItem(`photo:${res.data.matches[0].code}`, JSON.stringify(res.data.matches[0]))
                    localStorage.setItem("similar", "false")
                    router.push('/photo/'+res.data.matches[0].code);
                }
                if (res.data.similarMatch == true){
                    sessionStorage.setItem(`photo:${res.data.matches[0].code}`, JSON.stringify(res.data.matches[0]))
                    localStorage.setItem("similar", "true")
                    router.push('/photo/'+res.data.matches[0].code);
                }
                setLoading(false)
            })
        } catch (err) {
            alert(err)
        }
    }

    return(
        <div className="w-fit sm:w-[400px] bg-[#95e539]/60 backdrop-blur-[250px] p-7 space-y-7 rounded-[30] squircle text-[#709200] font-sans font-bold text-sm flex flex-col items-center">
        <div className="flex flex-col space-y-2">
            <p className="font-bold">Code</p>
            <InputOTP maxLength={6} pattern={REGEXP_ONLY_DIGITS_AND_CHARS} value={code} onChange={(value) => {
                setCode(value)
                CheckCode(value)}}>
            <InputOTPGroup>
                <InputOTPSlot index={0} />
                <InputOTPSlot index={1} />
                <InputOTPSlot index={2} />
                <InputOTPSlot index={3} />
                <InputOTPSlot index={4} />
                <InputOTPSlot index={5}/>
            </InputOTPGroup>
            </InputOTP>
        </div>

            <FileInput onChange={handleFileChange}/>
            {loading && <p className="text-sm text-muted-foreground mt-3">Loading...</p>}
        </div>
    )
}

import { HugeiconsIcon } from "@hugeicons/react";
import { ArrowLeft02Icon } from "@hugeicons/core-free-icons";
import Link from "next/link";

export function GetBackButton(){
    return(
        <nav className='h-25 w-full px-10 flex items-center justify-start absolute top-0 '>
            <Link href={"/"} className='flex flex-row items-center bg-[#AFFF5D] text-black space-x-2.5 p-2.5 rounded-lg'>
                <HugeiconsIcon icon={ArrowLeft02Icon} />
                <p>Get Back</p>
            </Link>
        </nav>
    )
}
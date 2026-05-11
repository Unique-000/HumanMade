"use client"

export default function Additional(){
    return(
        <>
        <div className="flex-1 flex pl-10 pr-10 mt-8 items-center">
            <p className="text-[#4C5C18] text-4xl font-bold mb-1">Additional functionalities</p>
        </div>
        <div className="flex-3 flex flex-col gap-2 pl-10 pr-10">
            <div className="flex flex-col">
                <p className='text-[#709200] text-2xl'>
                    Saving photo locally <span className="ml-5 text-red-400">Disabled</span>
                </p>
                <div className="flex flex-row gap-2 cursor-pointer mt-3">
                    <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="32"
                    height="32"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="#607d8b"
                    stroke-width="1"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    >
                    <path d="M4 18h12l4 -4h-12z" />
                    <path d="M8 14l-4 -4h12l4 4" />
                    <path d="M16 10l4 -4h-12l-4 4" />
                    </svg>
                    <p className='text-[#709200] text-2xl'>Pay with Solana</p>
                </div>

            </div>
        </div>
        </>
    )
}
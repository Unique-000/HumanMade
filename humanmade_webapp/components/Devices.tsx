"use client"

export default function Devices(){
    return(
        <>
        <div className="flex-1 flex pl-10 pr-10 mt-8 items-center">
            <p className="text-[#4C5C18] text-4xl font-bold mb-1">Devices</p>
        </div>
        <div className="flex-3 flex flex-col gap-2 pl-10 pr-10">
            <div className="flex flex-rows">
                <p className='text-[#709200] text-2xl'>
                    Device name
                </p>
                <p className='text-[#709200] text-2xl hover:text-red-400 ml-6 rounded-[10px] cursor-pointer'>
                    Delete
                </p>
            </div>
        </div>
        </>
    )
}